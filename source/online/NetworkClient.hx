package online;

import online.gui.sidebar.MainTab;
import online.GameClient.Error;
import online.backend.schema.NetworkSchema;
import online.network.Auth;
import io.colyseus.Client;
import io.colyseus.Room;

class NetworkClient {
	public static var client:Client;
	public static var room:Room<NetworkSchema>;
    public static var connecting:Bool = false;

	public static function connect() {
		if (connecting || NetworkClient.room != null)
            return;

		connecting = true;
		var client = new Client(GameClient.serverAddress);

		Thread.run(() -> {
			client.joinById('0', [
				"protocol" => Main.CLIENT_PROTOCOL,
				"networkId" => Auth.authID,
				"networkToken" => Auth.authToken,
			], NetworkSchema, (err, room) -> {
				joinCallback(err, room);
            });
		}, (exc) -> {
			connecting = false;
            trace(ShitUtil.prettyError(exc));
		});
    }

	static function joinCallback(err:Error, room:Room<NetworkSchema>, ?reconnect:Bool = false) {
		connecting = false;
		NetworkClient.room = null;
        if (err != null) {
			Waiter.put(() -> {
				MainTab.addMessage('Failed to connect to the network chatroom! (Reopen this tab to try again)');
			});
            trace(err);
            return;
        }

		Waiter.put(() -> {
		    MainTab.addMessage('Connected to the network chatroom!');
        });

		NetworkClient.room = room;

		room.onMessage("log", function(message) {
			Waiter.put(() -> {
				MainTab.addMessage(message);
			});
		});

		room.onMessage("notification", function(message) {
			Waiter.put(() -> {
				Alert.alert(message);
			});
		});

		room.onError += (code:Int, e:String) -> {
			Thread.safeCatch(() -> {
				Waiter.put(() -> {
					Alert.alert("Network Room error!", "room.onError: " + ShitUtil.prettyStatus(code) + "\n" + ShitUtil.readableError(e));
				});
				Sys.println("NetworkRoom.onError: " + code + " - " + e);
            }, e -> {
				trace(ShitUtil.prettyError(e));
            });
		}

		room.onLeave += () -> {
			Waiter.put(() -> {
				MainTab.addMessage('Disconnected from the chatroom');
			});

			var recToken = NetworkClient.room.reconnectionToken;
			NetworkClient.room = null;

			Thread.safeCatch(() -> {
				trace("Left/Kicked from the Network room!");

				connecting = true;
				client.reconnect(recToken, NetworkSchema, (err, newRoom) -> {
					trace("Reconnecting to the Network room");
					joinCallback(err, newRoom, true);
				});
			}, e -> {
                NetworkClient.room = null;
				connecting = false;
				trace(ShitUtil.prettyError(e));
            });
		}

        trace("Joined Network Room!");
    }
}