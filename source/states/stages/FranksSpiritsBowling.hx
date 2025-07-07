package states.stages;

import openfl.filters.ShaderFilter;
import shaders.DropShadow;
import shaders.DropShadowScreenspace;
import states.stages.objects.TankmenBG;
import flixel.math.FlxPoint;
import objects.Character;
import openfl.media.Sound;
import hxvlc.flixel.FlxVideoSprite;

class FranksSpiritsBowling extends BaseStage {
    var dancers:Array<BGSprite> = [];

	var tankmanEnd:FlxAnimate;
	var stressEndAudio:Sound;
	var rimlightCamera:FlxCamera;
	var screenspaceRimlight:DropShadowScreenspace;

	var tankmanRun:FlxTypedGroup<TankmenBG>;
	var sniper:BGSprite;

	override function create() {
		var bg:BGSprite = new BGSprite('erect/bg', -985, -805);
		bg.setGraphicSize(Std.int(bg.width * 1.15));
		bg.updateHitbox();
        add(bg);

		var guy:BGSprite = new BGSprite('erect/guy', 1398, 407, 1, 1, ['BLTank2 instance 1'], false);
		guy.setGraphicSize(Std.int(guy.width * 1.15));
		guy.updateHitbox();
		add(guy);
		dancers.push(guy);

		sniper = new BGSprite('erect/sniper', -127, 349, 1, 1, ['Tankmanidlebaked instance 1'], false);
		sniper.setGraphicSize(Std.int(sniper.width * 1.15));
		sniper.updateHitbox();
		sniper.animation.addByPrefix('sip', 'tanksippingBaked instance 1', 24, false);
		sniper.animation.play('sip', true);
        add(sniper);
		dancers.push(sniper);

		tankmanRun = new FlxTypedGroup<TankmenBG>();
		add(tankmanRun);
    }

	override function createPost() {
		if (songName == 'stress-pico') {
			rimlightCamera = new FlxCamera();

			FlxG.cameras.remove(game.camHUD, false);
			FlxG.cameras.remove(game.camOther, false);

			FlxG.cameras.add(rimlightCamera, false);
			FlxG.cameras.add(game.camHUD, false);
			FlxG.cameras.add(game.camOther, false);

			rimlightCamera.bgColor = 0x00FFFFFF; // Show the game scene behind the camera.

			screenspaceRimlight = new DropShadowScreenspace();

			screenspaceRimlight.baseBrightness = -46;
			screenspaceRimlight.baseHue = -38;
			screenspaceRimlight.baseContrast = -25;
			screenspaceRimlight.baseSaturation = -20;

			screenspaceRimlight.angle = 45;
			screenspaceRimlight.threshold = 0.3;

			var rimlightFilter:ShaderFilter = new ShaderFilter(screenspaceRimlight.shader);

			rimlightCamera.filters = [rimlightFilter];

			tankmanEnd = new FlxAnimate(778, 513);
			tankmanEnd.antialiasing = ClientPrefs.data.antialiasing;
			Paths.loadAnimateAtlas(tankmanEnd, 'erect/cutscene/tankmanEnding');
			tankmanEnd.anim.addBySymbol('scene', 'tankman stress ending', 24, false);
			tankmanEnd.cameras = [rimlightCamera];

			if (!seenCutscene) {
				setStartCallback(() -> {
					game.startVideo('stressPicoCutscene');
					inCutscene = true;
					canPause = true;
				});
			}
			setEndCallback(stressEndCutscene);
		}

		stressEndAudio = Paths.sound('erect/endCutscene');

		if (!ClientPrefs.data.lowQuality) {
			for (daGf in gfGroup) {
				if (!(daGf is Character))
					continue;

				var gf:Character = cast daGf;
				if (gf.curCharacter.endsWith('-speaker')) {
					var firstTank:TankmenBG = new TankmenBG(20, 500, true);
					firstTank.resetShit(20, 600, true);
					firstTank.strumTime = 10;
					firstTank.visible = false;
					tankmanRun.add(firstTank);

					for (i in 0...TankmenBG.animationNotes.length) {
						if (FlxG.random.bool(20)) {
							var tankBih = tankmanRun.recycle(TankmenBG);
							tankBih.strumTime = TankmenBG.animationNotes[i][0];
							tankBih.resetShit(500, 320, TankmenBG.animationNotes[i][1] < 2);
							tankBih.scale.set(1.1, 1.1);
							tankBih.updateHitbox();
							tankmanRun.add(tankBih);
						}
					}
					break;
				}
			}
		}

		if(ClientPrefs.data.shaders) {
			for(character in boyfriendGroup.members) {
				if(!Std.isOfType(character, objects.Character))
					continue;

				var rim:DropShadow = new DropShadow();
				rim.setAdjustColor(-46, -38, -25, -20);
				rim.color = 0xFFDFEF3C;
				rim.attachedSprite = character;

				rim.angle = 90;
				character.shader = rim.shader;

				character.animation.callback = function(name:String, frameNumber:Int, frameIndex:Int) {
					if(name.endsWith('-bloody'))
						rim.useAltMask = true;

					rim.updateFrameInfo(character.frame);
				};
			}

			for(character in gfGroup.members) {
				if(!Std.isOfType(character, objects.Character))
					continue;

				var rim:DropShadow = new DropShadow();
				rim.setAdjustColor(-46, -38, -25, -20);
				rim.color = 0xFFDFEF3C;
				rim.attachedSprite = character;

				rim.angle = 90;
				character.shader = rim.shader;

				character.animation.callback = function(name:String, frameNumber:Int, frameIndex:Int) {
					rim.updateFrameInfo(character.frame);
				};
			}

			for(character in dadGroup.members) {
				if(!Std.isOfType(character, objects.Character))
					continue;

				var rim:DropShadow = new DropShadow();
				rim.setAdjustColor(-46, -38, -25, -20);
				rim.color = 0xFFDFEF3C;
				rim.attachedSprite = character;

				rim.angle = 135;
				rim.threshold = 0.3;
				character.shader = rim.shader;

				switch(cast(character, objects.Character)?.curCharacter) {
					case 'tankman-bloody':
						rim.loadAltMask('erect/masks/tankmanCaptainBloody_mask');
				}

				rim.maskThreshold = 1;
				rim.useAltMask = false;

				character.animation.callback = function(name:String, frameNumber:Int, frameIndex:Int) {
					rim.updateFrameInfo(character.frame);
				};
			}
		}
	}

	override function update(elapsed:Float) {
		@:privateAccess
		if (rimlightCamera != null) {
			rimlightCamera.scroll.copyFrom(game.camGame.scroll);
			rimlightCamera.zoom = game.camGame.zoom;
		}
	}

	override function beatHit() {
		for (dancer in dancers) {
			if (dancer.animation.finished)
			    dancer.dance();
		};
	}

	function stressEndCutscene() {
		inCutscene = true;
		game.canPause = false;
		game.canReset = false;

		FlxTween.tween(game.camHUD, {alpha: 0}, 1, {ease: FlxEase.quadIn});
		
		game.tweenCameraZoom(0.65, 2, true, FlxEase.expoOut);
		game.moveCamera(true, false, 270, -70);
		game.tweenCameraToFollowPoint(2.8, FlxEase.expoOut);

		FlxG.sound.play(stressEndAudio);

		game.dad.visible = false;
		tankmanEnd.anim.play('scene');
		add(tankmanEnd);

		var bgSprite = new FlxSprite(0, 0);
		bgSprite.makeGraphic(2000, 2500, 0xFF000000);
		bgSprite.cameras = [PlayState.instance.camOther]; // Show over the HUD but below the video.
		bgSprite.alpha = 0;
		add(bgSprite);

		new FlxTimer().start(176 / 24, _ -> {
			game.boyfriend.playAnim('laughEnd', true);
		});

		new FlxTimer().start(270 / 24, _ -> {
			game.tweenCameraToPosition(camFollow.x, camFollow.y - 370, 2, FlxEase.quadInOut);
			FlxTween.tween(bgSprite, {alpha: 1}, 2, null);
			sniper.animation.play('sip', true);
		});

		new FlxTimer().start(320 / 24, _ -> {
			endSong();
		});
	}
}