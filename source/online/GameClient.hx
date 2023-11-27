package online;

import online.states.Lobby;
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
	public static var reconnectTries:Int = 0;

	public static var serverAddress(get, set):String;

    public static function createRoom(?onJoin:()->Void) {
		client = new Client(serverAddress);

		client.create("room", ["name" => ClientPrefs.data.nickname, "version" => MainMenuState.psychOnlineVersion], RoomState, function(err, room) {
            if (err != null) {
				Alert.alert("Couldn't connect!", "ERROR: " + err.code + " - " + err.message + (err.code == 0 ? "\nTry again in a few minutes! The server is probably restarting!" : ""));
				client = null;
                return;
            }

			Sys.println("joined!");

			FlxG.autoPause = false;

            GameClient.room = room;
			clearOnMessage();
			GameClient.isOwner = true;

			GameClient.room.onError += (id:Int, e:String) -> {
				Sys.println("Room.onError: " + id + " - " + e);
			}

			GameClient.room.onLeave += () -> {
				if (client == null) {
					leaveRoom();
					Alert.alert("Disconnected!");
				}
				else {
					reconnect();
				}
			}

			onJoin();
        });
    }

    public static function joinRoom(roomID:String, ?onJoin:()->Void) {
		client = new Client(serverAddress);

		client.joinById(roomID, ["name" => ClientPrefs.data.nickname, "version" => MainMenuState.psychOnlineVersion], RoomState, function(err, room) {
            if (err != null) {
				Alert.alert("Couldn't connect!", "JOIN ERROR: " + err.code + " - " + err.message);
				client = null;
                return;
            }

			Sys.println("joined!");

			FlxG.autoPause = false;

            GameClient.room = room;
			clearOnMessage();
			GameClient.isOwner = false;

			GameClient.room.onError += (id:Int, e:String) -> {
				Sys.println("Room.onError: " + id + " - " + e);
			}

			GameClient.room.onLeave += () -> {
				if (client == null) {
					leaveRoom();
					Alert.alert("Disconnected!");
				}
				else {
					reconnect();
				}
			}

			onJoin();
        });
    }

	public static function reconnect(?nextTry:Bool = false) {
		leaveRoom();
		Alert.alert("Disconnected!");
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

			Sys.println("reconnected!");

			GameClient.room = room;
			clearOnMessage();

			GameClient.room.onError += (id:Int, e:String) -> {
				Sys.println("Room.onError: " + id + " - " + e);
			}

			GameClient.room.onLeave += () -> {
				if (client == null) {
					leaveRoom();
					Alert.alert("Disconnected!");
				}
				else {
					reconnect();
				}
			}

			reconnectTries = 0;
		});
	}

	public static function getAvailableRooms(result:(MatchMakeError, Array<RoomAvailable>)->Void) {
		new Client(serverAddress).getAvailableRooms("room", result);
	}

	public static function leaveRoom() {
        Waiter.put(() -> {
			Sys.println("leaving the room");

			FlxG.autoPause = ClientPrefs.data.autoPause;

			FlxG.switchState(new Lobby());
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxG.sound.playMusic(Paths.music('freakyMenu'));

			GameClient.client = null;

			if (GameClient.room?.connection != null) {
				GameClient.room.connection.close();
				GameClient.room.teardown();
            }

			GameClient.room = null;
			GameClient.isOwner = false;
        });
	}

    public static function isConnected() {
		return client != null;
    }

	@:access(io.colyseus.Room.onMessageHandlers)
	public static function clearOnMessage() {
		if (GameClient.isConnected() && GameClient.room?.onMessageHandlers != null)
			GameClient.room.onMessageHandlers.clear();

		GameClient.room.onMessage("ping", function(message) {
			Waiter.put(() -> {
				GameClient.send("pong");
			});
		});
	}

	public static function send(type:Dynamic, ?message:Null<Dynamic>) {
		if (GameClient.isConnected() && GameClient.reconnectTries <= 0)
			room.send(type, message);
	}

	public static function hasPerms() {
		return GameClient.isOwner || GameClient.room.state.anarchyMode;
	}

	static final _defaultAddress:String = 
		#if LOCAL
		"ws://localhost:2567"
		#else
		"wss://gettinfreaky.onrender.com"
		#end
	;

	static function get_serverAddress():String {
		if (ClientPrefs.data.serverAddress != null) {
			return ClientPrefs.data.serverAddress;
		}
		return _defaultAddress;
	}

	static function set_serverAddress(v:String):String {
		if (v != null)
			v = v.trim();
		if (v == "" || v == _defaultAddress || v == "null")
			v = null;

		ClientPrefs.data.serverAddress = v;
		ClientPrefs.saveSettings();
		return serverAddress;
	}
}