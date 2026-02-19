package online.states;

import states.stages.objects.PhillyTrain;
import backend.StageData;
import flixel.util.FlxStringUtil;
import states.stages.Spooky;
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
import states.ModsMenuState;
import openfl.utils.Assets as OpenFlAssets;
import openfl.Lib;

#if lumod
@:build(lumod.LuaScriptClass.build())
#end
@:publicFields
/*#if interpret @:nullSafety(Off) #end*/
class RoomState extends MusicBeatState /*#if interpret implements interpret.Interpretable #end */ {
	var verifyMod:FlxText;
	var verifyModBg:FlxSprite;
	var roomCodeBg:FlxSprite;
	var roomCode:FlxText;
	var songName:FlxText;
	var songNameBg:FlxSprite;
	var playIcon:FlxSprite;
	var playIconBg:FlxSprite;
	var chatBox:ChatBox;

	var characters:Map<String, LobbyCharacter> = new Map();
	var charactersLayer:FlxTypedGroup<LobbyCharacter> = new FlxTypedGroup<LobbyCharacter>();

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

	var funnyMode(default, set):Int = 1;
	function set_funnyMode(v) {
		funnyMode = v;
		switch (funnyMode) {
			case 0:
				targetCamZoom = 0.65;
				targetCamX = 200;
				targetCamY = 120;
			case 1:
				targetCamZoom = 0.57;
				targetCamX = 150;
				targetCamY = 120;
			case 2:
				targetCamZoom = 0.45;
				targetCamX = 50;
				targetCamY = 180;
			case 3:
				targetCamZoom = 0.34;
				targetCamX = 50;
				targetCamY = 250;
		}
		startCamTween();
		return funnyMode;
	}

	var targetCamTween:FlxTween;
	var targetCamScrollTween:FlxTween;
	var targetCamZoom:Float = 0.65;
	var targetCamX:Float = 200;
	var targetCamY:Float = 120;

	function startCamTween() {
		if (targetCamTween != null)
			targetCamTween.cancel();
		targetCamTween = FlxTween.tween(cum, {zoom: targetCamZoom}, 1, {ease: FlxEase.quadOut});

		if (targetCamScrollTween != null)
			targetCamScrollTween.cancel();
		targetCamScrollTween = FlxTween.tween(cum.scroll, {x: targetCamX, y: targetCamY}, 1, {ease: FlxEase.quadOut});
	}

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
	}

	function registerMessages() {
		if (GameClient.getPlayerSelf() == null) {
			GameClient.leaveRoom('Self not in the room.');
			return;
		}

		GameClient.initStateListeners(this, this.registerMessages);

		if (!GameClient.isConnected())
			return;

		playMusic(GameClient.getPlayerSelf().hasSong);
		GameClient.callbacks.listen(GameClient.getPlayerSelf(), "hasSong", (value:Bool, prev) -> {
			Waiter.putPersist(() -> {
				playMusic(value);
			});
		});

		GameClient.room.onMessage("checkChart", function(message) {
			Waiter.putPersist(() -> {
				verifyDownloadMod(false, true);
			});
		});

		GameClient.room.onMessage("checkStage", function(message) {
			Waiter.put(() -> {
				checkStage();
			});
		});

		function listenUpdateTextOnField(player:Player, field:String) {
			GameClient.callbacks.listen(player, field, (value, prev) -> {
				if (value == prev)
					return;
				Waiter.put(() -> {
					updateTexts();
				});
			});
		}
		function listenUpdate(sid:String, player:Player) {
			listenUpdateTextOnField(player, 'ping');
			listenUpdateTextOnField(player, 'status');
			listenUpdateTextOnField(player, 'name');
			GameClient.callbacks.listen(player, "skin", (value, prev) -> {
				if (value == prev)
					return;
				Waiter.put(() -> {
					characters.get(sid).loadCharacter();
					updateCharacters();
				});
			});
			GameClient.callbacks.listen(player, "isReady", (value, prev) -> {
				Waiter.put(() -> {
					if (value) {
						var sond = FlxG.sound.play(Paths.sound('confirmMenu'), 0.5);
						sond.pitch = 1.5;
					}
					else {
						var sond = FlxG.sound.play(Paths.sound('cancelMenu'));
						sond.pitch = 1.5;
					}
				});
			});
			GameClient.callbacks.listen(player, "noteSkin", (value, prev) -> {
				if (value == prev)
					return;
				Waiter.put(() -> {
					checkNoteSkin(player);
				});
			});
			GameClient.callbacks.listen(player, "bfSide", (value, prev) -> {
				if (value == prev)
					return;

				Waiter.put(() -> {
					updateCharacters();
				});
			});
			GameClient.callbacks.listen(player, "ox", (value, prev) -> {
				if (value == prev)
					return;

				Waiter.put(() -> {
					updateCharacters();
				});
			});
		}

		function initPlayer(sid:String, player:Player) {
			if (!characters.exists(sid)) {
				var char = new LobbyCharacter(player);
				characters.set(sid, char);
				// HOW THE FUCK DOES THIS EVEN HAPPEN??!!??!
				if (charactersLayer.members == null)
					charactersLayer = new FlxTypedGroup<LobbyCharacter>();
				charactersLayer.add(char);
			}

			listenUpdate(sid, player);
			checkNoteSkin(player);
			updateCharacters();
		}

		//cool colyseus
		// for (sid => player in GameClient.room.state.players) {
		// 	trace('for: ' + sid + " " + player);
		// 	initPlayer(sid, player);
		// }
		GameClient.callbacks.onAdd("players", (player, sid) -> {
			Waiter.put(() -> {
				initPlayer(sid, player);
			});
		});

		GameClient.callbacks.onRemove("players", (player, sid) -> {
			Waiter.put(() -> {
				var character = characters.get(sid);
				charactersLayer.remove(character, true);
				character.destroy();
				characters.remove(sid);
				updateCharacters();
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

		GameClient.room.onMessage("charPlay", function(_message:Array<Dynamic>) {
			var sid:String = _message[0];
			var message:Array<Dynamic> = _message[1];

			Waiter.put(() -> {
				if (message == null || message[0] == null)
					return;

				playerAnim(message[0], sid);
			});
		});

		GameClient.callbacks.onChange(GameClient.room.state.gameplaySettings, () -> {
			Waiter.putPersist(() -> {
				FreeplayState.updateFreeplayMusicPitch();
				//FlxG.animationTimeScale = ClientPrefs.getGameplaySetting('songspeed');
			});
		});

	}

	override function destroy() {
		super.destroy();
		
		try {
			GameClient.clearCallbacks(GameClient.room.state.gameplaySettings);
		} catch (exc) {
			trace(exc);
		}
	}

	var lastSwapped = false;

	final TEXT_BG_COLOR = 0x8A000000;

	override function create() {
		super.create();

		if (!Lib.application.window.resizable)
			Lib.application.window.resizable = true;

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Lobby", null, null, false);
		#end

		WeekData.reloadWeekFiles(false);
		for (i in 0...WeekData.weeksList.length) {
			WeekData.setDirectoryFromWeek(WeekData.weeksLoaded.get(WeekData.weeksList[i]));
		}
		Mods.loadTopMod();
		WeekData.setDirectoryFromWeek();

		FlxG.animationTimeScale = 1;

		FlxG.cameras.reset(cum);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.setDefaultDrawTarget(cum, true);
		camHUD.bgColor.alpha = 0;

		groupHUD = new FlxGroup();
		groupHUD.cameras = [camHUD];

		// STAGE

		stage = new LobbyStage();
		stage.cameras = [cum];
		add(stage);

		// var debugPoser = new online.objects.DebugPosHelper();
		// add(debugPoser);

		cum.scroll.set(200, 130);
		cum.zoom = 0.5;

		add(charactersLayer);

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

		chatBox = new ChatBox(camHUD, (cmd, args) -> {
			switch (cmd) {
				case "pa":
					if (args[0] != null && args[0].trim() != "")
						playerAnim(args[0]);
					else {
						var anims = "";
						for (anim in @:privateAccess getCharacterSelf().animation._animations)
							anims += '"${anim.name}" ';
						ChatBox.addMessage("> Please enter the animation you want to play!\nAvailable animations: " + anims);
					}
					return true;
				case "results":
					FlxG.switchState(() -> new ResultsState());
					return true;
				case "restage":
					checkStage();
					return true;
				case "help":
					ChatBox.addMessage("> Room Commands: /pa <anim>, /results, /restage");
			}
			return false;
		});
		groupHUD.add(chatBox);

		items = new FlxTypedGroup<FlxSprite>();

		settingsIconBg = new FlxSprite();
		settingsIconBg.makeGraphic(100, 100, TEXT_BG_COLOR);
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
		chatIconBg.makeGraphic(100, 100, TEXT_BG_COLOR);
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
		playIconBg.makeGraphic(100, 100, TEXT_BG_COLOR);
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
		roomCodeBg.makeGraphic(1, 1, TEXT_BG_COLOR);
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
		songNameBg.makeGraphic(1, 1, TEXT_BG_COLOR);
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
		verifyModBg.makeGraphic(1, 1, TEXT_BG_COLOR);
		verifyModBg.updateHitbox();
		verifyModBg.y = verifyMod.y;
		verifyModBg.x = verifyMod.x;
		verifyModBg.scale.set(verifyMod.width, verifyMod.height);
		verifyModBg.updateHitbox();
		groupHUD.add(verifyModBg);
		items.add(verifyMod);

		groupHUD.add(items);

		itemTipBg = new FlxSprite(-1000);
		itemTipBg.makeGraphic(1, 1, TEXT_BG_COLOR);
		itemTipBg.updateHitbox();
		groupHUD.add(itemTipBg);

		itemTip = new FlxText(0, 0, 0, "Placeholder");
		itemTip.setFormat("VCR OSD Mono", 18, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		groupHUD.add(itemTip);

		groupHUD.add(leavePie = new LeavePie());

		add(groupHUD);
		
		updateTexts(true);

		FlxG.mouse.visible = true;
		FlxG.autoPause = false;

		verifyDownloadMod(false, true);
		checkStage();

		if (stage != null)
			stage.createPost();

		GameClient.send("status", "In the Lobby");

		registerMessages();
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

	function checkNoteSkin(player:Player, ?manualDownload:Bool = false) {
		if (!FileSystem.exists(Paths.mods(player.noteSkinMod)) && player.noteSkinURL != null) {
			OnlineMods.downloadMod(player.noteSkinURL, manualDownload, function(_) {
				Mods.updatedOnState = false;
				Mods.parseList();
				Mods.pushGlobalMods();
			});

			if(!manualDownload && ClientPrefs.data.disableAutoDownloads) {
				chatBox.addNoteSkinDownloadMessage(function() {
					checkNoteSkin(player, true);
				});
			}
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
	var updateTimer = 1.0;

    override function update(elapsed:Float) {
		super.update(elapsed);

		if (FlxG.keys.justPressed.F11) {
			GameClient.reconnect();
		}

		#if lumod
		if (FlxG.keys.justPressed.F12) {
			trace('reloading lumod');
			Lumod.cache.scripts.clear();
			lmLoad();
		}
		#end
		
		if (GameClient.getPlayerSelf() == null) {
			return;
		}

		if (lastFocused != (chatBox.focused && chatBox.typeText.text.length > 0)) {
			if (!lastFocused) // is now typing
				GameClient.send("status", "Typing...");
			else
				GameClient.send("status", "In the Lobby");
		}

		lastFocused = chatBox.focused && chatBox.typeText.text.length > 0;

		updateTimer -= elapsed;
		if (updateTimer <= 0) {
			updateTimer = 5.0;

			var sumReceivedBytes = 0.0;
			var sumContentLength = 0.0;
			for (down in ModDownloader.downloaders) {
				if (down?.client != null && down.status == READING_BODY) {
					sumReceivedBytes += down.client.receivedBytes;
					sumContentLength += down.client.contentLength;
				}
			}

			if (sumContentLength > 0) {
				GameClient.send("status", 'Downloading (${Math.floor(sumReceivedBytes / sumContentLength * 100)}%)');
			}
			else {
				if (lastFocused)
					GameClient.send("status", "Typing...");
				else
					GameClient.send("status", "In the Lobby");
			}
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
					if (GameClient.getPlayerSelf().hasSong) {
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
		playIcon.alpha = GameClient.getPlayerSelf().hasSong ? 1.0 : 0.5;

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
			
			if ((!FlxG.keys.pressed.ALT && controls.ACCEPT) || FlxG.mouse.justPressed) {
				switch (curSelected) {
					case 0:
						openSubState(new RoomSettingsSubstate());
					case 1:
						chatBox.focused = true;
					case 2:
						var selfPlayer:Player = GameClient.getPlayerSelf();

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
						if (GameClient.hasPerms() || GameClient.room.state.allPlayersChoose) {
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
							FlxG.switchState(() -> new DownloaderState());
						}
				}
			}
			else if (FlxG.mouse.justPressedRight) {
				if (curSelected == 5) {
					FlxG.switchState(() -> new DownloaderState());
				}
			}
		}

		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;
    }
	
	function verifyDownloadMod(manual:Bool, ?ignoreAlert:Bool = false) {
		try {
			trace(GameClient.getPlayerSelf().hasSong, GameClient.room.state.song, GameClient.room.state.modDir);
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
			if (GameClient.getPlayerSelf().hasSong) {
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

			if (Mods.getModDirectories().contains(GameClient.room.state.modDir) || GameClient.room.state.modDir == null || GameClient.room.state.modDir == "") {
				Mods.currentModDirectory = GameClient.room.state.modDir;
				try {
					GameClient.send("verifyChart", Md5.encode(Song.loadRawSong(GameClient.room.state.song, GameClient.room.state.folder)));
					return false;
				}
				catch (exc) {
				}
			}

			if (GameClient.room.state.modDir != null && GameClient.room.state.modURL != null && GameClient.room.state.modURL != "") {
				var daModURL = GameClient.room.state.modURL;
				OnlineMods.downloadMod(daModURL, manual, (mod) -> {
					if (GameClient.isConnected())
						GameClient.send("notifyInstall", daModURL);

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

	var _textsInit = false;
    function updateTexts(?init:Bool = false) {
		if (init)
			_textsInit = true;

		if (destroyed || GameClient.room == null || !_textsInit)
			return;

		var selfPlayer:Player = GameClient.getPlayerSelf();
		if (selfPlayer == null)
			return;
		
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

		updateCharacters();

		switch (curSelected) {
			case 0:
				itemTip.text = " - SETTINGS - \nOpens server settings.\n\n(Keybind: SHIFT)";
			case 1:
				itemTip.text = " - CHAT - \nOpens chat.\n\n(Keybind: TAB)";
			case 2:
				itemTip.text = " - START GAME/READY - \nToggles your READY status.\n\nPlayers also need to have the\ncurrently selected mod installed.\n\n(Both sides can only\nhave up to 2 players).";
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

	// @interpret
	function updateCharacters() {
		if (destroyed)
			return;

		// var sides = [0, 0];
		var maxOffset = 0.;
		for (character in characters) {
			character.character.ox = character.player.ox;
			character.repos();
			character.updatePlayerText();

			maxOffset = Math.max(maxOffset, character.character.ox);

			// sides[character.player.bfSide ? 1 : 0]++;
		}

		charactersLayer.members.sort(sortByOX);

		funnyMode = Std.int(maxOffset);

		//cum.zoom = 0.9 - (maxOffset * 0.1);
	}
	
	function sortByOX(a:LobbyCharacter, b:LobbyCharacter) {
		if (a == null || b == null) return 0;
		return b.character.ox - a.character.ox;
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

	static function playMusic(value:Bool) {
		FreeplayState.destroyFreeplayVocals();
		if (value) {
			Mods.currentModDirectory = GameClient.room.state.modDir;
			Difficulty.list = CoolUtil.asta(GameClient.room.state.diffList);
			PlayState.loadSong(GameClient.room.state.song, GameClient.room.state.folder);

			var diff = Difficulty.getString(GameClient.room.state.diff);
			var trackSuffix = diff == "Erect" || diff == "Nightmare" ? "-erect" : "";

			FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song, trackSuffix), 0.5);
			Conductor.mapBPMChanges(PlayState.SONG);
			Conductor.bpm = PlayState.SONG.bpm;
		}
		else {
			states.TitleState.playFreakyMusic(0.5);
			Conductor.bpm = 102;
		}
	}

	public function getCharacterSelf() {
		return characters.get(GameClient.room.sessionId).character;
	}

	function playerAnim(anim:String, ?sid:String) {
		if (destroyed)
			return;
		
		var character = characters.get(sid ?? GameClient.room.sessionId);
		character.character.playAnim(anim, true);
		if (anim.endsWith('miss'))
			var sond = FlxG.sound.play(Paths.sound('missnote' + FlxG.random.int(1, 3)), 0.25);

		if (sid == null) {
			GameClient.send("charPlay", [anim]);
		}
	}

	override function beatHit() {
		updateTexts();

		for (sid => character in characters) {
			character.danceLogic(curBeat);
		}
		
		super.beatHit();
	}
}

#if lumod
@:build(lumod.LuaScriptClass.build())
#end
class LobbyCharacter extends FlxTypedGroup<FlxSprite> {
	public var player:Player;
	public var character:Character;
	public var profileBox:ProfileBox;
	public var noSkin:Bool = false;
	var dlSkinTxt:FlxText;
	public var profileBoxXOffset:Float = 400;
	public var profileBoxXOffsetP2:Float = 100;
	public var profileBoxYOffset:Float = 50;
	public var xBoxStepOffset:Float = 450;
	public var yBoxStepOffset:Float = 150;
	public var xCharStepOffset:Float = 400;
	public var charOffsetX:Float = 0;

	public function new(player:Player, ?camHUD:FlxCamera, ?isVerified:Bool = false, ?sizeAdd:Int = 12) {
		super();

		this.player = player;
	
		profileBox = new ProfileBox(isVerified ? player.name : null, isVerified, 50, sizeAdd);
		profileBox.autoUpdateThings = false;
		profileBox.autoCardHeight = true;
		profileBox.avatarMaxSize = 100;
		profileBox.text.text = player.name;
		profileBox.setPosition(0, profileBoxYOffset);
		//if (camHUD != null)
		//	profileBox.camera = camHUD;
		add(profileBox);

		dlSkinTxt = new FlxText(0, 0, 0, "DOWNLOAD SKIN");
		dlSkinTxt.setFormat("VCR OSD Mono", 18, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);

		loadCharacter();
	}

	var _prevNoSkin:Bool = false;
	var _changedNoSkin:Bool = false;

	override function update(elapsed:Float) {
		super.update(elapsed);

		_changedNoSkin = _prevNoSkin != noSkin;
		_prevNoSkin = noSkin;

		if (noSkin) {
			if (_changedNoSkin) {
				character.colorTransform.redOffset = -255;
				character.colorTransform.greenOffset = -255;
				character.colorTransform.blueOffset = -255;
				character.alpha = 0.5;
				add(dlSkinTxt);
			}

			dlSkinTxt.setPosition(
				character.x + character.width / 2 - dlSkinTxt.width / 2, 
				character.y + character.height / 2 - dlSkinTxt.height / 2
			);

			if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(character, character.camera))
				loadCharacter(true, true);
		}
		else if (_changedNoSkin) {
			character.colorTransform.redOffset = 0;
			character.colorTransform.greenOffset = 0;
			character.colorTransform.blueOffset = 0;
			character.alpha = 1;
			remove(dlSkinTxt);
		}

		danceLogic();
	}

	var yellowMarker:FlxTextFormatMarkerPair;
	var pingMarker:FlxTextFormatMarkerPair;

	public function updatePlayerText() {
		if (yellowMarker == null)
			yellowMarker = new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.YELLOW), "<y>");
		if (pingMarker == null)
			pingMarker = new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.GREEN), "<p>");

		@:privateAccess
		pingMarker.format.format.color = FlxColor.interpolate(FlxColor.fromString("#00ff00"), FlxColor.fromString("#ff0000"), player.ping / 400);

		if (profileBox.user != player.name) {
			profileBox.updateData(player.name, player.verified);
		}

		profileBox.text.clearFormats();

		profileBox.text.applyMarkup(
		(player.verified ? '<y>${player.name + (profileBox?.profileData?.club != null ? ' [${profileBox.profileData.club}]' : '')}<y>' : player.name)
		, [yellowMarker]);

		profileBox.desc.applyMarkup(
			(player.verified && profileBox.profileData != null ? 
				FlxStringUtil.formatMoney(player.points, false) + 'FP (' + ShitUtil.toOrdinalNumber(profileBox.profileData.rank) + ")\n"
			 : "") +
			"Ping: <p>" + player.ping + "ms<p>\n\n" +
			player.status + "\n" +
			(!player.isReady ? "NOT " : "") + "READY" +
			(noSkin ? "\n(Unloaded Skin)" : "")
		, [pingMarker]);

		profileBox.updatePositions();
	}

	public function danceLogic(?curBeat:Null<Int>) {
		if (character != null && character.animation.curAnim != null) {
			if (curBeat != null) {
				if (curBeat % character.danceEveryNumBeats == 0 && !character.animation.curAnim.name.startsWith('sing'))
					character.dance();
			}
			else {
				if (!(character.animation.curAnim.name.endsWith('miss') || character.isMissing)
						&& !player.noteHold
						&& character.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * character.singDuration
						&& character.animation.curAnim.name.startsWith('sing')
						&& !(character.animation.curAnim.name.endsWith('miss') || character.isMissing))
					character.dance();
			}
		}
	}

	public function loadCharacter(?enableDownload:Bool = true, ?manualDownload:Bool = false) {
		if (character != null) {
			remove(character);
			character.destroy();
			character = null;
		}

		if (player.skin.length > 0) {
			online.util.ShitUtil.tempSwitchMod(player.skin.items[3], () -> {
				character = new Character(0, 0, player.skin.items[0] + player.skin.items[player.bfSide ? 2 : 1], player.bfSide);
			});

			if (character?.loadFailed && enableDownload && player.skinURL != null) {
				noSkin = true;
				OnlineMods.downloadMod(player.skinURL, manualDownload, (_) -> {
					if (RoomState.instance == null || RoomState.instance.destroyed)
						return;

					loadCharacter(false);
				});
			}
		}

		noSkin = character == null || character.loadFailed;

		if (noSkin) {
			character = new Character(0, 0, "bf" + (player.bfSide ? "" : '-opponent'), player.bfSide);
		}

		character.noHoldBullshit = true;
		add(character);

		remove(profileBox, true);
		insert(members.indexOf(character) + 1, profileBox);

		_bfSide = player.bfSide;

		repos();
	}

	var _bfSide = false;

	// var _charCamPos = FlxPoint.get();

	public function repos() {
		if (_bfSide != player.bfSide) {
			loadCharacter(false);
		}
		_bfSide = player.bfSide;

		// left side
		if (!player.bfSide) {
			character.x = charOffsetX + 200 + character.positionArray[0] - character.ox * xCharStepOffset;
			character.y = 120 + character.positionArray[1];
			profileBox.x = profileBoxXOffset - profileBox.width / 2 - character.ox * xBoxStepOffset;
		}
		// right side
		else {
			character.x = charOffsetX + 700 + character.positionArray[0] + character.ox * xCharStepOffset;
			character.y = 120 + character.positionArray[1];
			profileBox.x = profileBoxXOffsetP2 + FlxG.width - profileBoxXOffset - profileBox.width / 2 + character.ox * xBoxStepOffset;
		}
		// character.getScreenPosition(_charCamPos, profileBox.camera);
		// profileBox.x = _charCamPos.x + character.width / 2 * character.camera.zoom - profileBox.width / 2; 
		// profileBox.y = profileBoxYOffset + character.ox * yBoxStepOffset;
		// profileBox.x = character.x + character.width / 2 - profileBox.width / 2;
		profileBox.y = 100;
	}
}

class LobbyStage extends BaseStage {
	var sprites:Map<String, FlxSprite> = new Map();

	var phillyTrain:PhillyTrain;
	var phillyWindow:FlxSprite;
	var curLight:Int = 0;
	var phillyLightsColors:Array<FlxColor> = [0xFF31A2FD, 0xFF31FD8C, 0xFFFB33F5, 0xFFFD4531, 0xFFFBA633];

	override function create() {
		var stageData = StageData.getStageFile("lobby");
		if (stageData == null) { // Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = StageData.dummy();
		}
		Paths.setCurrentLevel(stageData.directory);
		var list = StageData.addObjectsToState(stageData.objects, null, null, null, this, ['train']);
		for (key => spr in list)
			if (!StageData.reservedNames.contains(key))
				sprites.set(key, spr);

		for (num => data in stageData.objects) {
			if (data.name == 'train') {
				// phillyTrain = new PhillyTrain(data.x, data.y);
				// phillyTrain.sound.volume = 0.5;
				// insert(members.indexOf(sprites.get('street')), phillyTrain);
			}
		}

		phillyWindow = sprites.get('window');
		if (phillyWindow != null) {
			phillyWindow.alpha = 0;
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (phillyWindow != null) {
			phillyWindow.alpha -= (Conductor.crochet / 1000) * FlxG.elapsed * 1.5;
		}
	}

	override function beatHit() {
		if (phillyTrain != null)
			phillyTrain.beatHit(curBeat);

		if (phillyWindow != null) {
			if (curBeat % 4 == 0) {
				curLight = FlxG.random.int(0, phillyLightsColors.length - 1, [curLight]);
				phillyWindow.color = phillyLightsColors[curLight];
				phillyWindow.alpha = 1;
			}
		}
	}
}