package online;

import backend.Song;
import sys.thread.Thread;
import backend.Rating;
import online.schema.Player;
import haxe.Http;
import sys.io.File;
import sys.FileSystem;
import online.states.OnlineState;
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
		LoadingScreen.toggle(true);
		
		Thread.create(() -> {
			client = new Client(serverAddress);

			client.create("room", getOptions(), RoomState, function(err, room) {
				Waiter.put(() -> {
					LoadingScreen.toggle(false);

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
							leaveRoom("");
						}
						else {
							reconnect();
						}
					}

					onJoin();
				});
			});
		});
    }

    public static function joinRoom(roomID:String, ?onJoin:()->Void) {
		LoadingScreen.toggle(true);

		Thread.create(() -> {
			client = new Client(serverAddress);

			client.joinById(roomID, getOptions(), RoomState, function(err, room) {
				Waiter.put(() -> {
					LoadingScreen.toggle(false);

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
							leaveRoom("");
						}
						else {
							reconnect();
						}
					}

					onJoin();
				});
			});
		});
    }

	public static function reconnect(?nextTry:Bool = false) {
		leaveRoom("");
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
					leaveRoom("");
				}
				else {
					reconnect();
				}
			}

			reconnectTries = 0;
		});
	}

	static function getOptions():Map<String, Dynamic> {
		var options:Map<String, Dynamic> = ["name" => Wrapper.prefNickname, "version" => MainMenuState.psychOnlineVersion];

		if (Wrapper.prefModSkin != null && Wrapper.prefModSkin.length >= 2) {
			options.set("skinMod", Wrapper.prefModSkin[0]);
			options.set("skinName", Wrapper.prefModSkin[1]);
			options.set("skinURL", OnlineMods.getModURL(Wrapper.prefModSkin[0]));
		}

		return options;
	}

	public static function getAvailableRooms(result:(MatchMakeError, Array<RoomAvailable>)->Void) {
		Thread.create(() -> {
			new Client(serverAddress).getAvailableRooms("room", result);
		});
	}

	public static function leaveRoom(?reason:String = null) {
		if (!isConnected())
			return;
		
		GameClient.client = null;
		
        Waiter.put(() -> {
			if (reason != null)
				Alert.alert("Disconnected!", reason.trim() != "" ? reason : null);
			Sys.println("leaving the room");

			FlxG.autoPause = Wrapper.prefAutoPause;

			MusicBeatState.switchState(new OnlineState());
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxG.sound.playMusic(Paths.music('freakyMenu'));

			if (GameClient.room?.connection != null) {
				GameClient.room.connection.close();
				GameClient.room.teardown();
            }

			GameClient.room = null;
			GameClient.isOwner = false;

			//Downloader.cancelAll();
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

				#if MODS_ALLOWED
				DiscordClient.loadModRPC();
				#end
			});
		});
	}

	public static function send(type:Dynamic, ?message:Null<Dynamic>) {
		if (GameClient.isConnected() && GameClient.reconnectTries <= 0)
			room.send(type, message);
	}

	public static function hasPerms() {
		if (!GameClient.isConnected())
			return false;

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
		if (Wrapper.prefServerAddress != null) {
			return Wrapper.prefServerAddress;
		}
		return _defaultAddress;
	}

	static function set_serverAddress(v:String):String {
		if (v != null)
			v = v.trim();
		if (v == "" || v == _defaultAddress || v == "null")
			v = null;

		Wrapper.prefServerAddress = v;
		ClientPrefs.saveSettings();
		return serverAddress;
	}

	public static function getPlayerCount(callback:(v:Null<Int>)->Void) {
		Thread.create(() -> {
			var swagAddress = serverAddress.split("//")[1];
			if (serverAddress.startsWith("wss"))
				swagAddress = "https://" + swagAddress;
			else if (serverAddress.startsWith("ws"))
				swagAddress = "http://" + swagAddress;

			var http = new Http(swagAddress + "/online");

			http.onData = function(data:String) {
				Waiter.put(() -> {
					callback(Std.parseInt(data));
				});
			}

			http.onError = function(error) {
				Waiter.put(() -> {
					callback(null);
				});
			}

			http.request();
		});
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
}