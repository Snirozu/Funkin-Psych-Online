package states.stages;

import openfl.media.Sound;
import states.stages.objects.*;

class MallErect extends BaseStage
{
	var upperBoppers:BGSprite;
	var bottomBoppers:MallCrowd;
	var santa:BGSprite;

	override function create()
	{
        var bg:BGSprite = new BGSprite('christmas/erect/bgWalls', -1000, -500, 0.2, 0.2);
        bg.setGraphicSize(Std.int(bg.width * 0.9));
        bg.updateHitbox();
        add(bg);

        if (!ClientPrefs.data.lowQuality) {
            upperBoppers = new BGSprite('christmas/erect/upperBop', -300, -80, 0.33, 0.33, ['upperBop']);
            upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
            upperBoppers.updateHitbox();
            add(upperBoppers);

            var bgEscalator:BGSprite = new BGSprite('christmas/erect/bgEscalator', -1100, -600, 0.3, 0.3);
            bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
            bgEscalator.updateHitbox();
            add(bgEscalator);
        }

        var tree:BGSprite = new BGSprite('christmas/erect/christmasTree', 370, -250, 0.40, 0.40);
        add(tree);

        var fog:BGSprite = new BGSprite('christmas/erect/white', -1000, 100, 0.85, 0.85);
        fog.setGraphicSize(Std.int(fog.width * 0.9));
        fog.updateHitbox();
        add(fog);

        bottomBoppers = new MallCrowd(-400, 120, 'christmas/erect/bottomBop', 'bottomBop');
        add(bottomBoppers);

		var fgSnow:BGSprite = new BGSprite('christmas/fgSnow', -600, 720);
		fgSnow.setGraphicSize(Std.int(fgSnow.width * 1.3));
		fgSnow.updateHitbox();
		add(fgSnow);

		santa = new BGSprite('christmas/santa', -840, 150, 1, 1, ['santa idle in fear']);
		precacheSound('Lights_Shut_off');
		setDefaultGF('gf-christmas');

		if (songName == "eggnog") {
			prepareSanta();
			setEndCallback(santaCutscene);
		}
	}

	override function createPost() {
		add(santa);
	}

	override function countdownTick(count:Countdown, num:Int) everyoneDance();
	override function beatHit() everyoneDance();

	override function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float)
	{
		switch(eventName)
		{
			case "Hey!":
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						return;
				}
				bottomBoppers.animation.play('hey', true);
				bottomBoppers.heyTimer = flValue2;
		}
	}

	function everyoneDance()
	{
		if(!ClientPrefs.data.lowQuality)
			upperBoppers.dance(true);

		bottomBoppers.dance(true);
		santa.dance(true);
	}

	var santaSpeak:FlxAnimate;
	var dadTroll:FlxAnimate;
	var _santaSpeaks:Sound;
	var _dadShoot:Sound;

	function prepareSanta() {
		trace("santa is about to fucking die");

		santaSpeak = new FlxAnimate(0, 0);
		santaSpeak.antialiasing = ClientPrefs.data.antialiasing;
		Paths.loadAnimateAtlas(santaSpeak, 'christmas/santa_speaks_assets');
		santaSpeak.anim.addBySymbol('scene', 'santa whole scene', 24, false);

		dadTroll = new FlxAnimate(0, 0);
		dadTroll.antialiasing = ClientPrefs.data.antialiasing;
		Paths.loadAnimateAtlas(dadTroll, 'christmas/parents_shoot_assets');
		dadTroll.anim.addBySymbol('scene', 'parents whole scene', 24, false);

		_santaSpeaks = Paths.sound('santa_emotion');
		_dadShoot = Paths.sound('santa_shot_n_falls');
	}

	function santaCutscene() {
		game.canPause = false;
		game.canReset = false;

		FlxTween.tween(game.camHUD, {alpha: 0}, 1, {ease: FlxEase.quadIn});
		
		game.tweenCameraZoom(0.85, 2, true, FlxEase.expoOut);
		game.camFollow.setPosition(santa.getMidpoint().x + 230, santa.getMidpoint().y - 120);
		//FlxG.camera.follow(santa, LOCKON, 0.05);

		santa.visible = false; // guys the real santa is not dead!@!!! wie cool ist das bitte
		santaSpeak.anim.play('scene');
		santaSpeak.setPosition(-455, 500);

		game.dad.visible = false;
		dadTroll.anim.play('scene');
		dadTroll.setPosition(-520, 505);
		add(dadTroll);
		add(santaSpeak);

		FlxG.sound.play(_santaSpeaks, 1.0);

		new FlxTimer().start(2.8, function(tmr) {
			game.tweenCameraZoom(0.7, 9, true, FlxEase.quadInOut);
		});

		new FlxTimer().start(11.375, function(tmr) {
			FlxG.sound.play(_dadShoot, 1.0);
		});

		new FlxTimer().start(12.83, function(tmr) {
			game.camGame.shake(0.005, 0.2);
			game.camFollow.setPosition(santa.getMidpoint().x + 300, santa.getMidpoint().y);
		});

		new FlxTimer().start(15, function(tmr) {
			game.camHUD.fade(0xFF000000, 1, false, null, true);
		});

		new FlxTimer().start(16, function(tmr) {
			endSong();
		});
	}
}