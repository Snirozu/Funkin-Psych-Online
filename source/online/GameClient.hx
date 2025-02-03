package online;

import flixel.FlxState;
import online.network.Auth;
import online.network.FunkinNetwork;
import states.OutdatedState;
import haxe.crypto.Md5;
import backend.Song;
import backend.Rating;
import online.backend.schema.Player;
import haxe.Http;
import sys.io.File;
import sys.FileSystem;
import online.states.OnlineState;
import lime.app.Application;
import io.colyseus.events.EventHandler;
import states.MainMenuState;
import online.backend.schema.Room as GameRoom;
import io.colyseus.Client;
import io.colyseus.Room;

typedef Error = #if (colyseus < "0.15.3") io.colyseus.error.MatchMakeError #else io.colyseus.error.HttpException #end;

class GameClient {
    public static var client:Client;
	public static var room:Room<GameRoom>;
	public static var isOwner:Bool;
	public static var address:String;
	public static var reconnecting:Bool = false;
	public static var rpcClientRoomID:String;

	/**
	 * the server address that the player set, if the player has set nothing then it returns `serverAddresses[0]`
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
			_pendingMessages = [];

			client.create("room", getOptions(true), GameRoom, (err, room) -> _onJoin(err, room, true, address, onJoin));
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
			_pendingMessages = [];

			client.joinById(roomID, getOptions(false), GameRoom, (err, room) -> _onJoin(err, room, false, roomAddress, onJoin));
		}, (exc) -> {
			onJoin(exc);
			LoadingScreen.toggle(false);
			Alert.alert("Failed to connect!", exc.toString());
		});
    }

	private static function _onJoin(err:Error, room:Room<GameRoom>, isHost:Bool, address:String, ?onJoin:(err:Dynamic)->Void) {
		reconnecting = false;
		if (err != null) {
			trace(err.code + " - " + err.message);
			Alert.alert("Couldn't connect!", "JOIN ERROR: " + ShitUtil.prettyStatus(err.code) + "\n" + ShitUtil.readableError(err.message));
			client = null;
			_pendingMessages = [];
			onJoin(err);
			LoadingScreen.toggle(false);
			if (err.code == 5003)
				Waiter.put(() -> {
					FlxG.switchState(() -> new OutdatedState());
				});
			return;
		}
		LoadingScreen.toggle(false);

		GameClient.room = room;
		GameClient.isOwner = isHost;
		GameClient.address = address;
		GameClient.rpcClientRoomID = Md5.encode(FlxG.random.int(0, 1000000).hex());
		clearOnMessage();

		GameClient.room.onError += (code:Int, e:String) -> {
			Alert.alert("Room error!", "room.onError: " + ShitUtil.prettyStatus(code) + "\n" + ShitUtil.readableError(e));
			Sys.println("Room.onError: " + code + " - " + e);
		}

		GameClient.room.onLeave += () -> {
			if (room?.roomId != null)
				trace("Left/Kicked from room: " + room.roomId);
			else
				trace("Left/Kicked from unknown room!");

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

	public static function reconnect(?debugReconnectDelay:Float = 0) {
		if (reconnecting)
			return;
		reconnecting = true;

		trace("Reconnecting with Token: " + room.reconnectionToken);
		Alert.alert("Reconnecting...");

		try {
			GameClient.room.teardown();
			GameClient.room.leave(false);
		}
		catch (exc) {}

		Thread.run(() -> {
			if (debugReconnectDelay > 0)
				Sys.sleep(debugReconnectDelay);
			client.reconnect(room.reconnectionToken, GameRoom, (err, newRoom:Room<GameRoom>) -> {
				if (err != null) {
					trace(err.code + " - " + err.message);
					Waiter.put(() -> {
						Alert.alert("Couldn't reconnect!", "RECONNECT ERROR: " + ShitUtil.prettyStatus(err.code) + " - " + ShitUtil.readableError(err.message));
					});
					leaveRoom();
					return;
				}

				newRoom.onStateChange += _ -> {
					newRoom.onStateChange = new EventHandler<Dynamic->Void>();

					_onJoin(err, newRoom, GameClient.isOwner, GameClient.address);
					if (addListeners != null)
						addListeners();
					sendPending();
					Waiter.put(() -> {
						Alert.alert("Reconnected!");
					});
				};
			});
		});
	}

	static function getOptions(asHost:Bool):Map<String, Dynamic> {
		var options:Map<String, Dynamic> = [
			"name" => ClientPrefs.getNickname(), 
			"protocol" => Main.CLIENT_PROTOCOL,
			"points" => FunkinPoints.funkinPoints,
			"arrowRGBT" => ClientPrefs.data.arrowRGB,
			"arrowRGBP" => ClientPrefs.data.arrowRGBPixel,
		];

		if (Auth.authID != null && Auth.authToken != null) {
			options.set("networkId", Auth.authID);
			options.set("networkToken", Auth.authToken);
		}

		if (ClientPrefs.data.modSkin != null && ClientPrefs.data.modSkin.length >= 2) {
			options.set("skinMod", ClientPrefs.data.modSkin[0]);
			options.set("skinName", ClientPrefs.data.modSkin[1]);
			options.set("skinURL", OnlineMods.getModURL(ClientPrefs.data.modSkin[0]));
		}

		// if (asHost) {
		// 	options.set("gameplaySettings", ClientPrefs.data.gameplaySettings);
		// }

		return options;
	}

	public static function leaveRoom(?reason:String = null) {
		Waiter.pingServer = null;
		reconnecting = false;
		_pendingMessages = [];

		if (!isConnected())
			return;
		
		GameClient.client = null;
		
        Waiter.put(() -> {
			if (reason != null)
				Alert.alert("Disconnected!", reason.trim() != "" ? reason : null);
			trace("Leaving the Room, Reason: " + reason);

			FlxG.autoPause = ClientPrefs.data.autoPause;

			FlxG.switchState(() -> new OnlineState());
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxG.sound.playMusic(Paths.music('freakyMenu'));

			try {
				if (GameClient.room?.connection != null) {
					GameClient.room.teardown();
					GameClient.room.leave(true);
				}
			}
			catch (exc) {}

			GameClient.room = null;
			GameClient.isOwner = false;
			GameClient.address = null;
			GameClient.rpcClientRoomID = null;

			//Downloader.cancelAll();
        });
	}

    public static function isConnected() {
		return client != null || reconnecting;
    }

	public static function initStateListeners(state:FlxState, listenersCallback:Void->Void) {
		addListenersState = state;
		addListeners = listenersCallback;
	}
	private static var addListenersState:FlxState;
	private static var addListeners(default, null):Void->Void;

	private static var hasStateCallback:Bool = false;

	@:access(io.colyseus.Room.onMessageHandlers)
	public static function clearOnMessage() {
		if (!GameClient.isConnected() || GameClient.room?.onMessageHandlers == null)
			return;

		if (!hasStateCallback) {
			hasStateCallback = true;
			FlxG.signals.postStateSwitch.add(() -> {
				if (addListenersState != FlxG.state)
					addListeners = null;
			});
		}

		GameClient.room.onMessageHandlers.clear();
		
		ChatBox.tryRegisterLogs();

		GameClient.room.onMessage("ping", function(message) {
			GameClient.send("pong");
		});

		GameClient.room.onMessage("gameStarted", function(message) {
			Waiter.put(() -> {
				FlxG.mouse.visible = false;

				Mods.currentModDirectory = GameClient.room.state.modDir;
				Difficulty.list = CoolUtil.asta(GameClient.room.state.diffList);
				PlayState.storyDifficulty = GameClient.room.state.diff;
				PlayState.SONG = Song.loadFromJson(GameClient.room.state.song, GameClient.room.state.folder);
				PlayState.isStoryMode = false;
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

	private static var _pendingMessages:Array<Array<Dynamic>> = [];
	public static function sendPending() {
		if (_pendingMessages.length == 0)
			return;

		Sys.println('resending ' + _pendingMessages.length + " packets");
		while (_pendingMessages.length > 0) {
			var msg = _pendingMessages.shift();
			GameClient.send(msg[0], msg[1]);
		}
	}

	public static function send(type:Dynamic, ?message:Null<Dynamic>) {
		if (GameClient.isConnected() && type != null)
			Waiter.put(() -> {
				try {
					room.send(type, message);
				}
				catch (exc) {
					_pendingMessages.push([type, message]);

					if (!reconnecting) {
						trace(exc + " : FAILED TO SEND: " + type + " -> " + message);
						reconnect();
					}
				}
			});
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
		FunkinNetwork.client = new HTTPClient(GameClient.addressToUrl(v));
		return serverAddress;
	}

	public static function addressToUrl(?address:Null<String>) {
		var copyAddress = address ?? GameClient.serverAddress;
		if (copyAddress.startsWith("wss://")) {
			copyAddress = "https://" + copyAddress.substr("wss://".length);
		}
		else if (copyAddress.startsWith("ws://")) {
			copyAddress = "http://" + copyAddress.substr("ws://".length);
		}
		return copyAddress;
	}

	public static function getAvailableRooms(address:String, result:(Error, Array<RoomAvailable>) -> Void) {
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

	public static function getPlayerRating(player:Player) {
		var ratingFC = 'Clear';
		if (player.misses < 1) {
			if (player.bads > 0 || player.shits > 0)
				ratingFC = 'FC';
			else if (player.goods > 0)
				ratingFC = 'GFC';
			else if (player.sicks > 0)
				ratingFC = 'SFC';
		}
		else if (player.misses < 10)
			ratingFC = 'SDCB';
		return ratingFC;
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
			return online.states.RoomState.getStaticPlayer(self);
		}
	}
}