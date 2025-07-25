package online;

import online.http.HTTPHandler;
import io.colyseus.serializer.schema.Schema;
import backend.NoteSkinData;
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
	public static var isOwner(get, never):Bool;
	public static var address:String;
	public static var reconnecting:Bool = false;
	public static var rpcClientRoomID:String;

	/**
	 * the game server address that the player set, if the player has set nothing then it returns `serverAddresses[0]`
	 */
	public static var serverAddress(get, set):String;

	/**
	 * the network server address that the player set, if the player has set nothing then it returns `serverAddresses[0]`
	 */
	public static var networkServerAddress(get, set):String;

	/**
	 * server list retrieved from github every launch
	 */
	@:unreflective
	public static var serverAddresses(default, null):Array<String> = [];

	public static function createRoom(address:String, ?onJoin:(err:Dynamic)->Void) {
		if (reconnecting)
			return;

		LoadingScreen.toggle(true);

		leaveRoom('Switching Rooms.');
		ChatBox.clearLogs();
		
		Thread.run(() -> {
			client = new Client(address);
			_pendingMessages = [];

			client.create("room", getOptions(true, address), GameRoom, (err, room) -> _onJoin(err, room, true, address, onJoin));
		}, (exc) -> {
			onJoin(exc);
			LoadingScreen.toggle(false);
			Alert.alert("Failed to connect!", exc.details());
		});
    }

	public static function joinRoom(roomSecret:String, ?onJoin:(err:Dynamic)->Void) {
		if (reconnecting)
			return;

		LoadingScreen.toggle(true);

		leaveRoom('Switching Rooms.');
		ChatBox.clearLogs();

		var roomID = roomSecret.trim();
		var roomAddress = GameClient.serverAddress;
		var coolIndex = roomSecret.indexOf(";");
		if (coolIndex != -1) {
			roomID = roomSecret.substring(0, coolIndex).trim();
			roomAddress = roomSecret.substring(coolIndex + 1).trim();
		}

		Thread.run(() -> {
			client = new Client(roomAddress);
			_pendingMessages = [];

			client.joinById(roomID, getOptions(false, roomAddress), GameRoom, (err, room) -> _onJoin(err, room, false, roomAddress, onJoin));
		}, (exc) -> {
			onJoin(exc);
			LoadingScreen.toggle(false);
			Alert.alert("Failed to connect!", exc.toString());
		});
    }

	private static function _onJoin(err:Error, room:Room<GameRoom>, isHost:Bool, address:String, ?onJoin:(err:Dynamic)->Void) {
		if (err != null) {
			trace(err.code + " - " + err.message);
			Alert.alert("Couldn't connect!", "JOIN ERROR: " + ShitUtil.prettyStatus(err.code) + "\n" + ShitUtil.readableError(err.message));
			onJoin(err);
			leaveRoom();
			LoadingScreen.toggle(false);
			if (err.code == 5003)
				Waiter.putPersist(() -> {
					FlxG.switchState(() -> new OutdatedState());
				});
			return;
		}
		LoadingScreen.toggle(false);

		GameClient.room = room;
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

		Waiter.putPersist(() -> {
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

		reconnecting = false;
	}

	public static function reconnect(?debugReconnectDelay:Float = 0) {
		if (reconnecting)
			return;
		reconnecting = true;

		if (room == null) {
			leaveRoom('Room Disposed?');
			return;
		}

		var reconnectToken = room.reconnectionToken;

		trace("Reconnecting with Token: " + reconnectToken);
		Alert.alert("Reconnecting...");

		try {
			GameClient.room.teardown();
			GameClient.room.leave(false);
		}
		catch (exc) {}

		Thread.run(() -> {
			if (debugReconnectDelay > 0)
				Sys.sleep(debugReconnectDelay);
			if (client == null)
				return;
			client.reconnect(reconnectToken, GameRoom, (err, newRoom:Room<GameRoom>) -> {
				try {
					if (reconnectToken != room.reconnectionToken) {
						reconnecting = false;
						return;
					}

					if (err != null) {
						trace(err.code + " - " + err.message);
						Waiter.putPersist(() -> {
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
						Waiter.putPersist(() -> {
							Alert.alert("Reconnected!");
						});
					};
				}
				catch (exc) {
					Waiter.putPersist(() -> {
						Alert.alert("Critically failed to reconnect!", "RECONNECT ERROR: " + ShitUtil.prettyStatus(err.code) + " - " + ShitUtil.readableError(err.message));
					});
					leaveRoom();
				}
			});
		});
	}

	@:unreflective
	static function getOptions(asHost:Bool, reqAddress:String):Map<String, Dynamic> {
		var options:Map<String, Dynamic> = [
			"name" => ClientPrefs.getNickname(), 
			"protocol" => Main.CLIENT_PROTOCOL,
			"points" => FunkinPoints.funkinPoints,
			"arrowRGBT" => ClientPrefs.data.arrowRGB,
			"arrowRGBP" => ClientPrefs.data.arrowRGBPixel,
		];

		if (reqAddress == networkServerAddress && Auth.authID != null && Auth.authToken != null) {
			options.set("networkId", Auth.authID);
			options.set("networkToken", Auth.authToken);
		}

		if (ClientPrefs.data.modSkin != null && ClientPrefs.data.modSkin.length >= 2) {
			options.set("skinMod", ClientPrefs.data.modSkin[0]);
			options.set("skinName", ClientPrefs.data.modSkin[1]);
			options.set("skinURL", OnlineMods.getModURL(ClientPrefs.data.modSkin[0]));
		}

		var data:NoteSkinStructure = NoteSkinData.getCurrent(-1);
		options.set('noteSkin', data.skin);
		options.set('noteSkinMod', data.folder);
		options.set('noteSkinURL', data.url);

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
		
		Waiter.putPersist(() -> {
			if (reason != null)
				Alert.alert("Disconnected!", reason.trim() != "" ? reason : null);
			trace("Leaving the Room, Reason: " + reason);

			FlxG.autoPause = ClientPrefs.data.autoPause;

			if (@:privateAccess FlxG.game._nextState == null) {
				FlxG.switchState(() -> new OnlineState());
			}
			FlxG.sound.play(Paths.sound('cancelMenu'));
			states.TitleState.playFreakyMusic();

			try {
				if (GameClient.room?.connection != null) {
					GameClient.room.teardown();
					GameClient.room.leave(true);
				}
			}
			catch (exc) {}

			GameClient.room = null;
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
		clearCallbacks(GameClient.room.state);
		clearCallbacks(GameClient.room.state.diffList);
		clearCallbacks(GameClient.room.state.gameplaySettings);
		for (sid => player in GameClient.room.state.players) {
			if (player == null)
				continue;

			clearCallbacks(player);
			clearCallbacks(player.arrowColor0);
			clearCallbacks(player.arrowColor1);
			clearCallbacks(player.arrowColor2);
			clearCallbacks(player.arrowColor3);
			clearCallbacks(player.arrowColorP0);
			clearCallbacks(player.arrowColorP1);
			clearCallbacks(player.arrowColorP2);
			clearCallbacks(player.arrowColorP3);
		}

		// clear waiter queue to avoid tasks that want to access stuff from the previous state
		// and then lead to a crash
		Waiter.stateQueue = [];
		
		ChatBox.tryRegisterLogs();

		GameClient.room.onMessage("ping", function(message) {
			GameClient.send("pong");
		});

		GameClient.room.onMessage("gameStarted", function(message) {
			Waiter.putPersist(() -> {
				FlxG.mouse.visible = false;

				Mods.currentModDirectory = GameClient.room.state.modDir;
				Difficulty.list = CoolUtil.asta(GameClient.room.state.diffList);
				PlayState.storyDifficulty = GameClient.room.state.diff;
				PlayState.loadSong(GameClient.room.state.song, GameClient.room.state.folder);
				PlayState.isStoryMode = false;
				LoadingState.loadAndSwitchState(new PlayState());

				FlxG.sound.music.volume = 0;

				#if (MODS_ALLOWED && DISCORD_ALLOWED)
				DiscordClient.loadModRPC();
				#end
			});
		});

		GameClient.room.onMessage("alert", function(message:Dynamic) {
			if (message == null)
				return;

			switch (Type.typeof(message)) {
				case Type.ValueType.TClass(String):
					Alert.alert(cast message);

				case Type.ValueType.TClass(Array):
					var arrMsg:Array<Dynamic> = cast message;
					if (arrMsg.length >= 2)
						Alert.alert(arrMsg[0], arrMsg[1]);

				default:
			}
		});

		GameClient.room.onMessage("requestSkin", function(?msg:Dynamic) {
			Waiter.putPersist(() -> {
				if (ClientPrefs.data.modSkin != null && ClientPrefs.data.modSkin.length >= 2) {
					GameClient.send("setSkin", [
						ClientPrefs.data.modSkin[0],
						ClientPrefs.data.modSkin[1],
						OnlineMods.getModURL(ClientPrefs.data.modSkin[0])
					]);
				}
				else {
					GameClient.send("setSkin", null);
				}
			});
		});

		GameClient.room.onMessage("checkChart", function(message) {
			Waiter.putPersist(() -> {
				try {
					var hash = Md5.encode(Song.loadRawSong(GameClient.room.state.song, GameClient.room.state.folder));
					trace("verifying song: " + GameClient.room.state.song + " | " + GameClient.room.state.folder + " : " + hash);
					GameClient.send("verifyChart", hash);
					states.FreeplayState.destroyFreeplayVocals();
					FlxG.switchState(() -> new RoomState());
					FlxG.autoPause = ClientPrefs.data.autoPause;
				}
				catch (exc:Dynamic) {
					Sys.println(exc);
				}
			});
		});

		#if DISCORD_ALLOWED
		GameClient.room.state.listen("isPrivate", (value, prev) -> {
			DiscordClient.updateOnlinePresence();
		});
		#end
	}

	@:privateAccess static function clearCallbacks(schema:Dynamic) {
		if (schema == null)
			return;
		if (schema._callbacks != null)
			schema._callbacks.clear();
		if (schema._propertyCallbacks != null)
			schema._propertyCallbacks.clear();
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
			Waiter.putPersist(() -> {
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

	static function get_isOwner() {
		if (GameClient.room == null || GameClient.room.state == null)
			return false;
		return GameClient.room.state.host == GameClient.room.sessionId;
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
		return getDefaultServer();
	}

	static function set_serverAddress(v:String):String {
		if (v != null)
			v = v.trim();
		if (v == "" || v == getDefaultServer() || v == "null")
			v = null;

		ClientPrefs.data.serverAddress = v;
		ClientPrefs.saveSettings();
		return serverAddress;
	}

	static function get_networkServerAddress():String {
		if (ClientPrefs.data.networkServerAddress != null) {
			return ClientPrefs.data.networkServerAddress;
		}
		return getDefaultServer();
	}

	static function set_networkServerAddress(v:String):String {
		if (v != null)
			v = v.trim();
		if (v == "" || v == getDefaultServer() || v == "null")
			v = null;

		ClientPrefs.data.networkServerAddress = v;
		ClientPrefs.saveSettings();
		FunkinNetwork.client = new online.http.HTTPHandler(GameClient.addressToUrl(v));
		if (NetworkClient.room != null) {
			NetworkClient.room.leave();
			NetworkClient.room = null;
			NetworkClient.connecting = false;
			NetworkClient.connect();
		}
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
			var http = new Http(addressToUrl(address) + "/api/onlinecount");

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
		if (forceAddress || GameClient.address != GameClient.getDefaultServer())
			return '${GameClient.room.roomId};${GameClient.address}';
		return GameClient.room.roomId;
	}

	public static function getGameplaySetting(key:String):Dynamic {
		if (key == 'songspeed') {
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

		return ClientPrefs.data.gameplaySettings.get(key);
	}

	public static function getPlayerCount():Int {
		if (!GameClient.isConnected())
			return 0;

		return GameClient.room?.state?.players?.length ?? 0;
	}

	public static function getPlayerSelf() {
		if (!GameClient.isConnected())
			return null;

		return GameClient.room.state.players.get(GameClient.room.sessionId);
	}

	public static function listPlayersBySide(isBf:Bool):Array<Player> {
		if (!GameClient.isConnected())
			return null;

		var arr = [];
		for (sid => player in GameClient.room.state.players) {
			if (player.bfSide == isBf)
				arr.push(player);
		}
		return arr;
	}

	public static function getDefaultServer() {
		return serverAddresses[0];
	}
	
	@:unreflective
	public static var hasAddresses:Bool = false;
	public static function asyncUpdateAddresses() {
		if (hasAddresses)
			return;

		Thread.run(() -> {
			if (hasAddresses)
				return;

			updateAddresses();
		});
	}

	public static function updateAddresses() {
		var http = new haxe.Http("https://raw.githubusercontent.com/Snirozu/Funkin-Psych-Online/main/server_addresses.txt");
		http.onData = function(data:String) {
			GameClient.serverAddresses = [];
			for (address in data.split(',')) {
				GameClient.serverAddresses.push(address.trim());
				hasAddresses = true;
			}
		}
		http.onError = function(error) {
			GameClient.serverAddresses = [];
			trace('error: $error');
			hasAddresses = false;
		}
		http.request();
		#if LOCAL
		GameClient.serverAddresses.insert(0, "ws://localhost:2567");
		#else
		GameClient.serverAddresses.push("ws://localhost:2567");
		#end

		FunkinNetwork.client = new HTTPHandler(GameClient.addressToUrl(networkServerAddress));
	}
}