package online.states;

import states.stages.Spooky;
import lumod.Lumod;
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
import online.backend.schema.Player;
import backend.Rating;
import backend.WeekData;
import backend.Song;
import haxe.crypto.Md5;
import states.FreeplayState;
import openfl.utils.Assets as OpenFlAssets;

@:build(lumod.LuaScriptClass.build())
@:publicFields
class RoomState extends MusicBeatState {
	//this shit is messy
	// var player1Text:FlxText;
	// var player1Bg:FlxSprite;
	// var player2Text:FlxText;
	// var player2Bg:FlxSprite;
	var playerBox1:ProfileBox;
	var playerBox2:ProfileBox;
	var isDuo:Bool = false;

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

	var dlSkinTxt:FlxText;

	var curSelected:Int = -1;
	var items:FlxTypedGroup<FlxSprite>;
	var settingsIconBg:FlxSprite;
	var settingsIcon:FlxSprite;
	var chatIconBg:FlxSprite;
	var chatIcon:FlxSprite;

	var itemTip:FlxText;
	var itemTipBg:FlxSprite;

	var stage:BaseStage;

	var cum:FlxCamera = new FlxCamera();
	var camHUD:FlxCamera = new FlxCamera();
	var groupHUD:FlxGroup;

	var leavePie:LeavePie;

	var revealTimer:FlxTimer;
	var playerHold(default, set):Bool = false;
	var oppHold:Bool = false;

	static var instance:RoomState = null;

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

		registerMessages();

		playMusic((GameClient.isOwner ? GameClient.room.state.player1 : GameClient.room.state.player2).hasSong);
		(GameClient.isOwner ? GameClient.room.state.player1 : GameClient.room.state.player2).listen("hasSong", (value:Bool, prev) -> {
			Waiter.put(() -> {
				playMusic(value);
			});
		});
	}

	function registerMessages() {
		GameClient.initStateListeners(this, this.registerMessages);

		GameClient.room.onMessage("checkChart", function(message) {
			Waiter.put(() -> {
				verifyDownloadMod(false, true);
			});
		});

		GameClient.room.onMessage("checkStage", function(message) {
			Waiter.put(() -> {
				checkStage();
			});
		});

		GameClient.room.state.player1.listen("skinName", (value, prev) -> {
			if (value == prev)
				return;
			Waiter.put(() -> {
				loadCharacter(true, true);
			});
		});
		GameClient.room.state.player2.listen("skinName", (value, prev) -> {
			if (value == prev)
				return;
			Waiter.put(() -> {
				loadCharacter(false, true);
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

		GameClient.room.onMessage("requestSkin", function(?msg:Dynamic) {
			Waiter.put(() -> {
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

		GameClient.room.state.gameplaySettings.onChange((o, n) -> {
			FreeplayState.updateFreeplayMusicPitch();
		});
	}

	override function destroy() {
		super.destroy();
		
		@:privateAccess
		if (GameClient.isConnected())
			GameClient.room.state.gameplaySettings._callbacks.clear();
	}

	var waitingForPlayer1Skin = false;
	var waitingForPlayer2Skin = false;

	var lastSwapped = false;

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

		if (online.backend.DateEvent.isHalloween) {
			Paths.setCurrentLevel("week2");
			stage = new Spooky();
			untyped stage.room = this;
		} 
		else {
			Paths.setCurrentLevel("week3");
			var pStage = new Philly();
			stage = pStage;
			pStage.phillyTrain.sound.volume = 0;

			if (!ClientPrefs.data.lowQuality) {
				pStage.bg.setGraphicSize(Std.int(pStage.bg.width * 1));
				pStage.bg.updateHitbox();

				pStage.bg.x -= 80;
				pStage.bg.y -= 50;
			}
			pStage.city.setGraphicSize(Std.int(pStage.city.width * 1.1));
			pStage.city.updateHitbox();
			pStage.phillyWindow.setGraphicSize(Std.int(pStage.phillyWindow.width * 1.1));
			pStage.phillyWindow.updateHitbox();

			pStage.city.x -= 80;
			pStage.phillyWindow.x -= 80;
			pStage.city.y -= 20;
			pStage.phillyWindow.y -= 20;
		}
		
		stage.cameras = [cum];
		add(stage);

		cum.scroll.set(100, 130);
		cum.zoom = 0.9;

		add(p1Layer);
		add(p2Layer);

		loadCharacter(true, true);
		loadCharacter(false, true);

		// POST STAGE

		// player1Text = new FlxText(0, 100, 0, "PLAYER 1");
		// player1Text.setFormat("VCR OSD Mono", 25, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);

		// player1Bg = new FlxSprite(-1000);
		// player1Bg.makeGraphic(1, 1, 0xA4000000);
		// player1Bg.updateHitbox();
		// player1Bg.y = player1Text.y - 30;
		// groupHUD.add(player1Bg);
		// groupHUD.add(player1Text);

		// player2Text = new FlxText(0, 100, 0, "PLAYER 2");
		// player2Text.setFormat("VCR OSD Mono", 25, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);

		// player2Bg = new FlxSprite(-1000);
		// player2Bg.makeGraphic(1, 1, 0xA4000000);
		// player2Bg.updateHitbox();
		// player2Bg.y = player2Text.y - 30;
		// groupHUD.add(player2Bg);
		// groupHUD.add(player2Text);

		for (i in 1...3) {
			var box = new ProfileBox(null, false, 50, 2);
			if (i == 1)
				playerBox1 = box;
			else
				playerBox2 = box;
			box.autoUpdateThings = false;
			box.autoCardHeight = true;
			box.text.text = "PLAYER" + i;
			box.setPosition(0, 70);
			box.camera = camHUD;
			groupHUD.add(box);
		}

		chatBox = new ChatBox(camHUD, (cmd, args) -> {
			switch (cmd) {
				case "help":
					ChatBox.addMessage("> Room Commands: /pa, /results, /restage");
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
					FlxG.switchState(() -> new ResultsState());
					return true;
				case "restage":
					checkStage();
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

		dlSkinTxt = new FlxText(0, 0, 0, "Download");
		dlSkinTxt.setFormat("VCR OSD Mono", 18, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		dlSkinTxt.visible = false;
		groupHUD.add(dlSkinTxt);

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

		verifyDownloadMod(false, true);
		checkStage();

		if (stage != null)
			stage.createPost();

		GameClient.send("status", "In the Lobby");
	}

	var hasStage:Bool = false;
	function checkStage() {
		if (GameClient.room.state.stageName == "") {
			hasStage = true;
			return;
		}

		if (FileSystem.exists(Paths.mods('${GameClient.room.state.stageMod}/stages/${GameClient.room.state.stageName}.json')) ||
			OpenFlAssets.exists(Paths.getPath('stages/${GameClient.room.state.stageName}.json'), TEXT)) {
			hasStage = true;
			return;
		}

		if (GameClient.room.state.stageURL != null) {
			hasStage = false;

			OnlineMods.downloadMod(GameClient.room.state.stageURL, false, (_) -> {
				if (destroyed)
					return;

				checkStage();
			});
		}
	}

	function loadCharacter(isP1:Bool, ?enableDownload:Bool = false, ?manualDownload:Bool = false) {
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
					p1 = new Character(0, 0, GameClient.room.state.player1.skinName + (GameClient.room.state.swagSides ? "-player" : ''), GameClient.room.state.swagSides);
			}
			else if (enableDownload && GameClient.room.state.player1.skinURL != null) {
				waitingForPlayer1Skin = true;
				OnlineMods.downloadMod(GameClient.room.state.player1.skinURL, manualDownload, (_) -> {
					if (destroyed)
						return;

					loadCharacter(isP1, false);
					waitingForPlayer1Skin = false;
				});
			}

			if (p1 == null)
				p1 = new Character(0, 0, "default" + (GameClient.room.state.swagSides ? "-player" : ''), GameClient.room.state.swagSides);

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
					p2 = new Character(0, 0, GameClient.room.state.player2.skinName + (GameClient.room.state.swagSides ? '' : "-player"), !GameClient.room.state.swagSides);
			}
			else if (enableDownload && GameClient.room.state.player2.skinURL != null) {
				waitingForPlayer2Skin = true;
				OnlineMods.downloadMod(GameClient.room.state.player2.skinURL, manualDownload, (_) -> {
					if (destroyed)
						return;

					loadCharacter(isP1, false);
					waitingForPlayer2Skin = false;
				});
			}

			if (p2 == null)
				p2 = new Character(/*770*/ 0, 0, "default" + (GameClient.room.state.swagSides ? '' : "-player"), !GameClient.room.state.swagSides);

			p2Layer.add(p2);
		}

		positionCharacters();
		
		Mods.currentModDirectory = oldModDir;
	}

	var rightSide:Character;
	var leftSide:Character;
	var rightSideBox:ProfileBox;
	var leftSideBox:ProfileBox;

	function positionCharacters() {
		rightSide = GameClient.room.state.swagSides ? p1 : p2;
		leftSide = GameClient.room.state.swagSides ? p2 : p1;
		rightSideBox = GameClient.room.state.swagSides ? playerBox1 : playerBox2;
		leftSideBox = GameClient.room.state.swagSides ? playerBox2 : playerBox1;

		if (rightSide != null) {
			rightSide.x = 600 + rightSide.positionArray[0];
			rightSide.y = 120 + rightSide.positionArray[1];
		}

		if (leftSide != null) {
			leftSide.x = 100 + leftSide.positionArray[0];
			leftSide.y = 120 + leftSide.positionArray[1];
		}

		if (leftSideBox != null) {
			leftSideBox.x = 250 - leftSideBox.width / 2;
		}

		if (rightSideBox != null) {
			rightSideBox.x = 700 - leftSideBox.width / 2;
		}
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
	var lastFocused = false;
    override function update(elapsed:Float) {
		if (FlxG.keys.justPressed.F11) {
			GameClient.reconnect();
		}

		if (FlxG.keys.justPressed.F12) {
			trace('reloading lumod');
			Lumod.cache.scripts.clear();
			lmLoad();
		}
		
		if (!GameClient.isConnected())
			return;

		if (lastFocused != (chatBox.focused && chatBox.typeText.text.length > 0)) {
			if (!lastFocused) // is now typing
				GameClient.send("status", "Typing...");
			else
				GameClient.send("status", "In the Lobby");
		}

		lastFocused = chatBox.focused && chatBox.typeText.text.length > 0;

		if (lastSwapped != GameClient.room.state.swagSides) {
			loadCharacter(true);
			loadCharacter(false);
		}

		lastSwapped = GameClient.room.state.swagSides;
		
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
				if (controls.TAUNT) {
					var altSuffix = FlxG.keys.pressed.SHIFT ? '-alt' : '';
					playerAnim('taunt' + altSuffix);
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
				if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.C) {
					Clipboard.text = GameClient.getRoomSecret(true);
					Alert.alert("Room code copied!");
				}

				if (FlxG.keys.justPressed.SHIFT) {
					openSubState(new RoomSettingsSubstate());
				}
			}
			
			danceLogic(p1);
			danceLogic(p2);
			
			if ((!FlxG.keys.pressed.ALT && controls.ACCEPT) || FlxG.mouse.justPressed) {
				switch (curSelected) {
					case 0:
						openSubState(new RoomSettingsSubstate());
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
								Alert.alert("Caught an exception!", ShitUtil.readableError(exc));
								if (optionShake != null)
									optionShake.cancel();
								optionShake = FlxTween.shake(playIcon, 0.05, 0.3, FlxAxes.X);
							}
						}
						else if (selfPlayer.hasSong) {
							checkStage();

							if (!hasStage) {
								Alert.alert("You don't have the current stage!");
							}
							else {
								GameClient.send("startGame");
							}
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
						if (verifyDownloadMod(true)) {
							GameClient.clearOnMessage();
							FlxG.switchState(() -> new DownloaderState());
						}
				}
			}
			else if (FlxG.mouse.justPressedRight) {
				if (curSelected == 5)
					FlxG.switchState(() -> new DownloaderState());
			}
		}

		if (waitingForPlayer1Skin && FlxG.mouse.justPressed && FlxG.mouse.overlaps(p1)) {
			loadCharacter(true, true, true);
		}
		else if (waitingForPlayer2Skin && FlxG.mouse.justPressed && FlxG.mouse.overlaps(p2)) {
			loadCharacter(false, true, true);
		}

        super.update(elapsed);

		updateTexts();

		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;
    }
	
	function verifyDownloadMod(manual:Bool, ?ignoreAlert:Bool = false) {
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
				OnlineMods.downloadMod(GameClient.room.state.modURL, manual, (mod) -> {
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

		var selfPlayer:Player = getSelfPlayer();
		
		var daModName = GameClient.room.state.modDir ?? "";
		if (daModName.length > 30) {
			daModName = daModName.substr(0, 30) + "...";
		}

		if (daModName == "" || GameClient.room.state.song == "") {
			verifyMod.text = "No chosen mod.";
		}
		else if (selfPlayer.hasSong) {
			verifyMod.text = "Mod: " + daModName;
		}
		else {
			if (GameClient.room.state.modURL == null || GameClient.room.state.modURL == "")
				verifyMod.text = "No mod named: " + daModName + " (Unknown; Host didn't specify mod's URL)";
			else 
				verifyMod.text = "No mod named: " + daModName + " (Download/Verify it here!)";
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

		setPlayerText(playerBox1, GameClient.room.state.player1, waitingForPlayer1Skin);

		if (GameClient.room.state.player2 != null && GameClient.room.state.player2.name != "") {
			p2.colorTransform.redOffset = 0;
			p2.colorTransform.greenOffset = 0;
			p2.colorTransform.blueOffset = 0;
			p2.alpha = 1;
			dlSkinTxt.visible = waitingForPlayer2Skin;
			if (waitingForPlayer2Skin)
				dlSkinTxt.setPosition(p2.x + p2.width / 2 - dlSkinTxt.width / 2, p2.y + p2.height / 2 - dlSkinTxt.height / 2);
			setPlayerText(playerBox2, GameClient.room.state.player2, waitingForPlayer2Skin);
        }
        else {
			if (p2.curCharacter != "default-player")
				loadCharacter(false);
			playerBox2.text.clearFormats();
			playerBox2.text.text = "WAITING FOR\nOPPONENT";
			playerBox2.desc.text = "";
			if (playerBox2 != null && playerBox2.user != null) {
				playerBox2.cardHeight = 50;
				playerBox2.updateData(null, false);
			}
			playerBox2.updatePositions();
			p2.colorTransform.redOffset = -255;
			p2.colorTransform.greenOffset = -255;
			p2.colorTransform.blueOffset = -255;
			p2.alpha = 0.5;
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

		positionCharacters();

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

	var yellowMarker:FlxTextFormatMarkerPair;
	var pingMarker:FlxTextFormatMarkerPair;

	function setPlayerText(box:ProfileBox, player:Player, noSkin:Bool) {
		if (yellowMarker == null)
			yellowMarker = new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.YELLOW), "<y>");
		if (pingMarker == null)
			pingMarker = new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.GREEN), "<p>");

		@:privateAccess
		pingMarker.format.format.color = FlxColor.interpolate(FlxColor.fromString("#00ff00"), FlxColor.fromString("#ff0000"), player.ping / 400);

		yellowMarker = new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.YELLOW), "<y>");

		if (box.user != player.name) {
			box.updateData(player.name, player.verified);
		}

		box.text.applyMarkup(
			(player.verified ? '<y>${player.name}<y>' : player.name)
		, [yellowMarker]);

		box.desc.applyMarkup(
            "Points: " + player.points + "\n" +
			(player.verified && box.profileData != null ? 
				"Rank: " + ShitUtil.toOrdinalNumber(box.profileData.rank) + "\n" +
				"Avg. Accuracy: " + FlxMath.roundDecimal((box.profileData.avgAccuracy * 100), 2) + "%\n"
			 : "") +
			"Ping: <p>" + player.ping + "ms<p>\n\n" +
			player.status + "\n" +
			(!player.isReady ? "NOT " : "") + "READY" +
			(noSkin ? "\n(Unloaded Skin)" : "")
		, [pingMarker]);

		box.updatePositions();
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
		FreeplayState.destroyFreeplayVocals();
		if (value) {
			Mods.currentModDirectory = GameClient.room.state.modDir;
			Difficulty.list = CoolUtil.asta(GameClient.room.state.diffList);
			PlayState.SONG = Song.loadFromJson(GameClient.room.state.song, GameClient.room.state.folder);

			var diff = Difficulty.getString(GameClient.room.state.diff);
			var trackSuffix = diff == "Erect" || diff == "Nightmare" ? "-erect" : "";

			FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song, trackSuffix), 0.5);
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
		danceLogic(p1, true);
		danceLogic(p2, true);
		
		super.beatHit();
	}
}