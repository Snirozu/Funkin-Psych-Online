package online.states;

import flixel.math.FlxAngle;
import flixel.addons.display.FlxBackdrop;
import openfl.media.Sound;
import flixel.math.FlxVelocity;
import flixel.text.FlxBitmapText;
import flixel.addons.transition.FlxTransitionableState;

import online.states.ResultsSoloState.DA_ANGLE;

// written everything based of my observations :ngNerd:

@:build(lumod.LuaScriptClass.build())
class ResultsSoloState extends MusicBeatState {
    public var data:ResultsData;

	public var charSprites:Array<FlxSprite> = [];
	public var charSpritesDelay:Array<Float> = [];
	public var charAnimates:Array<FlxAnimate> = [];
	public var charAnimatesDelay:Array<Float> = [];

	var rankTextos:FlxBackdrop;
	var rankScroll:FlxBackdrop;
	var rankScrollNeg:FlxBackdrop;

	var songText:FlxSpriteGroup;
	var vig:FlxSprite;

	var music:Sound;
	var musicIntro:Sound;

	var camBG:FlxCamera;
	var camRotScroll:FlxCamera;
	var camMain:FlxCamera;

	public static final DA_ANGLE = -3.5;

    public function new(data:ResultsData) {
        super();

		this.data = data;

		FlxTransitionableState.skipNextTransIn = true;
		FlxTransitionableState.skipNextTransOut = true;
    }

    override function create() {
        super.create();

		camBG = new FlxCamera();
		camRotScroll = new FlxCamera();
		camMain = new FlxCamera();
		
		camBG.bgColor = FlxColor.fromString('#FDC65B');
		camRotScroll.bgColor.alpha = 0;
		camRotScroll.angle = DA_ANGLE;
		camRotScroll.height += 50;
		camMain.bgColor.alpha = 0;

		FlxG.cameras.reset(camMain);
		FlxG.cameras.add(camBG, false);
		FlxG.cameras.add(camRotScroll, false);
		FlxG.cameras.add(camMain, false);
		FlxG.cameras.setDefaultDrawTarget(camMain, true);

		data.character ??= 'bf';

		if (data.character.endsWith("-player"))
			data.character = data.character.substring(0, data.character.length - "-player".length);

		if (data.character.endsWith("-pixel"))
			data.character = data.character.substring(0, data.character.length - "-pixel".length);

		if (data.character.endsWith("-christmas"))
			data.character = data.character.substring(0, data.character.length - "-christmas".length);

		FlxG.sound.destroy(true);

		Mods.loadTopMod();
		
		var curSkin = ClientPrefs.data.modSkin ?? [null, null];
		if (data.character == curSkin[0])
			Mods.currentModDirectory = curSkin[0];

		var charData:Dynamic = ShitUtil.getJson('characters_results/${data.character}');
		if (charData == null)
			charData = ShitUtil.getJson('characters_results/bf');

		var rankString = 'LOSS';
		var rank = charData.SHIT;
		//what the fuck is perfectGold?
		if (data.misses <= 0 && data.shits <= 0 && data.bads <= 0) {
			rank = charData.PERFECT;
			rankString = 'PERFECT';
		}
		else if (data.accuracy >= 0.9) {
			rank = charData.EXCELLENT;
			rankString = 'EXCELLENT';
		}
		else if (data.accuracy >= 0.8) {
			rank = charData.GREAT;
			rankString = 'GREAT';
		}
		else if (data.accuracy >= 0.6) {
			rank = charData.GOOD;
			rankString = 'GOOD';
		}

		var musicPathPrefix = '${rank.sound}/${rank.sound}';
		music = Paths.music(musicPathPrefix = '${rank.sound}/${rank.sound}-${data.character}');
		if (music == null)
			music = Paths.music(musicPathPrefix = '${rank.sound}/${rank.sound}');
		musicIntro = Paths.music(musicPathPrefix + '-intro');
		if (!(rank.soundOnFlash ?? false))
			playMusic();

		rankScroll = new FlxBackdrop(Paths.image('resultScreen/rankText/rankScroll' + rankString), XY, 20, 90);
		rankScroll.visible = false;
		rankScroll.cameras = [camRotScroll];
		rankScroll.y = -10;
		add(rankScroll);

		rankScrollNeg = new FlxBackdrop(Paths.image('resultScreen/rankText/rankScroll' + rankString), XY, 20, 90);
		rankScrollNeg.y = 60;
		rankScrollNeg.visible = false;
		rankScrollNeg.cameras = [camRotScroll];
		add(rankScrollNeg);

		var coolData:Array<Dynamic> = rank.images;
		if (coolData != null) {
			for (imageData in coolData) {
				switch (imageData.renderType) {
					case 'animateatlas':
						var coolAssAnim:FlxAnimate = new FlxAnimate(imageData.offsets[0], imageData.offsets[1]);
						Paths.loadAnimateAtlas(coolAssAnim, imageData.assetPath);
						if (imageData.scale != null)
							coolAssAnim.scale.set(imageData.scale, imageData.scale);
						coolAssAnim.visible = false;
						coolAssAnim.anim.onComplete = () -> {
							if (imageData.loopFrameLabel != null)
								coolAssAnim.anim.goToFrameLabel(imageData.loopFrameLabel);

							if (imageData.loopFrame != null)
								coolAssAnim.anim.play(null, true, false, imageData.loopFrame);
						};
						charAnimates.push(coolAssAnim);
						charAnimatesDelay.push(imageData?.delay ?? 0);
						add(coolAssAnim);
					case 'sparrow':
						var sprite = new FlxSprite(imageData.offsets[0], imageData.offsets[1]);
						sprite.frames = Paths.getSparrowAtlas(imageData.assetPath);
						if (imageData.scale != null)
							sprite.scale.set(imageData.scale, imageData.scale);
						sprite.visible = false;
						sprite.animation.addByPrefix('idle', '', 24, false);
						sprite.animation.finishCallback = _ -> {
							if (imageData.loopFrame != null)
								sprite.animation.play('idle', true, false, imageData.loopFrame);
						};
						charSprites.push(sprite);
						charSpritesDelay.push(imageData?.delay ?? 0);
						add(sprite);
				}
			}
		}

		rankTextos = new FlxBackdrop(Paths.image('resultScreen/rankText/rankText' + rankString), Y, 0, 40); 
		rankTextos.x = FlxG.width - rankTextos.width;
		rankTextos.visible = false;
		add(rankTextos);

		var flash = new FlxSprite();
		flash.makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
		flash.alpha = 0;
		add(flash);

		songText = new FlxSpriteGroup(550);
		songText.alpha = 0;
		add(songText);

		if (data.difficultyName != null) {
			if (data.difficultyName.trim() == '')
				data.difficultyName = 'normal';

			var img = Paths.image('resultScreen/diff_' + data.difficultyName.toLowerCase());
			if (img != null) {
				var songDifficulty = new FlxSprite(img);
				songText.add(songDifficulty);
			}
		}

		var songAccuracy = new ClearTextSmol(0, 0, data.accuracy, DA_ANGLE);
		ShitUtil.moveByDegrees(songAccuracy, songText.width + 20, DA_ANGLE);
		ShitUtil.moveByDegrees(songAccuracy, 10, DA_ANGLE + 90);
		songAccuracy.visible = false;
		songText.add(songAccuracy);

		var songTitle = new FlxBitmapText(0, 0, data.songName ?? "Penis Balls", Fonts.getTardlingFont());
		songTitle.letterSpacing = -10;
		songTitle.angle = DA_ANGLE;
		ShitUtil.moveByDegrees(songTitle, (songAccuracy.x - songText.x) + songAccuracy.members.length * 45, DA_ANGLE);
		songText.add(songTitle);
		
		var songFP = new FlxBitmapText(0, 0, data.points + "FP", Fonts.getTardlingFont('FP'));
		songFP.letterSpacing = -10;
		songFP.angle = DA_ANGLE;
		ShitUtil.moveByDegrees(songFP, (songTitle.x - songText.x) + songTitle.width + 20, DA_ANGLE);
		ShitUtil.moveByDegrees(songFP, 10, DA_ANGLE + 90);
		songFP.visible = false;
		songText.add(songFP);

		var blackBar = new FlxSprite(Paths.image('resultScreen/topBarBlack'));
		blackBar.y = -blackBar.frameHeight;
        add(blackBar);

        var title = new FlxSprite(-200, -15);
		title.frames = Paths.getSparrowAtlas('resultScreen/results');
        title.animation.addByPrefix('idle', 'results instance 1', 24, false);
        title.animation.play('idle');
        add(title);

		var soundSystem = new FlxSprite(-17, -183);
		soundSystem.frames = Paths.getSparrowAtlas('resultScreen/soundSystem');
		soundSystem.animation.addByPrefix('idle', 'sound system', 24, false);
		soundSystem.visible = false;
		add(soundSystem);

		var ratingNames = new FlxSprite(-136, 131);
		ratingNames.frames = Paths.getSparrowAtlas('resultScreen/ratingsPopin');
		ratingNames.animation.addByPrefix('idle', 'Categories', 24, false);
		ratingNames.visible = false;
		add(ratingNames);

		var scoreName = new FlxSprite(-177, 512);
		scoreName.frames = Paths.getSparrowAtlas('resultScreen/scorePopin');
		scoreName.animation.addByPrefix('idle', 'tally score', 24, false);
		scoreName.visible = false;
		add(scoreName);

		var highscore = new FlxSprite(42, 552);
		highscore.frames = Paths.getSparrowAtlas('resultScreen/highscoreNew');
		highscore.animation.addByPrefix('idle', 'highscoreAnim', 24, false);
		highscore.animation.addByIndices('loop', 'highscoreAnim', [for (i in 4...28 + 1) i], '', 24, true);
		highscore.animation.finishCallback = _ -> {
			highscore.animation.play('loop');
		};
		highscore.visible = false;
		add(highscore);

		var hitNotes = new TallieNumbers(335, 145, data.hitNotes);
		var combo = new TallieNumbers(338, 201, data.combo);
		var sicks = new TallieNumbers(208, 270, data.sicks, 0x2DE356);
		var goods = new TallieNumbers(201, 324, data.goods, 0x25B5EB);
		var bads = new TallieNumbers(177, 383, data.bads, 0xE6B72B);
		var shits = new TallieNumbers(193, 440, data.shits, 0xDC3834);
		var misses = new TallieNumbers(255, 492, data.misses, 0xA244D5);
		var score = new Seg7Numbers(72, 607, data.score);

		var clearText = new ClearText(800, 250);

        //show diff only for erect and nightmare difficulty

		vig = new FlxSprite();
		vig.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(vig);

		FlxTween.tween(blackBar, {y: 0}, 0.5, {ease: FlxEase.quadOut});
		FlxTween.tween(vig, {alpha: 0}, 0.8, {ease: FlxEase.quadOut});

        FlxTimer.wait(0.5, () -> {
			soundSystem.visible = true;
			soundSystem.animation.play('idle');
        });

		FlxTimer.wait(1, () -> {
			ratingNames.visible = true;
			ratingNames.animation.play('idle');

			ratingNames.animation.finishCallback = _ -> {
				scoreName.visible = true;
				scoreName.animation.play('idle');
				scoreName.animation.callback = (n, frameNum, frameIndex) -> {
					if (frameIndex == 1) {
						add(score);
						scoreName.animation.callback = null;

						flash.alpha = 0.5;
						FlxTween.tween(flash, {alpha: 0}, 0.3, {ease: FlxEase.quadOut});
						
						var prevAcc = 0.;
						FlxTween.tween(clearText, {value: data.accuracy}, 3.3, {ease: FlxEase.quadOut, onUpdate: tc -> {
							if (Math.floor(clearText.value * 100) > Math.floor(prevAcc * 100)) {
								FlxG.sound.play(Paths.sound('scrollMenu'), 0.5);
							}
							prevAcc = clearText.value;
						}, onComplete: _ -> {
							flash.alpha = 0.5;
							FlxTween.tween(flash, {alpha: 0}, 0.3, {ease: FlxEase.quadOut});

							FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
							FlxTween.tween(clearText, {alpha: 0}, 1, {ease: FlxEase.quadOut, startDelay: 0.5});

							songFP.visible = true;
							songAccuracy.visible = true;
							rankTextos.visible = true;
							rankScroll.visible = true;
							rankScrollNeg.visible = true;

							if (rank.soundOnFlash ?? false)
								playMusic();

							for (i => sprite in charAnimates) {
								FlxTimer.wait(charAnimatesDelay[i], () -> {
									sprite.visible = true;
									sprite.anim.play();
								});
							}
							for (i => sprite in charSprites) {
								FlxTimer.wait(charSpritesDelay[i], () -> {
									sprite.visible = true;
									sprite.animation.play('idle');
								});
							}

							#if DISCORD_ALLOWED
							DiscordClient.changePresence(
								'Results! - ${data.songName ?? "???"} [${(data.difficultyName ?? "???").toUpperCase()}]', 
								'${data.score} - ${data.points}FP (${Math.floor((data.accuracy ?? 0) * 100)}%)'
							);
							#end
						}});
						add(clearText);
					}
				};
			};

			// idfc about making this look fancy
			FlxTimer.wait(0.4, () -> {
				add(hitNotes);
			FlxTimer.wait(0.4, () -> {
				add(combo);
			FlxTimer.wait(0.4, () -> {
				add(sicks);
			FlxTimer.wait(0.4, () -> {
				add(goods);
				if (data.isHighscore) {
					FlxTimer.wait(1, () -> {
						highscore.visible = true;
						highscore.animation.play('idle');
					});
				}
			FlxTimer.wait(0.4, () -> {
				add(bads);
				score.playAnimAllDelay('activate', 0.1);
			FlxTimer.wait(0.4, () -> {
				add(shits);
			FlxTimer.wait(0.4, () -> {
				add(misses);
			});});});});});});});

			songText.alpha = 1;
			FlxTween.tween(songText, {y: 125}, 0.5, {ease: FlxEase.quadOut});
		});

		FlxTimer.wait(6, () -> {
			songText.velocity.copyFrom(FlxVelocity.velocityFromAngle(DA_ANGLE, -150));
		});

		//tween to 4 for 100%lerp

        add(new DebugPosHelper());
    }

	function playMusic() {
		if (musicIntro != null) {
			FlxG.sound.playMusic(musicIntro, 1, false);
			FlxG.sound.music.onComplete = () -> {
				if (music != null)
					FlxG.sound.playMusic(music);
			};
		}
		else if (music != null) {
			FlxG.sound.playMusic(music);
		}
	}

	var time:Float = 0;

	var exiting:Bool = false;
	override function update(elapsed:Float) {
		super.update(elapsed);

		time += elapsed;

		if (songText.x + songText.width < 500) {
			songText.setPosition(FlxG.width, 85);
		}

		if (FlxG.sound.music != null && !exiting && (controls.ACCEPT || controls.BACK)) {
			exiting = true;
			FlxTimer.globalManager.clear();
			FlxTween.globalManager.clear();
			remove(vig, true); //splice so it doesn't go back to it's original position when re-added
			add(vig);
			FlxTween.tween(vig, {alpha: 1}, 0.5, {ease: FlxEase.quadIn}); // i'm not remaking the stickerstate :P
			FlxTween.tween(FlxG.sound.music, {pitch: 3}, 0.1, {
				onComplete: _ -> {
					FlxTween.tween(FlxG.sound.music, {pitch: 0.5}, 0.5, {
						onComplete: _ -> {
							FlxG.sound.destroy(true);
							FlxG.switchState(new states.FreeplayState());
						}
					});
				}
			});
		}

		rankTextos.y -= elapsed * 50;
		rankScroll.x += elapsed * 5;
		rankScrollNeg.x -= elapsed * 5;
	}
}

typedef ResultsData = {
	var ?hitNotes:Int;
	var ?combo:Int;
	var ?sicks:Int;
	var ?goods:Int;
	var ?bads:Int;
	var ?shits:Int;
	var ?misses:Int;
	var ?score:Float;
	var ?accuracy:Float;
	var ?isHighscore:Bool;
	var ?difficultyName:String;
	var ?songName:String;
	var ?character:String;
	var ?points:Float;
}

class TallieNumbers extends FlxSpriteGroup {
	public function new(x:Float = 0, y:Float = 0, value:Int, ?color:FlxColor = null) {
		super(x, y);

		var lastX:Float = 0;
		for (number in Std.string(value).split('')) {
			var num = new FlxSprite(lastX);
			num.frames = Paths.getSparrowAtlas('resultScreen/tallieNumber');
			num.animation.addByPrefix('idle', number + ' small');
			num.animation.play('idle');
			if (color != null)
				num.color = color;
			lastX += 40;
			add(num);
		}
	}
}

class Seg7Numbers extends FlxSpriteGroup {
	public function new(x:Float = 0, y:Float = 0, value:Float, ?positions:Int = 10) {
		super(x, y);

		var numbers = Std.string(Math.ffloor(value)).split('');
		while (numbers.length < positions)
			numbers.unshift('_');

		var lastX:Float = 0;
		for (number in numbers) {
			var num = new FlxSprite(lastX);
			num.frames = Paths.getSparrowAtlas('resultScreen/score-digital-numbers');
			num.animation.addByPrefix('idle', 'DISABLED');
			num.animation.addByPrefix('gone', 'GONE');
			//fuck you dave
			var animPrefix = null;
			switch (number) {
				case '0':
					animPrefix = 'ZERO DIGITAL';
				case '1':
					animPrefix = 'ONE DIGITAL';
				case '2':
					animPrefix = 'TWO DIGITAL';
				case '3':
					animPrefix = 'THREE DIGITAL';
				case '4':
					animPrefix = 'FOUR DIGITAL';
				case '5':
					animPrefix = 'FIVE DIGITAL';
				case '6':
					animPrefix = 'SIX DIGITAL';
				case '7':
					animPrefix = 'SEVEN DIGITAL';
				case '8':
					animPrefix = 'EIGHT DIGITAL';
				case '9':
					animPrefix = 'NINE DIGITAL';
			}
			if (animPrefix != null) {
				num.animation.addByPrefix('activate', animPrefix, 24, false);
				num.animation.addByIndices('active', animPrefix, [0], '', false);
				num.animation.finishCallback = anim -> {
					if (anim == 'activate')
						num.animation.play('active');
				};
			}
			num.animation.play('idle');
			lastX += 65;
			//num.visible = false;
			add(num);
		}
	}

	public function playAnimAllDelay(anim:String, ?delay:Float = 0.05) {
		for (i in 0...members.length) {
			FlxTimer.wait(delay * i, () -> {
				playAnim(i, anim);
			});
		}
	}

	public function playAnim(i:Int, anim:String) {
		//members[i].visible = true;

		if (!members[i].animation.exists(anim))
			members[i].animation.play('idle');
		
		members[i].animation.play(anim);
	}
}

class ClearText extends FlxSpriteGroup {
	var clearImage:FlxSprite;

	var nums:Array<FlxSprite> = [];

	public var value(default, set):Float;
	
	public function new(x:Float = 0, y:Float = 0) {
		super(x, y);

		clearImage = new FlxSprite(0, 0, Paths.image('resultScreen/clearPercent/clearPercentText'));
		add(clearImage);

		value = 0;
	}

	public function set_value(v:Float) {
		for (num in nums) {
			num.kill();
		}
		nums = [];

		var numbers = Std.string(Math.floor(v * 100)).split('');
		var lastX = 0;
		for (number in numbers) {
			var num = recycle(ClearNum);
			num.setPosition(lastX - (80 * (numbers.length - 2)), 70);
			num.animation.addByPrefix('idle', 'number ' + number + ' ');
			num.animation.play('idle');
			nums.push(num);
			lastX += 80;
			add(num);
		}

		return value = v;
	}
}

class ClearNum extends FlxSprite {
	public function new() {
		super(0, 0);

		frames = Paths.getSparrowAtlas('resultScreen/clearPercent/clearPercentNumberRight');
	}
}

class ClearTextSmol extends FlxSpriteGroup {
	var clearImage:FlxSprite;

	var nums:Array<FlxSprite> = [];

	public var value(default, set):Float;

	public function new(x:Float = 0, y:Float = 0, ?value:Float = 0, ?angle:Float = 0) {
		super(x, y);

		clearImage = new FlxSprite(0, 0, Paths.image('resultScreen/clearPercent/clearPercentTextSmall'));
		add(clearImage);

		this.value = value;
		this.angle = angle;
	}

	public function set_value(v:Float) {
		for (num in nums) {
			num.kill();
		}
		nums = [];

		var numbers = Std.string(Math.floor(v * 100)).split('');
		var lastX = 0.;
		for (number in numbers) {
			var num = recycle(ClearNumSmol);
			num.setPosition(0, 0);
			ShitUtil.moveByDegrees(num, lastX, angle);
			num.animation.addByPrefix('idle', 'number ' + number + ' ');
			num.animation.play('idle');
			nums.push(num);
			lastX += num.width;
			add(num);
		}
		clearImage.setPosition(x, y);
		ShitUtil.moveByDegrees(clearImage, lastX + 10, angle);

		return value = v;
	}
}

class ClearNumSmol extends FlxSprite {
	public function new() {
		super(0, 0);

		frames = Paths.getSparrowAtlas('resultScreen/clearPercent/clearPercentNumberSmall');
	}
}