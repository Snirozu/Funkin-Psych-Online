package online;

import haxe.Json;
import online.gui.sidebar.tabs.ChatTab;
import online.GameClient.Error;
import online.backend.schema.NetworkSchema;
import online.network.Auth;
import io.colyseus.Client;
import io.colyseus.Room;

class NetworkClient {
	@:unreflective
	public static var client:Client;
	public static var room:Room<NetworkSchema>;
    public static var connecting:Bool = false;

	public static function leave() {
		if (room != null) {
			room.leave();
			room = null;
		}
		client = null;
		connecting = false;
	}

	public static function connect() {
		if (connecting || NetworkClient.room != null)
            return;

		GameClient.asyncUpdateAddresses();

		connecting = true;
		var client = new Client(GameClient.networkServerAddress);

		Thread.run(() -> {
			client.joinById('0', [
				"protocol" => Main.NETWORK_PROTOCOL,
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
			Waiter.putPersist(() -> {
				ChatTab.addMessage('Failed to connect to the network chatroom! (Reopen this tab to try again)');
			});
            //trace(err);
            return;
        }

		Waiter.putPersist(() -> {
			ChatTab.addMessage('Connected to the network chatroom!');
        });

		NetworkClient.room = room;

		room.onMessage("log", function(message) {
			Waiter.putPersist(() -> {
				ChatTab.addMessage(message, true);
			});
		});

		room.onMessage("batchLog", function(message) {
			var logs:Array<String> = Json.parse(message);
			Waiter.putPersist(() -> {
				for (log in logs) {
					ChatTab.addMessage(log);
				}
			});
		});

		room.onMessage("notification", function(message) {
			Waiter.putPersist(() -> {
				Alert.alert(message);
			});
		});

		room.onMessage("roominvite", function(message:String) {
			if (message == null || ClientPrefs.data.disableRoomInvites)
				return;
			var inviteData = Json.parse(message);

			Waiter.putPersist(() -> {
				Alert.alert(inviteData.name + ' has invited you to their room!', '(Click to Join)', () -> {
					OnlineState.inviteRoomID = inviteData.roomid;

					if (GameClient.isConnected()) {
						GameClient.leaveRoom('Switching States');
					}
					else {
						Waiter.putPersist(() -> {
							FlxG.switchState(() -> new OnlineState());
						});
					}
				});
			});
		});

		room.onMessage("friendOnlineNotif", function(player:String) {
			if (player == null || !ClientPrefs.data.friendOnlineNotification)
				return;

			Waiter.putPersist(() -> {
				Alert.alert(player + ' is now online!', null);
			});
		});

		room.onError += (code:Int, e:String) -> {
			Thread.safeCatch(() -> {
				Waiter.putPersist(() -> {
					Alert.alert("Network Room error!", "room.onError: " + ShitUtil.prettyStatus(code) + "\n" + ShitUtil.readableError(e));
				});
				Sys.println("NetworkRoom.onError: " + code + " - " + e);
            }, e -> {
				trace(ShitUtil.prettyError(e));
            });
		}

		room.onLeave += () -> {
			Thread.safeCatch(() -> {
				Waiter.putPersist(() -> {
					ChatTab.addMessage('Disconnected from the chatroom');
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
			}, e -> {
				trace(ShitUtil.prettyError(e));
			});
		}

		room.send('loggedMessagesAfter', ChatTab.lastLogDate);

        trace("Joined Network Room!");
    }
}