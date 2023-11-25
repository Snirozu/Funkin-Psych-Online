package online.states;

import lime.system.Clipboard;
import online.schema.Player;
import backend.Rating;
import backend.WeekData;
import backend.Song;
import haxe.crypto.Md5;
import states.FreeplayState;

class Room extends MusicBeatState {
	var player1Text:FlxText;
	var player2Text:FlxText;
	var roomCode:FlxText;
	var roomCodeTip:FlxText;
	var roomVisible:FlxText;
	var roomVisibleTip:FlxText;
	var startGame:FlxText;
	var startGameTip:FlxText;
	var chatBox:ChatBox;
	var chatBoxTip:FlxText;
	var settingsTip:FlxText;
	
	public function new() {
		super();

		if (GameClient.room.state.isPrivate) {
			DiscordClient.changePresence("In a online room.", "Private room.", null, true);
		}
		else {
			DiscordClient.changePresence("In a online room.", "Public room: " + GameClient.room.roomId, null, true);
		}

		WeekData.reloadWeekFiles(false);
		for (i in 0...WeekData.weeksList.length) {
			WeekData.setDirectoryFromWeek(WeekData.weeksLoaded.get(WeekData.weeksList[i]));
		}
		Mods.loadTopMod();
		WeekData.setDirectoryFromWeek();

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xff542680;
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

		player1Text = new FlxText(0, 50, 0, "PLAYER 1");
		player1Text.setFormat("VCR OSD Mono", 30, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(player1Text);

		player2Text = new FlxText(0, 50, 0, "PLAYER 2");
		player2Text.setFormat("VCR OSD Mono", 30, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(player2Text);

		roomCode = new FlxText(0, 0, FlxG.width, "????");
		roomCode.setFormat("VCR OSD Mono", 25, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		roomCode.y = FlxG.height - 70;
		roomCode.screenCenter(X);
		add(roomCode);

		roomCodeTip = new FlxText(0, roomCode.y + roomCode.height + 5, FlxG.width, "(Press S to show your room code, CTRL+C to copy)");
		roomCodeTip.setFormat("VCR OSD Mono", 18, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		roomCodeTip.screenCenter(X);
		add(roomCodeTip);

		roomVisible = new FlxText(0, 0, FlxG.width, "CODE ONLY");
		roomVisible.setFormat("VCR OSD Mono", 25, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		roomVisible.y = roomCode.y - 70;
		roomVisible.screenCenter(X);
		add(roomVisible);

		roomVisibleTip = new FlxText(0, roomVisible.y + roomVisible.height + 5, FlxG.width, "");
		roomVisibleTip.setFormat("VCR OSD Mono", 18, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		roomVisibleTip.screenCenter(X);
		add(roomVisibleTip);

		startGame = new FlxText(0, 0, FlxG.width, "");
		startGame.setFormat("VCR OSD Mono", 22, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		startGame.y = roomVisible.y - 70;
		startGame.screenCenter(X);
		add(startGame);

		startGameTip = new FlxText(0, startGame.y + startGame.height + 5, FlxG.width, "");
		startGameTip.setFormat("VCR OSD Mono", 18, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		startGameTip.screenCenter(X);
		add(startGameTip);

		chatBox = new ChatBox();
		chatBox.y = FlxG.height - chatBox.height;
		add(chatBox);

		chatBoxTip = new FlxText(0, 0, 0, "(Press TAB to show chat)");
		chatBoxTip.setFormat("VCR OSD Mono", 18, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		chatBoxTip.y = FlxG.height - chatBoxTip.height;
		chatBoxTip.y -= 20;
		chatBoxTip.x += 20;
		add(chatBoxTip);

		settingsTip = new FlxText(0, 0, 0, "(Press SHIFT to open settings)");
		settingsTip.setFormat("VCR OSD Mono", 18, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		settingsTip.y = FlxG.height - settingsTip.height;
		settingsTip.y -= 20;
		settingsTip.x = FlxG.width - settingsTip.width - 20;
		add(settingsTip);

		GameClient.room.onMessage("gameStarted", function(message) {
			Waiter.put(() -> {
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
					Mods.currentModDirectory = GameClient.room.state.modDir;
					GameClient.send("verifyChart", Md5.encode(Song.loadRawSong(GameClient.room.state.song, GameClient.room.state.folder)));
				}
				catch (exc) {
					Sys.println(exc);
				}
			});
		});

		GameClient.room.onMessage("log", function(message) {
			Waiter.put(() -> {
				chatBox.addMessage(message);
				var sond = FlxG.sound.play(Paths.sound('scrollMenu'));
				sond.pitch = 1.5;
			});
		});

		GameClient.room.state.listen("isPrivate", (value, prev) -> {
			if (value) {
				DiscordClient.changePresence("In a online room.", "Private room.", null, true);
			}
			else {
				DiscordClient.changePresence("In a online room.", "Public room: " + GameClient.room.roomId, null, true);
			}
		});

		updateTexts();
	}

    override function update(elapsed) {
		if (!chatBox.focused) {
			if (FlxG.keys.justPressed.ENTER) {
				if (GameClient.hasPerms() && GameClient.room.state.player1.hasSong && GameClient.room.state.player2.hasSong) {
					GameClient.send("startGame");
				}
			}

			if (FlxG.keys.justPressed.SPACE) {
				if (GameClient.hasPerms()) {
					GameClient.clearOnMessage();
					MusicBeatState.switchState(new FreeplayState());
				}
			}

			if (FlxG.keys.justPressed.S) {
				roomCode.text = GameClient.room.roomId;
				roomCodeTip.text = "(This is your room code)";
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

		chatBoxTip.visible = chatBox.alpha <= 0;

		updateTexts();

		player1Text.x = FlxG.width / 2 - 200 - player1Text.width;
		player2Text.x = FlxG.width / 2 + 200;

		roomCode.screenCenter(X);
		roomCodeTip.screenCenter(X);
		roomVisible.screenCenter(X);
		roomVisibleTip.screenCenter(X);
		startGame.screenCenter(X);
		startGameTip.screenCenter(X);
    }

    function updateTexts() {
		if (GameClient.room == null)
			return;

		if (!GameClient.hasPerms()) {
			roomVisibleTip.text = "(You can't change that)";
			startGameTip.text = "(Only the OP can do that)";
		}
		else {
			roomVisibleTip.text = "(This can be changed in the settings (SHIFT))";
			startGameTip.text = "(Press: ENTER to Start Game; SPACE to select song)";
		}

		startGame.text = "Song: " + GameClient.room.state.song;
		roomVisible.text = GameClient.room.state.isPrivate ? "CODE ONLY" : "PUBLIC";
		if (GameClient.room.state.player1.hasSong && GameClient.room.state.player2.hasSong) {
			startGame.alpha = 1;
			startGame.text += " - Ready to start!";
		}
		else {
			startGame.alpha = 0.5;
			if (GameClient.room.state.song != "none" && GameClient.room.state.player2.name != "") {
				startGame.text += " - " + GameClient.room.state.player2.name + " doesn't have mod: " + GameClient.room.state.modDir;
			}
		}

        player1Text.text = "PLAYER 1\n" +
            GameClient.room.state.player1.name + "\n\n" +
            "Last Song Summary\n" +
            "Score: " + GameClient.room.state.player1.score + "\n" +
			"Accuracy: " + getPlayerAccuracyPercent(GameClient.room.state.player1) + "%\n" +
            "Sicks: " + GameClient.room.state.player1.sicks + "\n" + 
            "Goods: " + GameClient.room.state.player1.goods + "\n" +
            "Bads: " + GameClient.room.state.player1.bads + "\n" + 
            "Shits: " + GameClient.room.state.player1.shits + "\n" +
			"Misses: " + GameClient.room.state.player1.misses + "\n" + 
			"Ping: " + GameClient.room.state.player1.ping + "ms";

		if (GameClient.room.state.player2 != null) {
            player2Text.text = "PLAYER 2\n" +
                GameClient.room.state.player2.name + "\n\n" +
                "Last Song Summary\n" +
                "Score: " + GameClient.room.state.player2.score + "\n" +
				"Accuracy: " + getPlayerAccuracyPercent(GameClient.room.state.player2) + "%\n" +
                "Sicks: " + GameClient.room.state.player2.sicks + "\n" + 
                "Goods: " + GameClient.room.state.player2.goods + "\n" +
                "Bads: " + GameClient.room.state.player2.bads + "\n" + 
                "Shits: " + GameClient.room.state.player2.shits + "\n" + 
				"Misses: " + GameClient.room.state.player2.misses + "\n" +
				"Ping: " + GameClient.room.state.player2.ping + "ms";
        }
        else {
			player2Text.text = "WAITING FOR OPPONENT...";
        }

		// player1BG.scale.set(player1Text.width + 10, player1Text.height + 10);
		// player2BG.scale.set(player2Text.width + 10, player2Text.height + 10);
		// player1BG.setPosition(player1Text.x - 5, player1Text.y - 5);
		// player2BG.setPosition(player1Text.x - 5, player2Text.y - 5);
    }

	public var ratingsData:Array<Rating> = Rating.loadDefault(); // from PlayState

	function getPlayerAccuracyPercent(player:Player) {
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