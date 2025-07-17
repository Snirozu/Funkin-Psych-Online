package online.states;

import online.states.RoomState.LobbyCharacter;
import flixel.util.FlxStringUtil;
import backend.WeekData;
import flixel.effects.FlxFlicker;
import sys.FileSystem;
import objects.Character;

#if lumod
@:build(lumod.LuaScriptClass.build())
#end
class ResultsState extends MusicBeatState {
	public static var gainedPoints:Float = 0;
	var gainedText:FlxText;

	var win:FlxSprite;
	var lose:FlxSprite;
	var tie:FlxSprite;
	var back:FlxSprite;

	var characters:Map<String, LobbyCharacter> = new Map();
	var charactersLayer:FlxTypedGroup<LobbyCharacter> = new FlxTypedGroup<LobbyCharacter>();
	var winnerSID:String = null;
	var winnerBfSide:Null<Bool> = null;

	var chatBox:ChatBox;
	var disableInput = true;

	var dim:FlxSprite;
	var spotlight:FlxSprite;

	var camBG:FlxCamera = new FlxCamera();
	var cam:FlxCamera = new FlxCamera();
	var camHUD:FlxCamera = new FlxCamera();

	//required for lumod
	public function new() {
		super();
	}

    override function create() {
        super.create();

		FlxG.cameras.reset(camBG);
		FlxG.cameras.add(cam, false);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.setDefaultDrawTarget(cam, true);
		cam.bgColor.alpha = 0;
		camHUD.bgColor.alpha = 0;

		CustomFadeTransition.nextCamera = camHUD;

		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end

		WeekData.reloadWeekFiles(false);
		for (i in 0...WeekData.weeksList.length) {
			WeekData.setDirectoryFromWeek(WeekData.weeksLoaded.get(WeekData.weeksList[i]));
		}
		Mods.loadTopMod();
		WeekData.setDirectoryFromWeek();
        
        FlxG.sound.music.stop();

		#if lumod
		if (luaValue == false)
			return;
		#end

		FlxG.sound.playMusic(Paths.music('title'), 0);
		FlxG.sound.music.onComplete = () -> {
			FlxG.sound.playMusic(Paths.music('breakfast'), 0);
			FlxG.sound.music.fadeIn(5, 0, 0.7);
		};
		FlxG.sound.music.fadeIn(5, 0, 0.7);

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xff1f1f1f;
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.cameras = [camBG];
		add(bg);

		cam.scroll.set(120, 130);
		cam.zoom = 0.75;

		charactersLayer.cameras = [cam];
		add(charactersLayer);

		win = new FlxSprite();
		win.antialiasing = ClientPrefs.data.antialiasing;
		win.frames = Paths.getSparrowAtlas('onlineJudges');
		win.animation.addByPrefix('idle', "weiner", 24);
		win.animation.play('idle');
		win.scale.set(0.65, 0.65);
		win.updateHitbox();
		win.y = 50;
        win.alpha = 0;
		win.cameras = [cam];
		add(win);

		lose = new FlxSprite();
		lose.antialiasing = ClientPrefs.data.antialiasing;
		lose.frames = Paths.getSparrowAtlas('onlineJudges');
		lose.animation.addByPrefix('idle', "loser", 24);
		lose.animation.play('idle');
		lose.scale.set(0.6, 0.6);
		lose.updateHitbox();
		lose.y = win.y + 10;
		lose.alpha = 0;
		lose.cameras = [cam];
		add(lose);

		tie = new FlxSprite();
		tie.antialiasing = ClientPrefs.data.antialiasing;
		tie.frames = Paths.getSparrowAtlas('onlineJudges');
		tie.animation.addByPrefix('idle', "tie", 24);
		tie.animation.play('idle');
		tie.scale.set(0.6, 0.6);
		tie.updateHitbox();
		tie.y = win.y + 10;
		tie.alpha = 0;
		tie.cameras = [camHUD];
		tie.screenCenter(X);
		add(tie);

		back = new FlxSprite();
		back.antialiasing = ClientPrefs.data.antialiasing;
		back.frames = Paths.getSparrowAtlas('backspace');
		back.animation.addByPrefix('idle', "backspace to exit white", 24);
		back.animation.addByPrefix('black', "backspace to exit0", 24);
		back.animation.addByPrefix('press', "backspace PRESSED", 24);
		back.animation.play('idle');
		back.scale.set(0.5, 0.5);
		back.updateHitbox();
		back.x = 30;
		back.y = FlxG.height - back.height - 30;
		back.alpha = 0;
		back.cameras = [camHUD];
		add(back);

		gainedText = new FlxText(0, 0, 0, '+ ${gainedPoints}FP');
		gainedText.setFormat(null, 40, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		//gainedText.setPosition(FlxG.width - gainedText.width - 20, FlxG.height - gainedText.height - 20);
		gainedText.setPosition(30, FlxG.height - gainedText.height - 25);
		gainedText.visible = false;
		gainedText.cameras = [camHUD];
		add(gainedText);

		#if !DEBUG_RESULTS
		if (!GameClient.isConnected()) {
			FlxG.switchState(() -> new OnlineState());
			return;
		}
		#end

		var prevWValue:Null<Float> = null;
		var playersWValue:Map<String, Array<String>> = new Map<String, Array<String>>();
		var switchedTimes:Int = 0;
		var isTie:Bool = false;

		var sumValueBySide = [0.0, 0.0];
		var playersBySide = [0, 0];

		for (sid => player in GameClient.room.state.players) {
			var char = new LobbyCharacter(player, cam, player.verified, 5);
			char.yBoxStepOffset = 0;
			char.xBoxStepOffset = 380;
			char.xCharStepOffset = 300;
			char.profileBoxXOffset = 530;
			char.profileBoxXOffsetP2 = 270;
			char.profileBoxYOffset = 200;
			var pAccuracy = GameClient.getPlayerAccuracyPercent(player);
			char.profileBox.desc.text = 'Accuracy: ${pAccuracy}%';
			char.profileBox.desc.text += '\nScore: ${FlxStringUtil.formatMoney(player.score, false)} - ${player.songPoints}FP';
			char.profileBox.desc.text += '\nMax Combo: ${player.maxCombo}';
			char.profileBox.desc.text += '\nSick: ${player.sicks}';
			char.profileBox.desc.text += '\nGoods: ${player.goods}';
			char.profileBox.desc.text += '\nBad: ${player.bads}';
			char.profileBox.desc.text += '\nShits: ${player.shits}';
			char.profileBox.desc.text += '\nMisses: ${player.misses}';
			char.profileBox.visible = false;
			characters.set(sid, char);
			if (charactersLayer.members == null)
				charactersLayer = new FlxTypedGroup<LobbyCharacter>();
			charactersLayer.add(char);

			if (char.character.animExists('resultsIdle')) {
				char.character.playAnim('resultsIdle');
			}
			else {
				char.character.dance();
				char.character.animation.finish();
			}

			switch (GameClient.room.state.winCondition) {
				case 0:
					if (GameClient.room.state.teamMode) {
						sumValueBySide[player.bfSide ? 1 : 0] += GameClient.getPlayerAccuracyPercent(player);
						playersBySide[player.bfSide ? 1 : 0]++;
					}

					if (prevWValue == null || pAccuracy >= prevWValue) {
						prevWValue = pAccuracy;
						winnerSID = sid;
						switchedTimes++;

						var arr = playersWValue.get(prevWValue + '') ?? [];
						arr.push(sid);
						playersWValue.set(prevWValue + '', arr);
					}
				case 1:
					if (GameClient.room.state.teamMode) {
						sumValueBySide[player.bfSide ? 1 : 0] += player.score;
						playersBySide[player.bfSide ? 1 : 0]++;
					}

					if (prevWValue == null || player.score >= prevWValue) {
						prevWValue = player.score;
						winnerSID = sid;
						switchedTimes++;

						var arr = playersWValue.get(prevWValue + '') ?? [];
						arr.push(sid);
						playersWValue.set(prevWValue + '', arr);
					}
				case 2:
					if (GameClient.room.state.teamMode) {
						sumValueBySide[player.bfSide ? 1 : 0] += player.misses;
						playersBySide[player.bfSide ? 1 : 0]++;
					}

					if (prevWValue == null || player.misses <= prevWValue) {
						prevWValue = player.misses;
						winnerSID = sid;
						switchedTimes++;

						var arr = playersWValue.get(prevWValue + '') ?? [];
						arr.push(sid);
						playersWValue.set(prevWValue + '', arr);
					}
				case 3:
					if (GameClient.room.state.teamMode) {
						sumValueBySide[player.bfSide ? 1 : 0] += player.songPoints;
						playersBySide[player.bfSide ? 1 : 0]++;
					}
					
					if (prevWValue == null || player.songPoints >= prevWValue) {
						prevWValue = player.songPoints;
						winnerSID = sid;
						switchedTimes++;

						var arr = playersWValue.get(prevWValue + '') ?? [];
						arr.push(sid);
						playersWValue.set(prevWValue + '', arr);
					}
				case 4:
					if (GameClient.room.state.teamMode) {
						sumValueBySide[player.bfSide ? 1 : 0] += player.maxCombo;
						playersBySide[player.bfSide ? 1 : 0]++;
					}

					if (prevWValue == null || player.maxCombo >= prevWValue) {
						prevWValue = player.maxCombo;
						winnerSID = sid;
						switchedTimes++;

						var arr = playersWValue.get(prevWValue + '') ?? [];
						arr.push(sid);
						playersWValue.set(prevWValue + '', arr);
					}
			}
		}

		var avgValueBySide = [
			sumValueBySide[0] / playersBySide[0],
			sumValueBySide[1] / playersBySide[1]
		];

		if (playersWValue.get(prevWValue + '').length >= 2) {
			if (!GameClient.room.state.teamMode) {
				isTie = true;
			}
			winnerSID = null;
		}

		if (GameClient.room.state.teamMode) {
			if (winnerSID != null)
				characters.get(winnerSID).profileBox.desc.text += '\n- BEST SOLO -';

			switch (GameClient.room.state.winCondition) {
				case 0, 1, 3, 4:
					if (avgValueBySide[0] == avgValueBySide[1]) {
						isTie = true;
						winnerBfSide = null;
						//break; // break outside loop --- stfu haxe
					}
					else
						winnerBfSide = avgValueBySide[1] > avgValueBySide[0];

				case 2:
					if (avgValueBySide[0] == avgValueBySide[1]) {
						isTie = true;
						winnerBfSide = null;
					}
					else
						winnerBfSide = avgValueBySide[1] < avgValueBySide[0];
			}
		}
		
		var maxOffset = 0.;
		for (character in characters) {
			character.character.ox = character.player.ox;
			character.repos();

			maxOffset = Math.max(maxOffset, character.character.ox);
		}

		charactersLayer.members.sort(function (a:LobbyCharacter, b:LobbyCharacter) {
			if (a == null || b == null)
				return 0;
			return b.character.ox - a.character.ox;
		});

		var avgWinTeamMidX = 0.0;
		var avgWinTeamMidXNums = 0;
		
		if (!isTie) {
			if (GameClient.room.state.teamMode) {
				for (character in characters) {
					if (character.player.bfSide == winnerBfSide) {
						avgWinTeamMidX += character.profileBox.getMidpoint().x;
						avgWinTeamMidXNums++;
					}
				}

				win.x = (avgWinTeamMidX / avgWinTeamMidXNums) - win.width / 2;
			}
			else {
				win.x = characters.get(winnerSID).profileBox.getMidpoint().x - win.width / 2;
			}
		}

		// #if DISCORD_ALLOWED
		// DiscordClient.changePresence(
		// 	'Results! (Online) - ${!GameClient.room.state.isPrivate ? 'VS. ' + opPlayer.name : ''}', 
		// 	'${mePlayer.score} - ${gainedPoints}FP (${meAccuracy}%)'
		// );
		// #end

		#if DISCORD_ALLOWED
		DiscordClient.changePresence(
			'Results! (Online)',
			''
		);
		#end

		dim = new FlxSprite(0, 0);
		dim.makeGraphic(Std.int(FlxG.width), Std.int(FlxG.height), FlxColor.BLACK);
		dim.scrollFactor.set(0, 0);
		dim.alpha = 1;
		dim.cameras = [cam];
		dim.scale.set(2.0, 2.0);
		add(dim);

		Paths.setCurrentLevel('week1');
		spotlight = new FlxSprite(0, -50).loadGraphic(Paths.image('spotlight'));
		spotlight.alpha = 0.375;
		spotlight.blend = ADD;
		spotlight.visible = false;
		if (!isTie) {
			if (GameClient.room.state.teamMode) {
				spotlight.x = (avgWinTeamMidX / avgWinTeamMidXNums) - spotlight.width / 2;
			}
			else {
				spotlight.x = characters.get(winnerSID).profileBox.getMidpoint().x - spotlight.width / 2;
			}
		}
		spotlight.cameras = [cam];
		add(spotlight);

		chatBox = new ChatBox(camera);
		chatBox.cameras = [camHUD];
		add(chatBox);

		FlxTween.tween(dim, {alpha: 0.25}, 2, {ease: FlxEase.quadInOut});
		FlxTween.tween(back, {alpha: 1}, 1, {ease: FlxEase.quartInOut, startDelay: 2.0});

		new FlxTimer().start(3, (t) -> {
			disableInput = false;
		});

		new FlxTimer().start(2, (t) -> {
			for (sid => player in characters) {
				player.profileBox.visible = true;
				player.profileBox.avatar.visible = player.player.verified;
				player.character.noAnimationBullshit = true;
				if (isTie) {
					if (player.character.animExists('tie')) {
						player.character.playAnim("tie");

						if (player.character.animExists('tieLoop')) {
							player.character.animation.finishCallback = n -> {
								player.character.animation.finishCallback = null;
								player.character.playAnim("tieLoop");
							};
						}
					}
					else {
						player.character.playAnim("hurt");
					}
					continue;
				}

				if ((!GameClient.room.state.teamMode && sid == winnerSID) || (GameClient.room.state.teamMode && player.player.bfSide == winnerBfSide)) {
					if (player.character.animExists('win')) {
						player.character.playAnim("win");
	
						if (player.character.animExists('winLoop')) {
							player.character.animation.finishCallback = n -> {
								player.character.animation.finishCallback = null;
								player.character.playAnim("winLoop");
							};
						}
					}
					else {
						player.character.playAnim("hey");
					}
				}
				else {
					if (player.character.animExists('lose')) {
						player.character.playAnim("lose");

						if (player.character.animExists('loseLoop')) {
							player.character.animation.finishCallback = n -> {
								player.character.animation.finishCallback = null;
								player.character.playAnim("loseLoop");
							};
						}
					}
					else {
						player.character.playAnim("hurt");
					}
				}
			}

			if (!isTie) {
				FlxTween.tween(win, {alpha: 1}, 0.5, {ease: FlxEase.quadInOut});
				if (ClientPrefs.data.flashing) {
					flickerLoop();
				}
				spotlight.visible = true;
			}
			else {
				FlxTween.tween(tie, {alpha: 1}, 0.5, {ease: FlxEase.quadInOut});
			}

			// FlxTween.tween(p1Text, {alpha: 1}, 1, {ease: FlxEase.quartInOut, startDelay: 1});
			// FlxTween.tween(p2Text, {alpha: 1}, 1, {ease: FlxEase.quartInOut, startDelay: 1});
			// FlxTween.tween(p1Bg, {alpha: 0.5}, 1, {ease: FlxEase.quartInOut, startDelay: 1});
			// FlxTween.tween(p2Bg, {alpha: 0.5}, 1, {ease: FlxEase.quartInOut, startDelay: 1});

			// if (winner > -1) {
			// 	FlxTween.tween(win, {alpha: 1}, 0.5, {ease: FlxEase.quadInOut});
			// 	FlxTween.tween(lose, {alpha: 1, angle: 3}, 0.5, {ease: FlxEase.quadInOut});
			// 	FlxTween.tween(lose, {angle: 0}, 0.2, {ease: FlxEase.quadInOut});
			// 	if (ClientPrefs.data.flashing) {
			// 		flickerLoop();
			// 	}
			// 	spotlight.visible = true;
			// }
			// else {
			// 	FlxTween.tween(dim, {alpha: 0}, 1, {ease: FlxEase.quadInOut});
			// 	FlxTween.tween(tie, {alpha: 1}, 0.5, {ease: FlxEase.quadInOut});
			// }

			if (gainedPoints > 0) {
				gainedText.visible = true;
				FlxG.sound.play(Paths.sound('fap'));
				if (ClientPrefs.data.flashing)
					FlxFlicker.flicker(gainedText, 0.4, 0.05, true);
				FlxTween.tween(gainedText, {alpha: 0.2}, 2, {ease: FlxEase.quadInOut});

				new FlxTimer().start(2, (t) -> {
					FlxTween.tween(gainedText, {x: back.x, y: back.y - 50, size: 25}, 1, {ease: FlxEase.quartOut});
				});
			}

			gainedPoints = 0;

		});

		registerMessages();
		FlxG.mouse.visible = true;
    }

	function registerMessages() {
		GameClient.initStateListeners(this, this.registerMessages);

		if (GameClient.isConnected()) {
			GameClient.send("status", "Viewing results");

			GameClient.room.onMessage("charPlay", function(_message:Array<Dynamic>) {
				var sid:String = _message[0];
				var message:Array<Dynamic> = _message[1];

				Waiter.put(() -> {
					if (message == null || message[0] == null)
						return;

					characters.get(sid).character.playAnim(message[0], true);
				});
			});
		}
	}

	function flickerLoop() {
		FlxFlicker.flicker(spotlight, 0.2, 0.05, true);
		new FlxTimer().start(FlxG.random.int(3, 12), (t) -> {
			if (!destroyed) {
				flickerLoop();
			}
		});
	}

	override function update(elapsed) {
        super.update(elapsed);

		#if lumod
		if (FlxG.keys.justPressed.F12) {
			trace('reloading lumod');
			Lumod.cache.scripts.clear();
			lmLoad();
		}

		if (luaValue == false)
			return;

		#end

		if (!disableInput) {
			if (back.animation.curAnim.name != "press")
				back.animation.play('idle');

			if (!chatBox.focused && (!FlxG.keys.justPressed.TAB && controls.BACK || FlxG.keys.justPressed.BACKSPACE || FlxG.keys.justPressed.ENTER)) {
				FlxG.sound.music.stop();
				FlxG.sound.play(Paths.sound('cancelMenu'));

				disableInput = true;
				back.animation.play('press');
				back.offset.set(80, 50);
				if (gainedText.visible)
					FlxTween.tween(gainedText, {alpha: 0}, 0.2, {ease: FlxEase.quadInOut});
                new FlxTimer().start(0.5, (t) -> {
					FlxG.switchState(() -> new RoomState());
                });
            }

			if (!chatBox.focused && controls.TAUNT) {
				var altSuffix = FlxG.keys.pressed.ALT ? '-alt' : '';
				characters.get(GameClient.room.sessionId).character.playAnim('taunt' + altSuffix, true);
				if (GameClient.isConnected())
					GameClient.send("charPlay", ["taunt" + altSuffix]);
			}
        }
        else {
			if (back.animation.curAnim.name != "press")
				back.animation.play('black');
        }
    }
}