package online;

import haxe.crypto.Md5;
import backend.Song;
import backend.Rating;
import online.schema.Player;
import haxe.Http;
import sys.io.File;
import sys.FileSystem;
import online.states.OnlineState;
//import io.colyseus.error.HttpException; 0.15.3 doesn't work
import io.colyseus.error.MatchMakeError;
import lime.app.Application;
import io.colyseus.events.EventHandler;
import states.MainMenuState;
import online.schema.RoomState;
import io.colyseus.Client;
import io.colyseus.Room;

class GameClient {
    public static var client:Client;
    public static var room:Room<RoomState>;
	public static var isOwner:Bool;
	public static var address:String;
	public static var reconnectTries:Int = 0;
	public static var rpcClientRoomID:String;

	/**
	 * the server address that the player set, if player set nothing then it returns `serverAddresses[0]`
	 */
	public static var serverAddress(get, set):String;
	/**
	 * server list retrieved from github every launch
	 */
	public static var serverAddresses:Array<String> = [];

	public static function createRoom(address:String, ?onJoin:(err:Dynamic)->Void) {
		LoadingScreen.toggle(true);

		ChatBox.clearLogs();
		
		Thread.run(() -> {
			client = new Client(address);

			client.create("room", getOptions(true), RoomState, (err, room) -> _onJoin(err, room, true, address, onJoin));
		}, (exc) -> {
			onJoin(exc);
			LoadingScreen.toggle(false);
			Alert.alert("Failed to connect!", exc.toString());
		});
    }

	public static function joinRoom(roomSecret:String, ?onJoin:(err:Dynamic)->Void) {
		LoadingScreen.toggle(true);

		var roomID = roomSecret.trim();
		var roomAddress = GameClient.serverAddress;
		var coolIndex = roomSecret.indexOf(";");
		if (coolIndex != -1) {
			roomID = roomSecret.substring(0, coolIndex).trim();
			roomAddress = roomSecret.substring(coolIndex + 1).trim();
		}

		ChatBox.clearLogs();

		Thread.run(() -> {
			client = new Client(roomAddress);

			client.joinById(roomID, getOptions(false), RoomState, (err, room) -> _onJoin(err, room, false, roomAddress, onJoin));
		}, (exc) -> {
			onJoin(exc);
			LoadingScreen.toggle(false);
			Alert.alert("Failed to connect!", exc.toString());
		});
    }

	private static function _onJoin(err:MatchMakeError, room:Room<RoomState>, isHost:Bool, address:String, ?onJoin:(err:Dynamic)->Void) {
		if (err != null) {
			Alert.alert("Couldn't connect!", "JOIN ERROR: " + err.code + " - " + err.message);
			client = null;
			onJoin(err);
			LoadingScreen.toggle(false);
			return;
		}
		LoadingScreen.toggle(false);

		GameClient.room = room;
		GameClient.isOwner = isHost;
		GameClient.address = address;
		GameClient.rpcClientRoomID = Md5.encode(FlxG.random.int(0, 1000000).hex());
		clearOnMessage();

		GameClient.room.onError += (id:Int, e:String) -> {
			Alert.alert("Room error!", "room.onError: " + id + " - " + e + "\n\nPlease report this error on GitHub!");
			Sys.println("Room.onError: " + id + " - " + e);
		}

		GameClient.room.onLeave += () -> {
			trace("Leaving!");

			if (client == null) {
				leaveRoom();
			}
			else {
				reconnect();
			}
		}

		Waiter.put(() -> {
			trace("Joined!");

			FlxG.autoPause = false;

			if (onJoin != null)
				onJoin(null);
		});

		//maybe just make it global
		//if (address.contains(".onrender.com")) {
		//	trace("onrender server detected");
		Waiter.pingServer = address;
		//}
	}

	public static function reconnect(?nextTry:Bool = false) {
		leaveRoom();
		return;
		//i give up on reconnection stuff, probably a colyseus bug
		// reconnection token invalid or expired?
		// i literally give it infinite seconds to reconnect again?

		if (nextTry)
			reconnectTries--;
		else {
			reconnectTries = 5;
		}
		
		client.reconnect(room.reconnectionToken, RoomState, (err, room) -> {
			if (err != null) {
				if (reconnectTries <= 0) {
					Alert.alert("Couldn't reconnect!", "RECONNECT ERROR: " + err.code + " - " + err.message);
					leaveRoom();
				}
				else {
					new FlxTimer().start(0.5, t -> reconnect(true));
				}
				return;
			}

			_onJoin(err, room, GameClient.isOwner, GameClient.address);
			reconnectTries = 0;
		});
	}

	static function getOptions(asHost:Bool):Map<String, Dynamic> {
		var options:Map<String, Dynamic> = [
			"name" => ClientPrefs.data.nickname, 
			"version" => MainMenuState.psychOnlineVersion,
			"points" => FunkinPoints.funkinPoints
		];

		if (ClientPrefs.data.modSkin != null && ClientPrefs.data.modSkin.length >= 2) {
			options.set("skinMod", ClientPrefs.data.modSkin[0]);
			options.set("skinName", ClientPrefs.data.modSkin[1]);
			options.set("skinURL", OnlineMods.getModURL(ClientPrefs.data.modSkin[0]));
		}

		if (asHost) {
			options.set("gameplaySettings", ClientPrefs.data.gameplaySettings);
		}

		return options;
	}

	public static function leaveRoom(?reason:String = null) {
		Waiter.pingServer = null;

		if (!isConnected())
			return;
		
		GameClient.client = null;
		
        Waiter.put(() -> {
			if (reason != null)
				Alert.alert("Disconnected!", reason.trim() != "" ? reason : null);
			Sys.println("leaving the room");

			FlxG.autoPause = ClientPrefs.data.autoPause;

			FlxG.switchState(() -> new OnlineState());
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxG.sound.playMusic(Paths.music('freakyMenu'));

			if (GameClient.room?.connection != null) {
				GameClient.room.connection.close();
				GameClient.room.teardown();
            }

			GameClient.room = null;
			GameClient.isOwner = false;
			GameClient.address = null;
			GameClient.rpcClientRoomID = null;

			//Downloader.cancelAll();
        });
	}

    public static function isConnected() {
		return client != null;
    }

	@:access(io.colyseus.Room.onMessageHandlers)
	public static function clearOnMessage() {
		if (!GameClient.isConnected() || GameClient.room?.onMessageHandlers == null)
			return;

		GameClient.room.onMessageHandlers.clear();
		
		ChatBox.tryRegisterLogs();

		GameClient.room.onMessage("ping", function(message) {
			GameClient.send("pong");
		});

		GameClient.room.onMessage("gameStarted", function(message) {
			Waiter.put(() -> {
				FlxG.mouse.visible = false;

				Mods.currentModDirectory = GameClient.room.state.modDir;
				trace("WOWO : " + GameClient.room.state.song + " | " + GameClient.room.state.folder);
				PlayState.SONG = Song.loadFromJson(GameClient.room.state.song, GameClient.room.state.folder);
				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = GameClient.room.state.diff;
				GameClient.clearOnMessage();
				LoadingState.loadAndSwitchState(new PlayState());

				FlxG.sound.music.volume = 0;

				#if (MODS_ALLOWED && DISCORD_ALLOWED)
				DiscordClient.loadModRPC();
				#end
			});
		});

		#if DISCORD_ALLOWED
		GameClient.room.state.listen("isPrivate", (value, prev) -> {
			DiscordClient.updateOnlinePresence();
		});
		#end
	}

	public static function send(type:Dynamic, ?message:Null<Dynamic>) {
		if (GameClient.isConnected() && type != null)
			room.send(type, message);
	}

	public static function hasPerms() {
		if (!GameClient.isConnected())
			return false;

		return GameClient.isOwner || GameClient.room.state.anarchyMode;
	}

	static function get_serverAddress():String {
		if (ClientPrefs.data.serverAddress != null) {
			return ClientPrefs.data.serverAddress;
		}
		return serverAddresses[0];
	}

	static function set_serverAddress(v:String):String {
		if (v != null)
			v = v.trim();
		if (v == "" || v == serverAddresses[0] || v == "null")
			v = null;

		ClientPrefs.data.serverAddress = v;
		ClientPrefs.saveSettings();
		return serverAddress;
	}

	public static function addressToUrl(address:String) {
		var copyAddress = address;
		if (copyAddress.startsWith("wss://")) {
			copyAddress = "https://" + copyAddress.substr("wss://".length);
		}
		else if (copyAddress.startsWith("ws://")) {
			copyAddress = "http://" + copyAddress.substr("ws://".length);
		}
		return copyAddress;
	}

	public static function getAvailableRooms(address:String, result:(MatchMakeError, Array<RoomAvailable>) -> Void) {
		Thread.run(() -> {
			new Client(address).getAvailableRooms("room", result);
		});
	}

	public static function getServerPlayerCount(?address:String, ?callback:(v:Null<Int>)->Void) {
		if (address == null)
			address = serverAddress;

		Thread.run(() -> {
			var http = new Http(addressToUrl(address) + "/api/online");

			http.onData = function(data:String) {
				if (callback != null)
					Waiter.put(() -> {
						callback(Std.parseInt(data));
					});
			}

			http.onError = function(error) {
				if (callback != null)
					Waiter.put(() -> {
						callback(null);
					});
			}

			http.request();
		}, _ -> {});
	}

	private static var ratingsData:Array<Rating> = Rating.loadDefault(); // from PlayState

	public static function getPlayerAccuracyPercent(player:Player) {
		var totalPlayed = player.sicks + player.goods + player.bads + player.shits + player.misses; // all the encountered notes
		var totalNotesHit = 
			(player.sicks * ratingsData[0].ratingMod) + 
			(player.goods * ratingsData[1].ratingMod) + 
			(player.bads * ratingsData[2].ratingMod) +
			(player.shits * ratingsData[3].ratingMod)
		;

		if (totalPlayed == 0)
			return 0.0;
		
		return CoolUtil.floorDecimal(Math.min(1, Math.max(0, totalNotesHit / totalPlayed)) * 100, 2);
	}

	public static function getRoomSecret(?forceAddress:Bool = false) {
		if (forceAddress || GameClient.address != GameClient.serverAddresses[0])
			return '${GameClient.room.roomId};${GameClient.address}';
		return GameClient.room.roomId;
	}

	public static function getGameplaySetting(key:String):Dynamic {
		var daSetting:String = room.state.gameplaySettings.get(key);
		if (daSetting == "true" || daSetting == "false") {
			return daSetting == "true" ? true : false;
		}
		var _tryNum:Null<Float> = Std.parseFloat(daSetting);
		if (_tryNum != null && !Math.isNaN(_tryNum)) {
			return _tryNum;
		}
		return daSetting;
	}

	public static function setGameplaySetting(key:String, value:Dynamic) {
		if (GameClient.hasPerms()) {
			GameClient.send("setGameplaySetting", [key, value]);
		}
	}

	public static function getPlayerCount():Int {
		if (!GameClient.isConnected())
			return 0;

		if (GameClient.room.state.player2 != null && GameClient.room.state.player2.name != "")
			return 2;
		return 1;
	}

	public static function getStaticPlayer(?self:Bool = true) {
		if (PlayState.instance != null) {
			return self ? PlayState.instance.getPlayer() : PlayState.instance.getOpponent();
		} else {
			return online.states.Room.getStaticPlayer(self);
		}
	}
}