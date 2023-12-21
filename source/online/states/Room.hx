package online.states;

import flixel.math.FlxPoint;
import flixel.FlxObject;
import flixel.util.FlxSpriteUtil;
import objects.Character;
import lime.system.Clipboard;
import online.schema.Player;
import backend.Rating;
import backend.WeekData;
import backend.Song;
import haxe.crypto.Md5;
import states.FreeplayState;

class Room extends MusicBeatState {
	//this shit is messy
	var player1Text:FlxText;
	var player1Bg:FlxSprite;
	var player2Text:FlxText;
	var player2Bg:FlxSprite;

	var verifyMod:FlxText;
	var verifyModBg:FlxSprite;
	var roomCodeBg:FlxSprite;
	var roomCode:FlxText;
	var songName:FlxText;
	var songNameBg:FlxSprite;
	var playIcon:FlxSprite;
	var playIconBg:FlxSprite;
	var chatBox:ChatBox;

	var p1:Character;
	var p2:Character;

	var curSelected:Int = -1;
	var items:FlxTypedGroup<FlxSprite>;
	var settingsIconBg:FlxSprite;
	var settingsIcon:FlxSprite;
	var chatIconBg:FlxSprite;
	var chatIcon:FlxSprite;

	var itemTip:FlxText;
	var itemTipBg:FlxSprite;

	var phillyWindow:BGSprite;
	var phillyLightsColors = [0xFF31A2FD, 0xFF31FD8C, 0xFFFB33F5, 0xFFFD4531, 0xFFFBA633];
	var curLight:Int = -1;
	
	public function new() {
		super();

		WeekData.reloadWeekFiles(false);
		for (i in 0...WeekData.weeksList.length) {
			WeekData.setDirectoryFromWeek(WeekData.weeksLoaded.get(WeekData.weeksList[i]));
		}
		Mods.loadTopMod();
		WeekData.setDirectoryFromWeek();

		// STAGE
		Paths.setCurrentLevel("week3");

		var stageOffset = [-150, -200];

		if (!ClientPrefs.data.lowQuality) {
			var bg:BGSprite = new BGSprite('philly/sky', -175, -30, 0.1, 0.1);
			add(bg);
		}

		var city:BGSprite = new BGSprite('philly/city', -65, -30, 0.3, 0.3);
		city.setGraphicSize(Std.int(city.width * 0.85));
		city.updateHitbox();
		add(city);

		phillyWindow = new BGSprite('philly/window', city.x, city.y, 0.3, 0.3);
		phillyWindow.setGraphicSize(Std.int(phillyWindow.width * 0.85));
		phillyWindow.updateHitbox();
		add(phillyWindow);
		phillyWindow.color = 0xFF31A2FD;

		if (!ClientPrefs.data.lowQuality) {
			var streetBehind:BGSprite = new BGSprite('philly/behindTrain', -40 + stageOffset[0], 50 + stageOffset[1]);
			streetBehind.setGraphicSize(Std.int(streetBehind.width * 0.8));
			add(streetBehind);
		}

		// var phillyTrain = new PhillyTrain(2000, 360);
		// add(phillyTrain);

		var phillyStreet = new BGSprite('philly/street', -40 + stageOffset[0], 90 + stageOffset[1]);
		phillyStreet.setGraphicSize(Std.int(phillyStreet.width * 0.82));
		add(phillyStreet);

		p1 = new Character(100, 400, "bf");
		p1.scale.set(0.7, 0.7);
		p1.updateHitbox();
		add(p1);

		p2 = new Character(550, 400, "bf", true);
		p2.scale.set(0.7, 0.7);
		p2.updateHitbox();
		add(p2);
		// POST STAGE

		player1Text = new FlxText(0, 80, 0, "PLAYER 1");
		player1Text.setFormat("VCR OSD Mono", 25, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);

		player1Bg = new FlxSprite(-1000);
		player1Bg.makeGraphic(1, 1, 0xA4000000);
		player1Bg.updateHitbox();
		player1Bg.y = player1Text.y;
		add(player1Bg);
		add(player1Text);

		player2Text = new FlxText(0, 80, 0, "PLAYER 2");
		player2Text.setFormat("VCR OSD Mono", 25, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);

		player2Bg = new FlxSprite(-1000);
		player2Bg.makeGraphic(1, 1, 0xA4000000);
		player2Bg.updateHitbox();
		player2Bg.y = player2Text.y;
		add(player2Bg);
		add(player2Text);

		chatBox = new ChatBox();
		chatBox.y = FlxG.height - chatBox.height;
		add(chatBox);

		items = new FlxTypedGroup<FlxSprite>();

		settingsIconBg = new FlxSprite();
		settingsIconBg.makeGraphic(100, 100, 0x5D000000);
		settingsIconBg.updateHitbox();
		settingsIconBg.y = FlxG.height - settingsIconBg.height - 20;
		settingsIconBg.x = FlxG.width - settingsIconBg.width - 20;
		add(settingsIconBg);

		settingsIcon = new FlxSprite(settingsIconBg.x, settingsIconBg.y);
		settingsIcon.antialiasing = ClientPrefs.data.antialiasing;
		settingsIcon.frames = Paths.getSparrowAtlas('online_settings');
		settingsIcon.animation.addByPrefix('idle', "settings", 24);
		settingsIcon.animation.play('idle');
		settingsIcon.updateHitbox();
		settingsIcon.x += settingsIconBg.width / 2 - settingsIcon.width / 2;
		settingsIcon.y += settingsIconBg.height / 2 - settingsIcon.height / 2;
		settingsIcon.ID = 0;
		items.add(settingsIcon);

		chatIconBg = new FlxSprite();
		chatIconBg.makeGraphic(100, 100, 0x5D000000);
		chatIconBg.updateHitbox();
		chatIconBg.y = settingsIconBg.y;
		chatIconBg.x = settingsIconBg.x - chatIconBg.width - 20;
		add(chatIconBg);

		chatIcon = new FlxSprite(chatIconBg.x, chatIconBg.y);
		chatIcon.antialiasing = ClientPrefs.data.antialiasing;
		chatIcon.frames = Paths.getSparrowAtlas('online_chat');
		chatIcon.animation.addByPrefix('idle', "chat", 24);
		chatIcon.animation.play('idle');
		chatIcon.updateHitbox();
		chatIcon.x += chatIconBg.width / 2 - chatIcon.width / 2;
		chatIcon.y += chatIconBg.height / 2 - chatIcon.height / 2;
		chatIcon.ID = 1;
		items.add(chatIcon);

		playIconBg = new FlxSprite();
		playIconBg.makeGraphic(100, 100, 0x5D000000);
		playIconBg.updateHitbox();
		playIconBg.y = chatIconBg.y;
		playIconBg.x = chatIconBg.x - playIconBg.width - 20;
		add(playIconBg);

		playIcon = new FlxSprite(playIconBg.x, playIconBg.y);
		playIcon.antialiasing = ClientPrefs.data.antialiasing;
		playIcon.frames = Paths.getSparrowAtlas('online_play');
		playIcon.animation.addByPrefix('idle', "play", 24);
		playIcon.animation.play('idle');
		playIcon.updateHitbox();
		playIcon.x += playIconBg.width / 2 - playIcon.width / 2;
		playIcon.y += playIconBg.height / 2 - playIcon.height / 2;
		playIcon.ID = 2;
		items.add(playIcon);
		
		roomCode = new FlxText(0, 0, 0, "Room Code: ????");
		roomCode.setFormat("VCR OSD Mono", 18, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		roomCode.x = settingsIconBg.x + settingsIconBg.width - roomCode.width;
		roomCode.y = settingsIconBg.y - roomCode.height - 10;
		roomCode.ID = 3;

		roomCodeBg = new FlxSprite();
		roomCodeBg.makeGraphic(1, 1, 0x5D000000);
		roomCodeBg.updateHitbox();
		roomCodeBg.y = roomCode.y;
		roomCodeBg.x = roomCode.x;
		roomCodeBg.scale.set(roomCode.width, roomCode.height);
		roomCodeBg.updateHitbox();
		add(roomCodeBg);
		items.add(roomCode);

		songName = new FlxText(0, 0, 0, "Selected Song: ????");
		songName.setFormat("VCR OSD Mono", 18, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		songName.x = roomCodeBg.x + roomCodeBg.width - songName.width;
		songName.y = roomCodeBg.y - songName.height - 10;
		songName.ID = 4;

		songNameBg = new FlxSprite();
		songNameBg.makeGraphic(1, 1, 0x5D000000);
		songNameBg.updateHitbox();
		songNameBg.y = songName.y;
		songNameBg.x = songName.x;
		songNameBg.scale.set(songName.width, songName.height);
		songNameBg.updateHitbox();
		add(songNameBg);
		items.add(songName);

		verifyMod = new FlxText(0, 0, 0, "...");
		verifyMod.setFormat("VCR OSD Mono", 18, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		verifyMod.x = songNameBg.x + songNameBg.width - verifyMod.width;
		verifyMod.y = songNameBg.y - verifyMod.height - 10;
		verifyMod.ID = 5;

		verifyModBg = new FlxSprite();
		verifyModBg.makeGraphic(1, 1, 0x5D000000);
		verifyModBg.updateHitbox();
		verifyModBg.y = verifyMod.y;
		verifyModBg.x = verifyMod.x;
		verifyModBg.scale.set(verifyMod.width, verifyMod.height);
		verifyModBg.updateHitbox();
		add(verifyModBg);
		items.add(verifyMod);

		add(items);

		itemTipBg = new FlxSprite(-1000);
		itemTipBg.makeGraphic(1, 1, 0xA4000000);
		itemTipBg.updateHitbox();
		add(itemTipBg);

		itemTip = new FlxText(0, 0, 0, "Placeholder");
		itemTip.setFormat("VCR OSD Mono", 18, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(itemTip);

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

		GameClient.room.onMessage("checkChart", function(message) {
			Waiter.put(() -> {
				try {
					if (GameClient.room.state.song == "")
						return;

					if (Mods.getModDirectories().contains(GameClient.room.state.modDir) || GameClient.room.state.modDir == "") {
						Mods.currentModDirectory = GameClient.room.state.modDir;
						try {
							GameClient.send("verifyChart", Md5.encode(Song.loadRawSong(GameClient.room.state.song, GameClient.room.state.folder)));
						}
						catch (exc) {}
						return;
					}

					if (GameClient.room.state.modDir != null && GameClient.room.state.modURL != null && GameClient.room.state.modURL != "") {
						OnlineMods.downloadMod(GameClient.room.state.modURL);
					}
				}
				catch (exc) {
					Sys.println(exc);
				}
			});
		});

		GameClient.room.state.listen("isPrivate", (value, prev) -> {
			if (value) {
				DiscordClient.changePresence("In a online room.", "Private room.", null, false);
			}
			else {
				DiscordClient.changePresence("In a online room.", "Public room: " + GameClient.room.roomId, null, false);
			}
		});

		playMusic((GameClient.isOwner ? GameClient.room.state.player1 : GameClient.room.state.player2).hasSong);
		(GameClient.isOwner ? GameClient.room.state.player1 : GameClient.room.state.player2).listen("hasSong", (value:Bool, prev) -> {
			playMusic(value);
		});

		GameClient.room.onMessage("ping", function(message) {
			Waiter.put(() -> {
				GameClient.send("pong");
				curLight = FlxG.random.int(0, phillyLightsColors.length - 1, [curLight]);
				phillyWindow.color = phillyLightsColors[curLight];
			});
		});

		GameClient.room.onMessage("charPlay", function(message:Array<Dynamic>) {
			Waiter.put(() -> {
				if (message == null || message[0] == null)
					return;

				playerAnim(message[0], true);
			});
		});

		updateTexts();
	}

	override function create() {
		super.create();

		FlxG.mouse.visible = true;
	}

	var elapsedShit = 0.;
    override function update(elapsed:Float) {
		elapsedShit += elapsed;

		if (elapsedShit >= 3) {
			elapsedShit = 0;
			if (GameClient.room.state.isPrivate) {
				DiscordClient.changePresence("In a online room.", "Private room.", null, false);
			}
			else {
				DiscordClient.changePresence("In a online room.", "Public room: " + GameClient.room.roomId, null, false);
			}
		}

		for (item in items) {
			if (curSelected == item.ID) {
				if (item == settingsIcon)
					item.angle += 20 * elapsed;
				else if (item == chatIcon)
					item.angle = FlxMath.lerp(item.angle, 20, elapsed * 5);

				if (item != playIcon)
					item.scale.set(FlxMath.lerp(item.scale.x, 1.1, elapsed * 10), FlxMath.lerp(item.scale.y, 1.1, elapsed * 10));
				else
					item.scale.set(FlxMath.lerp(item.scale.x, 1.2, elapsed * 10), FlxMath.lerp(item.scale.y, 1.2, elapsed * 10));
			}
			else {
				item.angle = FlxMath.lerp(item.angle, 0, elapsed * 5);
				item.scale.set(FlxMath.lerp(item.scale.x, 1, elapsed * 10), FlxMath.lerp(item.scale.y, 1, elapsed * 10));
			}
		}

		if (!chatBox.focused) {
			if (FlxG.mouse.justMoved) {
				if (mouseInsideOf(settingsIconBg)) {
					curSelected = settingsIcon.ID;
				}
				else if (mouseInsideOf(chatIconBg)) {
					curSelected = chatIcon.ID;
				}
				else if (mouseInsideOf(playIconBg)) {
					curSelected = playIcon.ID;
				}
				else if (mouseInsideOf(roomCodeBg)) {
					curSelected = roomCode.ID;
				}
				else if (mouseInsideOf(songNameBg)) {
					curSelected = songName.ID;
				}
				else if (mouseInsideOf(verifyModBg)) {
					curSelected = verifyMod.ID;
				}
				else {
					curSelected = -1;
				}
			}

			if (controls.UI_LEFT_P) {
				changeSelection(1);
			}
			if (controls.UI_RIGHT_P) {
				changeSelection(-1);
			}
			if (controls.UI_UP_P) {
				changeSelection(1);
			}
			if (controls.UI_DOWN_P) {
				changeSelection(-1);
			}

			if (controls.ACCEPT || FlxG.mouse.justPressed) {
				switch (curSelected) {
					case 0:
						openSubState(new ServerSettingsSubstate());
					case 1:
						chatBox.focused = true;
					case 2:
						var selfPlayer:Player;
						if (GameClient.isOwner)
							selfPlayer = GameClient.room.state.player1;
						else
							selfPlayer = GameClient.room.state.player2;

						if (!selfPlayer.hasSong && GameClient.room.state.song != "" && (Mods.getModDirectories().contains(GameClient.room.state.modDir) || GameClient.room.state.modDir == "")) {
							Mods.currentModDirectory = GameClient.room.state.modDir;
							try {
								GameClient.send("verifyChart", Md5.encode(Song.loadRawSong(GameClient.room.state.song, GameClient.room.state.folder)));
							}
							catch (exc) {
							}
						}
						else {
							GameClient.send("startGame");
						}
					case 3:
						roomCode.text = "Room Code: " + GameClient.room.roomId;
						roomCode.x = settingsIconBg.x + settingsIconBg.width - roomCode.width;
						roomCodeBg.scale.set(roomCode.width, roomCode.height);
						roomCodeBg.updateHitbox();
						roomCodeBg.x = roomCode.x;
					case 4:
						if (GameClient.hasPerms()) {
							GameClient.clearOnMessage();
							MusicBeatState.switchState(new FreeplayState());
							FlxG.mouse.visible = false;
						}
					case 5:
						var selfPlayer:Player;
						if (GameClient.isOwner)
							selfPlayer = GameClient.room.state.player1;
						else
							selfPlayer = GameClient.room.state.player2;

						if (GameClient.room.state.song == "")
							return;

						if (Mods.getModDirectories().contains(GameClient.room.state.modDir) || GameClient.room.state.modDir == "") {
							Mods.currentModDirectory = GameClient.room.state.modDir;
							try {
								GameClient.send("verifyChart", Md5.encode(Song.loadRawSong(GameClient.room.state.song, GameClient.room.state.folder)));
							}
							catch (exc) {}
							return;
						}

						if (!selfPlayer.hasSong && GameClient.room.state.modDir != null && GameClient.room.state.modURL != null && GameClient.room.state.modURL != "") {
							OnlineMods.downloadMod(GameClient.room.state.modURL);
						}
				}
			}

			if (FlxG.keys.justPressed.ENTER) {
				if (GameClient.hasPerms() && GameClient.room.state.player1.hasSong && GameClient.room.state.player2.hasSong) {
					GameClient.send("startGame");
				}
			}

			if (controls.BACK) {
				GameClient.leaveRoom();
			}

			if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.C) {
				Clipboard.text = GameClient.room.roomId;
			}

			if (FlxG.keys.justPressed.SHIFT) {
				openSubState(new ServerSettingsSubstate());
			}
		}

        super.update(elapsed);

		updateTexts();

		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;
    }

    function updateTexts() {
		if (GameClient.room == null)
			return;

		player1Text.x = p1.x + p1.width / 2 - player1Text.width / 2;
		player2Text.x = p2.x + p2.width / 2 - player2Text.width / 2;

		var selfPlayer:Player;
		if (GameClient.isOwner)
			selfPlayer = GameClient.room.state.player1;
		else
			selfPlayer = GameClient.room.state.player2;

		if (GameClient.room.state.modDir == "" || GameClient.room.state.song == "") {
			verifyMod.text = "No chosen mod.";
		}
		else if (selfPlayer.hasSong) {
			verifyMod.text = "Mod: " + GameClient.room.state.modDir;
		}
		else {
			if (GameClient.room.state.modURL == null || GameClient.room.state.modURL == "")
				verifyMod.text = "No mod named: " + GameClient.room.state.modDir + " (Unknown; Couldn't find mod's URL)";
			else 
				verifyMod.text = "No mod named: " + GameClient.room.state.modDir + " (Download/Verify it here!)";
		}

		verifyMod.x = songNameBg.x + songNameBg.width - verifyMod.width;
		verifyModBg.scale.set(verifyMod.width, verifyMod.height);
		verifyModBg.updateHitbox();
		verifyModBg.x = verifyMod.x;

		songName.text = "Selected Song: " + GameClient.room.state.song;
		if (!selfPlayer.hasSong)
			songName.text += " (Not found!)";
		songName.x = roomCodeBg.x + roomCodeBg.width - songName.width;
		songNameBg.scale.set(songName.width, songName.height);
		songNameBg.updateHitbox();
		songNameBg.x = songName.x;

		// if (!GameClient.hasPerms()) {
		// 	roomVisibleTip.text = "(You can't change that)";
		// 	startGameTip.text = "(Only the OP can do that)";
		// }
		// else {
		// 	roomVisibleTip.text = "(This can be changed in the settings (SHIFT))";
		// 	startGameTip.text = "(Press: ENTER to Start Game; SPACE to select song)";
		// }

		// startGame.text = "Song: " + GameClient.room.state.song;
		// roomVisible.text = GameClient.room.state.isPrivate ? "CODE ONLY" : "PUBLIC";
		// if (GameClient.room.state.player1.hasSong && GameClient.room.state.player2.hasSong) {
		// 	startGame.alpha = 1;
		// 	startGame.text += " - Ready to start!";
		// }
		// else {
		// 	startGame.alpha = 0.5;
		// 	if (GameClient.room.state.song != "" && GameClient.room.state.player2.name != "") {
		// 		startGame.text += " - " + GameClient.room.state.player2.name + " doesn't have mod: " + GameClient.room.state.modDir;
		// 	}
		// }

        player1Text.text = "PLAYER 1\n" +
            GameClient.room.state.player1.name + "\n\n" +
            "Last Song Summary\n" +
            "Score: " + GameClient.room.state.player1.score + "\n" +
			"Accuracy: " + GameClient.getPlayerAccuracyPercent(GameClient.room.state.player1) + "%\n" +
            "Sicks: " + GameClient.room.state.player1.sicks + "\n" + 
            "Goods: " + GameClient.room.state.player1.goods + "\n" +
            "Bads: " + GameClient.room.state.player1.bads + "\n" + 
            "Shits: " + GameClient.room.state.player1.shits + "\n" +
			"Misses: " + GameClient.room.state.player1.misses + "\n" + 
			"Ping: " + GameClient.room.state.player1.ping + "ms";
		if (GameClient.room.state.player1.isReady)
			player1Text.text += "\nREADY";
		else
			player1Text.text += "\nNOT READY";

		if (GameClient.room.state.player2 != null && GameClient.room.state.player2.name != "") {
			player2Text.alpha = 1;
			p2.alpha = 1;
            player2Text.text = "PLAYER 2\n" +
                GameClient.room.state.player2.name + "\n\n" +
                "Last Song Summary\n" +
                "Score: " + GameClient.room.state.player2.score + "\n" +
				"Accuracy: " + GameClient.getPlayerAccuracyPercent(GameClient.room.state.player2) + "%\n" +
                "Sicks: " + GameClient.room.state.player2.sicks + "\n" + 
                "Goods: " + GameClient.room.state.player2.goods + "\n" +
                "Bads: " + GameClient.room.state.player2.bads + "\n" + 
                "Shits: " + GameClient.room.state.player2.shits + "\n" + 
				"Misses: " + GameClient.room.state.player2.misses + "\n" +
				"Ping: " + GameClient.room.state.player2.ping + "ms";
			if (GameClient.room.state.player2.isReady)
				player2Text.text += "\nREADY";
			else
				player2Text.text += "\nNOT READY";
        }
        else {
			player2Text.text = "WAITING FOR OPPONENT...";
			player2Text.alpha = 0.8;
			p2.alpha = 0.4;
        }

		player1Bg.x = player1Text.x;
		player1Bg.scale.set(player1Text.width, player1Text.height);
		player1Bg.updateHitbox();

		player2Bg.x = player2Text.x;
		player2Bg.scale.set(player2Text.width, player2Text.height);
		player2Bg.updateHitbox();

		switch (curSelected) {
			case 0:
				itemTip.text = " - SETTINGS - \nOpens server settings.\n\n(Keybind: SHIFT)";
			case 1:
				itemTip.text = " - CHAT - \nOpens chat.\n\n(Keybind: TAB)";
			case 2:
				itemTip.text = " - START GAME/READY - \nToggles your READY status.\nPlayers need to have the currently\nselected mod installed.\nAll players should also be ready to start.";
			case 3:
				itemTip.text = " - ROOM CODE - \nUnique code of this room.\n\nACCEPT - Reveals the code.\nCTRL + C - Copies it without revealing.";
			case 4:
				itemTip.text = " - SELECT SONG - \nSelects the song.\n\n(Players with host permissions\ncan only do that)";
			case 5:
				itemTip.text = " - VERIFY MOD - \nDownloads the currently selected mod\nif it isn't installed.\n\nAfter you install it\npress this button again!";
			default:
				itemTip.text = " - LOBBY - \nPress UI keybinds\nor use your mouse\nto select an option!";
		}

		itemTip.x = settingsIconBg.x + settingsIconBg.width - itemTip.width;
		itemTip.y = verifyMod.y - itemTip.height - 20;
		itemTipBg.x = itemTip.x;
		itemTipBg.y = itemTip.y;
		itemTipBg.scale.set(itemTip.width, itemTip.height);
		itemTipBg.updateHitbox();
    }

	function changeSelection(diffe:Int) {
		curSelected += diffe;

		if (curSelected >= items.length) {
			curSelected = 0;
		}
		else if (curSelected < 0) {
			curSelected = items.length - 1;
		}
	}

	function playMusic(value:Bool) {
		if (value) {
			Mods.currentModDirectory = GameClient.room.state.modDir;
			PlayState.SONG = Song.loadFromJson(GameClient.room.state.song, GameClient.room.state.folder);
			FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.5);
			Conductor.mapBPMChanges(PlayState.SONG);
			Conductor.bpm = PlayState.SONG.bpm;
		}
		else {
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 0.5);
			Conductor.bpm = 102;
		}
	}

	function mouseInsideOf(object:FlxObject) {
		return 
			FlxG.mouse.x >= object.x && FlxG.mouse.x <= object.x + object.width &&
			FlxG.mouse.y >= object.y && FlxG.mouse.y <= object.y + object.height
		;
	}

	function playerAnim(anim:String, incoming:Bool) {
		if (!GameClient.isOwner) {
			(incoming ? p1 : p2).playAnim(anim, true);
		}
		else {
			(incoming ? p2 : p1).playAnim(anim, true);
		}

		if (!incoming)
			GameClient.send("charPlay", [anim]);
	}

	override function beatHit() {
		super.beatHit();

		if (curBeat % p1.danceEveryNumBeats == 0)
			p1.dance();
		
		if (curBeat % p2.danceEveryNumBeats == 0)
			p2.dance();
	}

	
}