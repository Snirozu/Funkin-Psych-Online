package substates;

import online.util.ShitUtil;
import openfl.media.Sound;
import backend.WeekData;

import objects.Character;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.math.FlxPoint;

import states.StoryMenuState;
import states.FreeplayState;

// i hate how this state is coded, can we kill shadoemaryo

class GameOverSubstate extends MusicBeatSubstate
{
	public var boyfriend:Character;
	var fakeOut:Character;
	var camFollow:FlxObject;
	var updateCamera:Bool = false;
	var playingDeathSound:Bool = false;

	var stageSuffix:String = "";

	public static var characterName:String = 'bf-dead';
	public static var deathSoundName:String = 'fnf_loss_sfx';
	public static var loopSoundName:String = 'gameOver';
	public static var endSoundName:String = 'gameOverEnd';

	public static var instance:GameOverSubstate;

	public var retryButton:Character;

	var tankTalk:Sound;
	var deathSound:Sound;
	var loopSound:Sound;
	var endSound:Sound;

	public static function resetVariables() {
		characterName = 'bf-dead';
		deathSoundName = 'fnf_loss_sfx';
		loopSoundName = 'gameOver';
		endSoundName = 'gameOverEnd';

		var _song = PlayState.SONG;
		if(_song != null)
		{
			if(_song.gameOverChar != null && _song.gameOverChar.trim().length > 0) characterName = _song.gameOverChar;
			if(_song.gameOverSound != null && _song.gameOverSound.trim().length > 0) deathSoundName = _song.gameOverSound;
			if(_song.gameOverLoop != null && _song.gameOverLoop.trim().length > 0) loopSoundName = _song.gameOverLoop;
			if(_song.gameOverEnd != null && _song.gameOverEnd.trim().length > 0) endSoundName = _song.gameOverEnd;
		}
	}

	override function create()
	{
		instance = this;
		Main.view3D.onDebug = (v) -> {
			this.active = !v;
		};
		PlayState.instance.callOnScripts('onGameOverStart', []);

		super.create();
	}

	public function new(x:Float, y:Float, camX:Float, camY:Float, ?overCharacter:Character)
	{
		super();

		PlayState.instance.setOnScripts('inGameOver', true);

		Conductor.songPosition = 0;

		if (overCharacter == null) {
			boyfriend = new Character(x, y, characterName, true, false);
		}
		else {
			if (overCharacter.deadName != null) {
				boyfriend = new Character(x, y, overCharacter.deadName, true, false);
			}
			else {
				boyfriend = overCharacter;
				boyfriend.setPosition(x, y);
				boyfriend.visible = true;
				boyfriend.alpha = 1;
			}
		}

		if (boyfriend.isAnimateAtlas) {
			boyfriend.onAtlasAnimationComplete = animName -> {
				if (animName == "confirm") {
					boyfriend.atlas.anim.play("confirm", true, false);
				}
				else {
					boyfriend.atlas.anim.play("loop", true, false);
				}
			};
		}
		boyfriend.x += boyfriend.positionArray[0];
		boyfriend.y += boyfriend.positionArray[1];
		add(boyfriend);

		var retryChar:String = null;
		if (boyfriend.curCharacter.startsWith('pico')) {
			deathSoundName = 'fnf_loss_sfx-pico';
			loopSoundName = 'gameOver-pico';
			endSoundName = 'gameOverEnd-pico';

			if (!boyfriend.curCharacter.contains('-nene') && !boyfriend.curCharacter.contains('-pixel')) {
				retryChar = 'pico-retry-button';
	
				var neneKill = new FlxSprite(x, y);
				if (boyfriend.curCharacter.startsWith('pico-christmas')) {
					neneKill.frames = Paths.getSparrowAtlas('characters/neneChristmas/neneChristmasKnife');
					neneKill.animation.addByPrefix('idle', 'knife toss xmas', 24, false);
				}
				else {
					neneKill.frames = Paths.getSparrowAtlas('characters/NeneKnifeToss');
					neneKill.animation.addByPrefix('idle', 'knife toss', 24, false);
				}
				neneKill.animation.finishCallback = _ -> {
					FlxTween.tween(neneKill, {alpha: 0}, 0.5, {ease: FlxEase.quadOut});
				};
				neneKill.animation.play('idle');
				neneKill.setPosition(
					PlayState.instance.gf.getScreenPosition().x + PlayState.instance.gf.positionArray[0],
					PlayState.instance.gf.getScreenPosition().y + PlayState.instance.gf.positionArray[1]
				);
				add(neneKill);
			}

			if (boyfriend.curCharacter == 'pico-pixel-dead') {
				deathSoundName = 'fnf_loss_sfx-pixel-pico';
				loopSoundName = 'gameOver-pixel-pico';
				endSoundName = 'gameOverEnd-pixel-pico';

				var neneKill = new FlxSprite(x, y);
				neneKill.frames = Paths.getSparrowAtlas('characters/nenePixelKnifeToss');
				neneKill.animation.addByPrefix('idle', 'knifetosscolor', 24, false);
				neneKill.animation.finishCallback = _ -> {
					FlxTween.tween(neneKill, {alpha: 0}, 0.5, {ease: FlxEase.quadOut});
				};
				neneKill.animation.play('idle');
				neneKill.setPosition(
					PlayState.instance.gf.getScreenPosition().x + PlayState.instance.gf.positionArray[0] - 100,
					PlayState.instance.gf.getScreenPosition().y + PlayState.instance.gf.positionArray[1] - 200
				);
				neneKill.antialiasing = false;
				neneKill.scale.set(6, 6);
				neneKill.updateHitbox();
				add(neneKill);
			}
		}

		if (retryChar != null) {
			retryButton = new Character(x, y, retryChar, true);
			retryButton.setPosition(x, y);
			retryButton.x += retryButton.positionArray[0];
			retryButton.y += retryButton.positionArray[1];
			retryButton.visible = false;
			retryButton.alpha = 0;
			add(retryButton);
		}

		FlxG.camera.scroll.set();
		FlxG.camera.target = null;
		// why is it frame based lol
		new FlxTimer().start(0.5, function(tmr:FlxTimer) {
			if (!isFollowingAlready) {
				FlxG.camera.follow(camFollow, LOCKON, 0.01);
				updateCamera = true;
				isFollowingAlready = true;
			}
		});

		deathSound = Paths.sound(deathSoundName);
		loopSound = Paths.music(loopSoundName);
		endSound = Paths.music(endSoundName);

		if (FlxG.random.bool(0.1) && boyfriend.curCharacter == 'bf-dead') {
			boyfriend.visible = false;
			fakeOut = new Character(boyfriend.x, boyfriend.y, 'bf-fakeout', true);
			fakeOut.playAnim('fakeOut');
			add(fakeOut);
			FlxG.sound.play(Paths.sound('fakeout_death'));
		}
		else {
			FlxG.sound.play(deathSound);
			boyfriend.playAnim('firstDeath');
		}

		if (PlayState.instance.dad.curCharacter.startsWith('tankman')) {
			if (ClientPrefs.data.modSkin != null)
				ShitUtil.tempSwitchMod(ClientPrefs.data.modSkin[0], () -> {
					tankTalk = Paths.sound('jeffGameover-${ClientPrefs.data.modSkin[1]}/jeffGameover-' + FlxG.random.int(1, 10));
				});
			tankTalk ??= Paths.sound('jeffGameover/jeffGameover-' + FlxG.random.int(1, 25));
		}

		camFollow = new FlxObject(0, 0, 1, 1);
		if (boyfriend.curCharacter.contains('-dead'))
			camFollow.setPosition(boyfriend.getMidpoint().x + boyfriend.cameraPosition[0], boyfriend.getMidpoint().y + boyfriend.cameraPosition[1]);
		else
			camFollow.setPosition(boyfriend.getMidpoint().x, boyfriend.getMidpoint().y);
		FlxG.camera.focusOn(new FlxPoint(FlxG.camera.scroll.x + (FlxG.camera.width / 2), FlxG.camera.scroll.y + (FlxG.camera.height / 2)));
		add(camFollow);

		add(new online.objects.DebugPosHelper());
	}

	public var startedDeath:Bool = false;
	var isFollowingAlready:Bool = false;
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		PlayState.instance.callOnScripts('onUpdate', [elapsed]);

		if (PlayState.redditMod) {
			if (FlxG.random.bool(1)) {
				online.network.Auth.saveClose();
				Sys.exit(1);
			}
		}
		else {
			if (controls.ACCEPT) {
				endBullshit();
			}

			if (controls.BACK) {
				#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
				FlxG.sound.music.stop();
				PlayState.deathCounter = 0;
				PlayState.seenCutscene = false;
				PlayState.chartingMode = false;

				Mods.loadTopMod();
				if (PlayState.isStoryMode)
					FlxG.switchState(() -> new StoryMenuState());
				else
					FlxG.switchState(() -> new FreeplayState());

				states.TitleState.playFreakyMusic();
				PlayState.instance.callOnScripts('onGameOverConfirm', [false]);
			}
		}

		if (retryButton != null && retryButton.visible) {
			retryButton.alpha += elapsed;
		}

		if (fakeOut != null && fakeOut.atlas.anim.finished) {
			boyfriend.visible = true;
			boyfriend.playAnim('firstDeath');
			FlxG.sound.play(deathSound);
			remove(fakeOut);
			fakeOut = null;
		}
		
		if (boyfriend.animation.curAnim != null)
		{
			if (boyfriend.animation.curAnim.name == 'firstDeath' && boyfriend.animation.curAnim.finished && startedDeath) {
				if (retryButton != null) {
					retryButton.visible = true;
					retryButton.playAnim('deathLoop');
				}
				boyfriend.playAnim('deathLoop');
			}

			if(boyfriend.animation.curAnim.name == 'firstDeath')
			{
				if(boyfriend.animation.curAnim.curFrame >= 12 && !isFollowingAlready)
				{
					FlxG.camera.follow(camFollow, LOCKON, 0.01);
					updateCamera = true;
					isFollowingAlready = true;
				}

				if (boyfriend.animation.curAnim.finished && !playingDeathSound && !isEnding)
				{
					startedDeath = true;
					if (tankTalk != null)
					{
						playingDeathSound = true;
						coolStartDeath(0.2);
						
						var exclude:Array<Int> = [];
						//if(!ClientPrefs.cursing) exclude = [1, 3, 8, 13, 17, 21];

						FlxG.sound.play(tankTalk, 1, false, null, true, function() {
							if(!isEnding)
							{
								FlxG.sound.music.fadeIn(1, 0.2, 1);
							}
						});
					}
					else coolStartDeath();
				}
			}
		}
		
		// if(updateCamera) FlxG.camera.followLerp = FlxMath.bound(elapsed * 0.6, 0, 1);
		// else FlxG.camera.followLerp = 0;

		if (FlxG.sound.music.playing)
		{
			Conductor.songPosition = FlxG.sound.music.time;
		}
		PlayState.instance.callOnScripts('onUpdatePost', [elapsed]);
	}

	var isEnding:Bool = false;

	function coolStartDeath(?volume:Float = 1):Void
		FlxG.sound.playMusic(loopSound, volume);

	function endBullshit():Void
	{
		if (!isEnding)
		{
			isEnding = true;
			if (retryButton != null) {
				retryButton.visible = true;
				retryButton.playAnim('deathConfirm');
			}
			boyfriend.playAnim('deathConfirm', true);
			FlxG.sound.music.stop();
			FlxG.sound.play(endSound);
			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
				{
					FlxG.switchState(new PlayState());
				});
			});
			PlayState.instance.callOnScripts('onGameOverConfirm', [true]);
		}
	}

	override function destroy()
	{
		instance = null;
		super.destroy();
	}
}
