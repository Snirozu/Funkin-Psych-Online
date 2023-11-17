package online;

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

	public static var serverAddress:String = 
		#if LOCAL
		"localhost:2567"
		#else
		"gettinfreaky.onrender.com"
		#end
	;
	public static var serverProtocol:String =
		#if LOCAL
		"ws"
		#else
		"wss"
		#end
	;

    public static function createRoom(?onJoin:()->Void) {
		client = new Client(serverProtocol + "://" + serverAddress);

		client.create("room", ["name" => ClientPrefs.data.nickname], RoomState, function(err, room) {
            if (err != null) {
				Application.current.window.alert("ERROR: " + err.code + " - " + err.message + (err.code == 0 ? "\nTry again in a few minutes! The server is probably restarting!" : ""), "Couldn't connect!");
                return;
            }

			FlxG.autoPause = false;

            GameClient.room = room;
			GameClient.isOwner = true;

			GameClient.room.onError += (id:Int, e:String) -> {
				Sys.println("Room.onError: " + id + " - " + e);
				// leaveRoom();
				// Application.current.window.alert("Error " + id + ": " + e, "Disconnected!");
			}

			GameClient.room.onLeave += () -> {
				leaveRoom();
				Application.current.window.alert("Disconnected!");
			}

			onJoin();
        });
    }

    public static function joinRoom(roomID:String, ?onJoin:()->Void) {
		client = new Client(serverProtocol + "://" + serverAddress);

		client.joinById(roomID, ["name" => ClientPrefs.data.nickname], RoomState, function(err, room) {
            if (err != null) {
				Application.current.window.alert("JOIN ERROR: " + err.code + " - " + err.message, "Couldn't connect!");
                return;
            }

			FlxG.autoPause = false;

            GameClient.room = room;
			GameClient.isOwner = false;

			GameClient.room.onError += (id:Int, e:String) -> {
				Sys.println("Room.onError: " + id + " - " + e);
				//leaveRoom();
				//Application.current.window.alert("Error " + id + ": " + e, "Disconnected!");
			}

			GameClient.room.onLeave += () -> {
				leaveRoom();
				Application.current.window.alert("Disconnected!");
			}

			onJoin();
        });
    }

	public static function getAvailableRooms(result:(MatchMakeError, Array<RoomAvailable>)->Void) {
		client = new Client(serverProtocol + "://" + serverAddress);

		client.getAvailableRooms("room", result);
	}

	public static function leaveRoom() {
        Waiter.put(() -> {
			// FlxG.state.persistentUpdate = false;
			// FlxG.state.persistentDraw = false;
            // doesn't work because flixel is awesome!

			FlxG.autoPause = ClientPrefs.data.autoPause;

			FlxG.switchState(new MainMenuState());
			FlxG.sound.play(Paths.sound('cancelMenu'));

			if (GameClient.room?.connection != null) {
				GameClient.room.connection.close();
				GameClient.room.teardown();
            }

			GameClient.room = null;
			GameClient.client = null;
			GameClient.isOwner = false;
        });
	}

    public static function isConnected() {
		return room != null;
    }

	public static function clearOnMessage() {
		if (GameClient.isConnected())
			@:privateAccess GameClient.room.onMessageHandlers.clear();
	}
}