package online.states;

import flixel.util.FlxAxes;
import flixel.addons.display.FlxPieDial;
import sys.FileSystem;
import states.stages.Philly;
import flixel.FlxSubState;
import flixel.group.FlxGroup;
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
	var p1Layer:FlxTypedGroup<Character> = new FlxTypedGroup<Character>();
	var p2Layer:FlxTypedGroup<Character> = new FlxTypedGroup<Character>();

	var curSelected:Int = -1;
	var items:FlxTypedGroup<FlxSprite>;
	var settingsIconBg:FlxSprite;
	var settingsIcon:FlxSprite;
	var chatIconBg:FlxSprite;
	var chatIcon:FlxSprite;

	var itemTip:FlxText;
	var itemTipBg:FlxSprite;

	var stage:Philly;

	var cum:FlxCamera = new FlxCamera();
	var camHUD:FlxCamera = new FlxCamera();
	var groupHUD:FlxGroup;

	var leavePie:LeavePie;

	var revealTimer:FlxTimer;
	var playerHold(default, set):Bool = false;
	var oppHold:Bool = false;

	static var instance:Room = null;

	function set_playerHold(v) {
		if (playerHold != v) {
			playerHold = v;
			GameClient.send("noteHold", v);
		}
		return v;
	}

	public function new() {
		super();

		instance = this;

		GameClient.room.onMessage("checkChart", function(message) {
			Waiter.put(() -> {
				verifyDownloadMod(true);
			});
		});

		playMusic((GameClient.isOwner ? GameClient.room.state.player1 : GameClient.room.state.player2).hasSong);
		(GameClient.isOwner ? GameClient.room.state.player1 : GameClient.room.state.player2).listen("hasSong", (value:Bool, prev) -> {
			Waiter.put(() -> {
				playMusic(value);
			});
		});

		GameClient.room.state.player1.listen("skinName", (value, prev) -> {
			if (value == prev) return;
			Waiter.put(() -> {
				loadCharacter(true);
			});
		});
		GameClient.room.state.player2.listen("skinName", (value, prev) -> {
			if (value == prev) return;
			Waiter.put(() -> {
				loadCharacter(false);
			});
		});

		GameClient.room.state.player1.listen("isReady", (value, prev) -> {
			Waiter.put(() -> {
				if (value) {
					var sond = FlxG.sound.play(Paths.sound('scrollMenu'), 0.5);
					sond.pitch = 1.1;
				}
				// else {
				// 	var sond = FlxG.sound.play(Paths.sound('cancelMenu'));
				// 	sond.pitch = 1.1;
				// }
			});
		});
		GameClient.room.state.player2.listen("isReady", (value, prev) -> {
			Waiter.put(() -> {
				if (value) {
					var sond = FlxG.sound.play(Paths.sound('scrollMenu'), 0.5);
					sond.pitch = 1.1;
				}
				// else {
				// 	var sond = FlxG.sound.play(Paths.sound('cancelMenu'));
				// 	sond.pitch = 1.1;
				// }
			});
		});

		// GameClient.room.onMessage("ping", function(message) {
		// 	Waiter.put(() -> {
		// 		GameClient.send("pong");
		// 		@:privateAccess {
		// 			if (stage?.phillyWindow == null) return;
		// 			stage.curLight = FlxG.random.int(0, stage.phillyLightsColors.length - 1, [stage.curLight]);
		// 			stage.phillyWindow.color = stage.phillyLightsColors[stage.curLight];
		// 		}
		// 	});
		// });

		GameClient.room.onMessage("charPlay", function(message:Array<Dynamic>) {
			Waiter.put(() -> {
				if (message == null || message[0] == null)
					return;

				playerAnim(message[0], true);
			});
		});

		GameClient.room.onMessage("noteHold", function(?message:Bool) {
			Waiter.put(() -> {
				if (message == null) {
					return;
				}
				oppHold = message;
			});
		});
	}

	var waitingForPlayer1Skin = false;
	var waitingForPlayer2Skin = false;

	override function create() {
		super.create();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Lobby", null, null, false);
		#end

		WeekData.reloadWeekFiles(false);
		for (i in 0...WeekData.weeksList.length) {
			WeekData.setDirectoryFromWeek(WeekData.weeksLoaded.get(WeekData.weeksList[i]));
		}
		Mods.loadTopMod();
		WeekData.setDirectoryFromWeek();

		FlxG.cameras.reset(cum);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.setDefaultDrawTarget(cum, true);
		camHUD.bgColor.alpha = 0;

		groupHUD = new FlxGroup();
		groupHUD.cameras = [camHUD];

		// STAGE
		Paths.setCurrentLevel("week3");

		stage = new Philly();
		stage.cameras = [cum];
		@:privateAccess {
			stage.phillyTrain.sound.volume = 0;

			if (!ClientPrefs.data.lowQuality) {
				stage.bg.setGraphicSize(Std.int(stage.bg.width * 1));
				stage.bg.updateHitbox();

				stage.bg.x -= 80;
				stage.bg.y -= 50;
			}
			stage.city.setGraphicSize(Std.int(stage.city.width * 1.1));
			stage.city.updateHitbox();
			stage.phillyWindow.setGraphicSize(Std.int(stage.phillyWindow.width * 1.1));
			stage.phillyWindow.updateHitbox();

			stage.city.x -= 80;
			stage.phillyWindow.x -= 80;
			stage.city.y -= 20;
			stage.phillyWindow.y -= 20;
		}
		add(stage);

		cum.scroll.set(100, 130);
		cum.zoom = 0.9;

		add(p1Layer);
		add(p2Layer);

		loadCharacter(true);
		loadCharacter(false);

		// POST STAGE

		player1Text = new FlxText(0, 100, 0, "PLAYER 1");
		player1Text.setFormat("VCR OSD Mono", 25, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);

		player1Bg = new FlxSprite(-1000);
		player1Bg.makeGraphic(1, 1, 0xA4000000);
		player1Bg.updateHitbox();
		player1Bg.y = player1Text.y - 30;
		groupHUD.add(player1Bg);
		groupHUD.add(player1Text);

		player2Text = new FlxText(0, 100, 0, "PLAYER 2");
		player2Text.setFormat("VCR OSD Mono", 25, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);

		player2Bg = new FlxSprite(-1000);
		player2Bg.makeGraphic(1, 1, 0xA4000000);
		player2Bg.updateHitbox();
		player2Bg.y = player2Text.y - 30;
		groupHUD.add(player2Bg);
		groupHUD.add(player2Text);

		chatBox = new ChatBox(camHUD, (cmd, args) -> {
			switch (cmd) {
				case "help":
					ChatBox.addMessage("> Room Commands: /pa, /results");
					return true;
				case "pa":
					if (args[0] != null && args[0].trim() != "")
						playerAnim(args[0]);
					else {
						var anims = "";
						for (anim in @:privateAccess getPlayer().animation._animations)
							anims += '"${anim.name}" ';
						ChatBox.addMessage("Please enter the animation you want to play!\nAvailable animations: " + anims);
					}
					return true;
				case "results":
					FlxG.switchState(() -> new ResultsScreen());
					return true;
				default:
					return false;
			}
		});
		groupHUD.add(chatBox);

		items = new FlxTypedGroup<FlxSprite>();

		settingsIconBg = new FlxSprite();
		settingsIconBg.makeGraphic(100, 100, 0x5D000000);
		settingsIconBg.updateHitbox();
		settingsIconBg.y = FlxG.height - settingsIconBg.height - 20;
		settingsIconBg.x = FlxG.width - settingsIconBg.width - 20;
		groupHUD.add(settingsIconBg);

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
		groupHUD.add(chatIconBg);

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
		groupHUD.add(playIconBg);

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
		groupHUD.add(roomCodeBg);
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
		groupHUD.add(songNameBg);
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
		groupHUD.add(verifyModBg);
		items.add(verifyMod);

		groupHUD.add(items);

		itemTipBg = new FlxSprite(-1000);
		itemTipBg.makeGraphic(1, 1, 0xA4000000);
		itemTipBg.updateHitbox();
		groupHUD.add(itemTipBg);

		itemTip = new FlxText(0, 0, 0, "Placeholder");
		itemTip.setFormat("VCR OSD Mono", 18, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		groupHUD.add(itemTip);

		groupHUD.add(leavePie = new LeavePie());

		add(groupHUD);
		
		updateTexts();

		FlxG.mouse.visible = true;
		FlxG.autoPause = false;

		verifyDownloadMod(true);

		GameClient.send("status", "In the Lobby");
	}

	function loadCharacter(isP1:Bool, ?enableDownload:Bool = true) {
		var oldModDir = Mods.currentModDirectory;

		if (isP1) {
			if (p1Layer == null || p1Layer.members == null) //what
				return;
			if (p1 != null)
				p1.destroy();
			p1 = null;
			p1Layer.clear();

			if (FileSystem.exists(Paths.mods(GameClient.room.state.player1.skinMod))) {
				if (GameClient.room.state.player1.skinMod != null)
					Mods.currentModDirectory = GameClient.room.state.player1.skinMod;

				if (GameClient.room.state.player1.skinName != null)
					p1 = new Character(0, 0, GameClient.room.state.player1.skinName);
			}
			else if (enableDownload && GameClient.room.state.player1.skinURL != null) {
				waitingForPlayer1Skin = true;
				OnlineMods.downloadMod(GameClient.room.state.player1.skinURL, (_) -> {
					if (destroyed)
						return;

					loadCharacter(isP1, false);
					waitingForPlayer1Skin = false;
				});
			}

			if (p1 == null)
				p1 = new Character(0, 0, "default");
			p1.x = 100 + p1.positionArray[0];
			p1.y = 120 + p1.positionArray[1];

			p1Layer.add(p1);
		}
		else 
		{
			if (p2Layer == null || p2Layer.members == null)
				return;
			if (p2 != null)
				p2.destroy();
			p2 = null;
			p2Layer.clear();

			if (FileSystem.exists(Paths.mods(GameClient.room.state.player2.skinMod))) {
				if (GameClient.room.state.player2.skinMod != null)
					Mods.currentModDirectory = GameClient.room.state.player2.skinMod;

				if (GameClient.room.state.player2.skinName != null)
					p2 = new Character(0, 0, GameClient.room.state.player2.skinName + "-player", true);
			}
			else if (enableDownload && GameClient.room.state.player2.skinURL != null) {
				waitingForPlayer2Skin = true;
				OnlineMods.downloadMod(GameClient.room.state.player2.skinURL, (_) -> {
					if (destroyed)
						return;

					loadCharacter(isP1, false);
					waitingForPlayer2Skin = false;
				});
			}

			if (p2 == null)
				p2 = new Character(/*770*/ 0, 0, "default-player", true);
			p2.x = 600 + p2.positionArray[0];
			p2.y = 120 + p2.positionArray[1];

			p2Layer.add(p2);
		}
		
		Mods.currentModDirectory = oldModDir;
	}

	override function openSubState(obj:FlxSubState) {
		obj.cameras = [camHUD];
		super.openSubState(obj);
	}

	override function closeSubState() {
		super.closeSubState();

		GameClient.send("status", "In the Lobby");
	}

	var optionShake:FlxTween;

	var elapsedShit = 3.;
    override function update(elapsed:Float) {
		if (!GameClient.isConnected()) {
			return;
		}
		
		// if (FlxG.keys.justPressed.SPACE) {
		// 	Alert.alert("Camera Location:", '${cum.scroll.x},${cum.scroll.y} x ${cum.zoom}');
		// }
		// if (FlxG.keys.pressed.U) {
		// 	cum.zoom -= elapsed * 0.5;
		// }
		// if (FlxG.keys.pressed.O) {
		// 	cum.zoom += elapsed * 0.5;
		// }
		// if (FlxG.keys.pressed.I) {
		// 	cum.scroll.y -= elapsed * 20;
		// }
		// if (FlxG.keys.pressed.J) {
		// 	cum.scroll.x -= elapsed * 20;
		// }
		// if (FlxG.keys.pressed.K) {
		// 	cum.scroll.y += elapsed * 20;
		// }
		// if (FlxG.keys.pressed.L) {
		// 	cum.scroll.x += elapsed * 20;
		// }

		#if DISCORD_ALLOWED
		elapsedShit += elapsed;

		if (elapsedShit >= 3) {
			elapsedShit = 0;
			DiscordClient.updateOnlinePresence();
		}
		#end

		for (item in items) {
			if (curSelected == item.ID) {
				if (item == settingsIcon)
					item.angle += 20 * elapsed;
				else if (item == chatIcon)
					item.angle = FlxMath.lerp(item.angle, 20, elapsed * 5);

				if (item == playIcon) {
					if (getSelfPlayer().hasSong) {
						item.scale.set(FlxMath.lerp(item.scale.x, 1.2, elapsed * 10), FlxMath.lerp(item.scale.y, 1.2, elapsed * 10));
					}
					else {
						item.scale.set(FlxMath.lerp(item.scale.x, 1.05, elapsed * 10), FlxMath.lerp(item.scale.y, 1.05, elapsed * 10));
					}
				}
				else
					item.scale.set(FlxMath.lerp(item.scale.x, 1.1, elapsed * 10), FlxMath.lerp(item.scale.y, 1.1, elapsed * 10));
			}
			else {
				item.angle = FlxMath.lerp(item.angle, 0, elapsed * 5);
				item.scale.set(FlxMath.lerp(item.scale.x, 1, elapsed * 10), FlxMath.lerp(item.scale.y, 1, elapsed * 10));
			}
		}
		playIcon.alpha = getSelfPlayer().hasSong ? 1.0 : 0.5;

		if (!chatBox.focused) {
			if (FlxG.mouse.justMoved) {
				if (FlxG.mouse.overlaps(settingsIconBg, camHUD)) {
					curSelected = settingsIcon.ID;
				}
				else if (FlxG.mouse.overlaps(chatIconBg, camHUD)) {
					curSelected = chatIcon.ID;
				}
				else if (FlxG.mouse.overlaps(playIconBg, camHUD)) {
					curSelected = playIcon.ID;
				}
				else if (FlxG.mouse.overlaps(roomCodeBg, camHUD)) {
					curSelected = roomCode.ID;
				}
				else if (FlxG.mouse.overlaps(songNameBg, camHUD)) {
					curSelected = songName.ID;
				}
				else if (FlxG.mouse.overlaps(verifyModBg, camHUD)) {
					curSelected = verifyMod.ID;
				}
				else {
					curSelected = -1;
				}
			}

			if (controls.TAUNT)
				playerAnim('taunt');

			var held = false;
			for (key in ['note_left', 'note_down', 'note_up', 'note_right']) {
				if (controls.pressed(key)) {
					held = true;
					break;
				}
			}
			playerHold = held;

			// trace('playerHold = ' + playerHold + ', oppHold = ' + oppHold);

			if (FlxG.keys.pressed.ALT) { // useless, but why not?
				var suffix = FlxG.keys.pressed.CONTROL ? 'miss' : '';
				if (controls.NOTE_LEFT_P) {
					playerAnim('singLEFT' + suffix);
				}
				if (controls.NOTE_RIGHT_P) {
					playerAnim('singRIGHT' + suffix);
				}
				if (controls.NOTE_UP_P) {
					playerAnim('singUP' + suffix);
				}
				if (controls.NOTE_DOWN_P) {
					playerAnim('singDOWN' + suffix);
				}
			} else {
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
			}
			
			danceLogic(p1);
			danceLogic(p2);
			
			if (controls.ACCEPT || FlxG.mouse.justPressed) {
				switch (curSelected) {
					case 0:
						openSubState(new ServerSettingsSubstate());
					case 1:
						chatBox.focused = true;
					case 2:
						var selfPlayer:Player = getSelfPlayer();

						if (!selfPlayer.hasSong && GameClient.room.state.song != "" && (Mods.getModDirectories().contains(GameClient.room.state.modDir) || GameClient.room.state.modDir == "")) {
							Mods.currentModDirectory = GameClient.room.state.modDir;
							try {
								GameClient.send("verifyChart", Md5.encode(Song.loadRawSong(GameClient.room.state.song, GameClient.room.state.folder)));
							}
							catch (exc) {
								Alert.alert("Caught an exception!", exc.toString());
								if (optionShake != null)
									optionShake.cancel();
								optionShake = FlxTween.shake(playIcon, 0.05, 0.3, FlxAxes.X);
							}
						}
						else if (selfPlayer.hasSong) {
							GameClient.send("startGame");
						}
						else {
							if (GameClient.room.state.song == "") {
								Alert.alert("Song isn't selected!");
							}
							else {
								Alert.alert("You don't have the current song/mod!");
							}
							var sond = FlxG.sound.play(Paths.sound('badnoise' + FlxG.random.int(1, 3)));
							sond.pitch = 1.1;
							if (optionShake != null)
								optionShake.cancel();
							optionShake = FlxTween.shake(playIcon, 0.05, 0.3, FlxAxes.X);
						}
					case 3:
						roomCode.text = 'Room Code: "' + GameClient.getRoomSecret() + '"';
						roomCode.x = settingsIconBg.x + settingsIconBg.width - roomCode.width;
						roomCodeBg.scale.set(roomCode.width, roomCode.height);
						roomCodeBg.updateHitbox();
						roomCodeBg.x = roomCode.x;
						if (revealTimer != null)
							revealTimer.cancel();
						revealTimer = new FlxTimer().start(10, (t) -> {
							roomCode.text = "Room Code: ????";
							roomCode.x = settingsIconBg.x + settingsIconBg.width - roomCode.width;
							roomCodeBg.scale.set(roomCode.width, roomCode.height);
							roomCodeBg.updateHitbox();
							roomCodeBg.x = roomCode.x;
						});
						Clipboard.text = GameClient.getRoomSecret(true);
						Alert.alert("Room code copied!");
					case 4:
						if (GameClient.hasPerms()) {
							GameClient.clearOnMessage();
							FlxG.switchState(() -> new FreeplayState());
							FlxG.mouse.visible = false;
						}
						else {
							Alert.alert("Only the host can do that!");
							var sond = FlxG.sound.play(Paths.sound('badnoise' + FlxG.random.int(1, 3)));
							sond.pitch = 1.1;
							if (optionShake != null)
								optionShake.cancel();
							optionShake = FlxTween.shake(songName, 0.05, 0.3, FlxAxes.X);
						}
					case 5:
						if (verifyDownloadMod()) {
							GameClient.clearOnMessage();
							FlxG.switchState(() -> new BananaDownload());
						}
				}
			}
			else if (FlxG.mouse.justPressedRight) {
				if (curSelected == 5)
					FlxG.switchState(() -> new BananaDownload());
			}

			if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.C) {
				Clipboard.text = GameClient.getRoomSecret(true);
				Alert.alert("Room code copied!");
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
	
	function verifyDownloadMod(?ignoreAlert:Bool = false) {
		try {
			if (GameClient.room.state.song == "") {
				if (ignoreAlert)
					return false;

				if (GameClient.hasPerms())
					return true;

				Alert.alert("Song isn't selected!");
				var sond = FlxG.sound.play(Paths.sound('badnoise' + FlxG.random.int(1, 3)));
				sond.pitch = 1.1;
				if (optionShake != null)
					optionShake.cancel();
				optionShake = FlxTween.shake(verifyMod, 0.05, 0.3, FlxAxes.X);
				return false;
			}
			if (getSelfPlayer().hasSong) {
				if (ignoreAlert)
					return false;

				if (GameClient.hasPerms())
					return true;

				Alert.alert("You already have this song installed!");
				var sond = FlxG.sound.play(Paths.sound('badnoise' + FlxG.random.int(1, 3)));
				sond.pitch = 1.1;
				if (optionShake != null)
					optionShake.cancel();
				optionShake = FlxTween.shake(verifyMod, 0.05, 0.3, FlxAxes.X);
				return false;
			}

			if (Mods.getModDirectories().contains(GameClient.room.state.modDir) || GameClient.room.state.modDir == "") {
				Mods.currentModDirectory = GameClient.room.state.modDir;
				try {
					GameClient.send("verifyChart", Md5.encode(Song.loadRawSong(GameClient.room.state.song, GameClient.room.state.folder)));
				}
				catch (exc) {
				}
				return false;
			}

			if (GameClient.room.state.modDir != null && GameClient.room.state.modURL != null && GameClient.room.state.modURL != "") {
				OnlineMods.downloadMod(GameClient.room.state.modURL, (mod) -> {
					if (destroyed)
						return;

					if (GameClient.isConnected() && GameClient.room.state.modDir == mod) {
						if (Mods.getModDirectories().contains(GameClient.room.state.modDir)) {
							Mods.currentModDirectory = GameClient.room.state.modDir;
							GameClient.send("verifyChart", Md5.encode(Song.loadRawSong(GameClient.room.state.song, GameClient.room.state.folder)));
						}
					}
				});
			}
			else if (!ignoreAlert) {
				if (GameClient.room.state.modURL == null || GameClient.room.state.modURL == "") {
					Alert.alert("Mod couldn't be found!", "Host didn't specify the URL of this mod");
				}
				else if (Mods.getModDirectories().contains(GameClient.room.state.modDir)) {
					Alert.alert("Mod couldn't be found!", "Expected mod data to exist in this path: " + (GameClient.room.state.modDir ?? "mods/"));
				}
				var sond = FlxG.sound.play(Paths.sound('badnoise' + FlxG.random.int(1, 3)));
				sond.pitch = 1.1;
				if (optionShake != null)
					optionShake.cancel();
				optionShake = FlxTween.shake(verifyMod, 0.05, 0.3, FlxAxes.X);
			}
		}
		catch (exc) {
			Sys.println(exc);
		}

		return false;
	}

    function updateTexts() {
		if (GameClient.room == null)
			return;

		player1Text.x = 250 - player1Text.width / 2;
		player2Text.x = 700 - player2Text.width / 2;

		var selfPlayer:Player = getSelfPlayer();

		if (GameClient.room.state.modDir == "" || GameClient.room.state.song == "") {
			verifyMod.text = "No chosen mod.";
		}
		else if (selfPlayer.hasSong) {
			verifyMod.text = "Mod: " + GameClient.room.state.modDir;
		}
		else {
			if (GameClient.room.state.modURL == null || GameClient.room.state.modURL == "")
				verifyMod.text = "No mod named: " + GameClient.room.state.modDir + " (Unknown; Host didn't specify mod's URL)";
			else 
				verifyMod.text = "No mod named: " + GameClient.room.state.modDir + " (Download/Verify it here!)";
		}

		verifyMod.x = songNameBg.x + songNameBg.width - verifyMod.width;
		verifyModBg.scale.set(verifyMod.width, verifyMod.height);
		verifyModBg.updateHitbox();
		verifyModBg.x = verifyMod.x;

		songName.text = "Selected Song: " + GameClient.room.state.song;
		if (GameClient.room.state.song == null || GameClient.room.state.song.trim() == "")
			songName.text += "(None)";
		else if (!selfPlayer.hasSong)
			songName.text += " (Not found!)";
		songName.x = roomCodeBg.x + roomCodeBg.width - songName.width;
		songNameBg.scale.set(songName.width, songName.height);
		songNameBg.updateHitbox();
		songNameBg.x = songName.x;

		player1Text.text = returnPlayerText(GameClient.room.state.player1);

		if (GameClient.room.state.player2 != null && GameClient.room.state.player2.name != "") {
			player2Text.alpha = 1;
			p2.colorTransform.redOffset = 0;
			p2.colorTransform.greenOffset = 0;
			p2.colorTransform.blueOffset = 0;
			p2.alpha = 1;
			player2Text.text = returnPlayerText(GameClient.room.state.player2);
        }
        else {
			player2Text.text = "WAITING FOR\nOPPONENT";
			player2Text.alpha = 0.8;
			p2.colorTransform.redOffset = -255;
			p2.colorTransform.greenOffset = -255;
			p2.colorTransform.blueOffset = -255;
			p2.alpha = 0.5;
			if (p2.curCharacter != "default-player")
				loadCharacter(false);
        }

		if (waitingForPlayer1Skin) {
			p1.colorTransform.redOffset = -255;
			p1.colorTransform.greenOffset = -255;
			p1.colorTransform.blueOffset = -255;
			p1.alpha = 0.5;
		}
		else {
			p1.colorTransform.redOffset = 0;
			p1.colorTransform.greenOffset = 0;
			p1.colorTransform.blueOffset = 0;
			p1.alpha = 1;
		}

		if (waitingForPlayer2Skin) {
			p2.colorTransform.redOffset = -255;
			p2.colorTransform.greenOffset = -255;
			p2.colorTransform.blueOffset = -255;
			p2.alpha = 0.5;
		}

		player1Bg.scale.set(FlxMath.bound(player1Text.width, 300), player1Text.height + 60);
		player1Bg.updateHitbox();

		player2Bg.scale.set(FlxMath.bound(player2Text.width, 300), player2Text.height + 60);
		player2Bg.updateHitbox();

		player1Bg.x = 250 - player1Bg.width / 2;
		player2Bg.x = 700 - player2Bg.width / 2;

		switch (curSelected) {
			case 0:
				itemTip.text = " - SETTINGS - \nOpens server settings.\n\n(Keybind: SHIFT)";
			case 1:
				itemTip.text = " - CHAT - \nOpens chat.\n\n(Keybind: TAB)";
			case 2:
				itemTip.text = " - START GAME/READY - \nToggles your READY status.\n\nPlayers also need to have the\ncurrently selected mod installed.\n\nTwo players are required to start.";
			case 3:
				itemTip.text = " - ROOM CODE - \nUnique code of this room.\n\nACCEPT - Reveals the code and\ncopies it to your clipboard.\n\nCTRL + C - Copies the code without\nrevealing it on the screen.";
			case 4:
				itemTip.text = " - SELECT SONG - \nSelects the song.\n\n(Players with host permissions\ncan only do that)";
			case 5:
				itemTip.text = " - MOD - \nDownloads the currently selected mod\nif it isn't installed.\n\nAfter you install it\npress this button again!\n\nRIGHT CLICK - Open Mod Downloader";
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

	function returnPlayerText(player:Player) {
		return 
			player.name + "\n\n" +
			//player.title + "\n\n" + //completely unsure about that
            "Statistics\n" +
            "Points: " + player.points + "\n" +
            "Ping: " + player.ping + "ms" + "\n\n" +
			player.status + "\n" +
			(!player.isReady ? "NOT " : "") + "READY"
		;
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

	static public function getStaticPlayer(?isSelf:Bool = true) {
		if (instance != null)
			return instance.getPlayer(isSelf);
		return null;
	}

	public function getPlayer(?isSelf:Bool = true) {
		if (GameClient.isOwner) {
			return isSelf ? p1 : p2;
		}
		else {
			return isSelf ? p2 : p1;
		}
	}

	function playerAnim(anim:String, ?incoming:Bool = false) {
		getPlayer(!incoming)?.playAnim(anim, true);
		if (anim.endsWith('miss'))
			var sond = FlxG.sound.play(Paths.sound('missnote' + FlxG.random.int(1, 3)), 0.25);

		if (!incoming)
			GameClient.send("charPlay", [anim]);
	}

	function getSelfPlayer() {
		if (GameClient.isOwner)
			return GameClient.room.state.player1;
		else
			return GameClient.room.state.player2;
	}

	function danceLogic(char:Character, ?isBeat = false) {
		if (char != null && char.animation.curAnim != null) {
			if (isBeat) {
				if (curBeat % char.danceEveryNumBeats == 0 &&
					!char.animation.curAnim.name.startsWith('sing'))
					char.dance();
			} else {
				if (!(char.animation.curAnim.name.endsWith('miss') || char.isMissing) &&
					!(getPlayer() == char ? playerHold : oppHold) &&
					char.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * char.singDuration
					&& char.animation.curAnim.name.startsWith('sing') &&
					!(char.animation.curAnim.name.endsWith('miss') || char.isMissing))
					char.dance();
			}
		}
	}

	override function beatHit() {
		super.beatHit();

		#if (PSYCH_VER < "0.7")
		stage.beatHit(curBeat);
		#end

		danceLogic(p1, true);
		danceLogic(p2, true);
	}
}