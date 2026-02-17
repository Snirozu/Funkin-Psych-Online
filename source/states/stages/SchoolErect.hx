package states.stages;

import states.stages.objects.*;
import shaders.AdjustColor;
import shaders.DropShadow;
import substates.GameOverSubstate;
import objects.BGSprite;

// btw, all bgGirls related stuff is commented out because base game has it like that too
// just in-case they add them back or smth


class SchoolErect extends BaseStage
{
	// var bgGirls:BackgroundGirls;
	override function create()
	{
		var _song = PlayState.SONG;
		if(_song.gameOverSound == null || _song.gameOverSound.trim().length < 1) GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
		if(_song.gameOverLoop == null || _song.gameOverLoop.trim().length < 1) GameOverSubstate.loopSoundName = 'gameOver-pixel';
		if(_song.gameOverEnd == null || _song.gameOverEnd.trim().length < 1) GameOverSubstate.endSoundName = 'gameOverEnd-pixel';
		if(_song.gameOverChar == null || _song.gameOverChar.trim().length < 1) GameOverSubstate.characterName = 'bf-pixel-dead';

		var bgSky:BGSprite = new BGSprite('weeb/erect/weebSky', -164, -78, 0.2, 0.2);
		bgSky.scale.set(PlayState.daPixelZoom, PlayState.daPixelZoom);
		bgSky.updateHitbox();
		add(bgSky);
		bgSky.antialiasing = false;

		var backTrees:BGSprite = new BGSprite('weeb/erect/weebBackTrees', -242, -80, 0.5, 0.5);
		add(backTrees);
		backTrees.antialiasing = false;

		var bgSchool:BGSprite = new BGSprite('weeb/erect/weebSchool', -216, -38, 0.75, 0.75);
		add(bgSchool);
		bgSchool.antialiasing = false;

		var bgStreet:BGSprite = new BGSprite('weeb/erect/weebStreet', -200, 6, 1, 1);
		add(bgStreet);
		bgStreet.antialiasing = false;

		if(!ClientPrefs.data.lowQuality) {
			var fgTrees:BGSprite = new BGSprite('weeb/erect/weebTreesBack', -200, 6, 1, 1);
			fgTrees.scale.set(PlayState.daPixelZoom, PlayState.daPixelZoom);
			fgTrees.updateHitbox();
			add(fgTrees);
			fgTrees.antialiasing = false;
		}

		var bgTrees:FlxSprite = new FlxSprite(-806, -1050);
		bgTrees.frames = Paths.getPackerAtlas('weeb/erect/weebTrees');
		bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
		bgTrees.animation.play('treeLoop');
		bgTrees.scrollFactor.set(0.85, 0.85);
		bgTrees.scale.set(PlayState.daPixelZoom, PlayState.daPixelZoom);
		bgTrees.updateHitbox();
		add(bgTrees);
		bgTrees.antialiasing = false;

		if(!ClientPrefs.data.lowQuality) {
			var treeLeaves:BGSprite = new BGSprite('weeb/erect/petals', -20, -40, 0.85, 0.85, ['PETALS ALL'], true);
			treeLeaves.scale.set(PlayState.daPixelZoom, PlayState.daPixelZoom);
			treeLeaves.updateHitbox();
			add(treeLeaves);
			treeLeaves.antialiasing = false;
		}

		bgSky.scale.set(PlayState.daPixelZoom, PlayState.daPixelZoom);
		bgSchool.scale.set(PlayState.daPixelZoom, PlayState.daPixelZoom);
		backTrees.scale.set(PlayState.daPixelZoom, PlayState.daPixelZoom);
		bgStreet.scale.set(PlayState.daPixelZoom, PlayState.daPixelZoom);
		bgTrees.scale.set(PlayState.daPixelZoom, PlayState.daPixelZoom);

		bgSky.updateHitbox();
		bgSchool.updateHitbox();
		backTrees.updateHitbox();
		bgStreet.updateHitbox();
		bgTrees.updateHitbox();

		/*if(!ClientPrefs.data.lowQuality) {
			bgGirls = new BackgroundGirls(-100, 190);
			bgGirls.scrollFactor.set(0.9, 0.9);
			add(bgGirls);
		}*/
		setDefaultGF('gf-pixel');

		if (songName.startsWith('senpai')) {
			FlxG.sound.playMusic(Paths.music('Lunchbox'), 0);
			FlxG.sound.music.fadeIn(1, 0, 0.8);
		}
		else if (songName.startsWith('roses')) {
			FlxG.sound.play(Paths.sound('ANGRY_TEXT_BOX'));
			if (isStoryMode && !seenCutscene) {
				FlxG.sound.play(Paths.sound('ANGRY'));
			}
			/*if (bgGirls != null)
				bgGirls.swapDanceType();*/
		}

		/*if(isStoryMode && !seenCutscene) {
			initDoof();
			setStartCallback(schoolIntro);
		}*/
	}

	override function createPost() {
		if(!ClientPrefs.data.shaders)
			return;

		for(character in boyfriendGroup.members) {
			if(!Std.isOfType(character, objects.Character))
				continue;

			var rim:DropShadow = new DropShadow();
			rim.setAdjustColor(-66, -10, 24, -23);
			rim.color = 0xFF52351d;
			rim.antialiasAmt = 0;
			rim.attachedSprite = character;
			rim.distance = 5;

			rim.angle = 90;
			character.shader = rim.shader;

			switch(cast(character, objects.Character)?.curCharacter) {
				case 'bf-pixel':
					rim.loadAltMask('weeb/erect/masks/bfPixel_mask');
				case 'pico-pixel':
					rim.loadAltMask('weeb/erect/masks/picoPixel_mask');
			}

			rim.maskThreshold = 1;
			rim.useAltMask = true;

			character.animation.callback = function(name:String, frameNumber:Int, frameIndex:Int) {
				rim.updateFrameInfo(character.frame);
			};
		}

		for(character in gfGroup.members) {
			if(!Std.isOfType(character, objects.Character))
				continue;

			var rim:DropShadow = new DropShadow();
			rim.setAdjustColor(-42, -10, 5, -25);
			rim.color = 0xFF52351d;
			rim.antialiasAmt = 0;
			rim.attachedSprite = character;

			rim.angle = 90;
			rim.distance = 3;
			rim.threshold = 0.3;

			character.shader = rim.shader;

			switch(cast(character, objects.Character).curCharacter) {
				case 'gf-pixel':
					rim.loadAltMask('weeb/erect/masks/gfPixel_mask');
				case 'nene-pixel':
					rim.loadAltMask('weeb/erect/masks/nenePixel_mask');
			}

			rim.maskThreshold = 1;
			rim.useAltMask = true;

			character.animation.callback = function(name:String, frameNumber:Int, frameIndex:Int) {
				rim.updateFrameInfo(character.frame);
			};
		}

		for(character in dadGroup.members) {
			if(!Std.isOfType(character, objects.Character))
				continue;

			var rim:DropShadow = new DropShadow();
			rim.setAdjustColor(-66, -10, 24, -23);
			rim.color = 0xFF52351d;
			rim.antialiasAmt = 0;
			rim.attachedSprite = character;
			rim.distance = 5;

			rim.angle = 90;
			character.shader = rim.shader;

			switch(cast(character, objects.Character)?.curCharacter) {
				case 'senpai', 'senpai-angry':
					rim.loadAltMask('weeb/erect/masks/senpai_mask');
			}

			rim.maskThreshold = 1;
			rim.useAltMask = true;

			character.animation.callback = function(name:String, frameNumber:Int, frameIndex:Int) {
				rim.updateFrameInfo(character.frame);
			};
		}


		if(gf.speaker != null) {
			var noRimShader:AdjustColor = new AdjustColor();
			noRimShader.hue = -10;
			noRimShader.saturation = -23;
			noRimShader.brightness = -66;
			noRimShader.contrast = 24;

			if (gf.speaker is ABotSpeaker) {
				var abot:ABotSpeaker = cast gf.speaker;

				var abotSpeakerShader:DropShadow = new DropShadow();
				abotSpeakerShader.setAdjustColor(-66, -10, 24, -23);
				abotSpeakerShader.angle = 90;
				abotSpeakerShader.color = 0xFF52351d;
				abotSpeakerShader.distance = 5;
				abotSpeakerShader.antialiasAmt = 0;
				abotSpeakerShader.threshold = 1;

				abotSpeakerShader.attachedSprite = abot.speakerPixel;
				abot.speakerPixel.animation.callback = function(name:String, frameNumber:Int, frameIndex:Int) {
					abotSpeakerShader.updateFrameInfo(abot.speakerPixel.frame);
				};

				abotSpeakerShader.loadAltMask('weeb/erect/masks/aBotPixel_mask');
				abotSpeakerShader.maskThreshold = 0;
				abotSpeakerShader.useAltMask = true;

				abot.bg.shader = noRimShader.shader;
				abot.eyesPixel.shader = noRimShader.shader;
				for(viz in abot.vizSprites)
					viz.shader = noRimShader.shader;
				abot.speakerPixel.shader = abotSpeakerShader.shader;
			}
			else {
				gf.speaker.shader = noRimShader.shader;
			}
		}
	}

	/*override function beatHit()
	{
		if(bgGirls != null) bgGirls.dance();
	}

	// For events
	override function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float)
	{
		switch(eventName)
		{
			case "BG Freaks Expression":
				if(bgGirls != null) bgGirls.swapDanceType();
		}
	}

	var doof:DialogueBox = null;
	function initDoof()
	{
		var file:String = Paths.txt(songName + '/' + songName + 'Dialogue'); //Checks for vanilla/Senpai dialogue
		#if MODS_ALLOWED
		if (!FileSystem.exists(file))
		#else
		if (!OpenFlAssets.exists(file))
		#end
		{
			startCountdown();
			return;
		}

		doof = new DialogueBox(false, CoolUtil.coolTextFile(file));
		doof.cameras = [camHUD];
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;
		doof.nextDialogueThing = PlayState.instance.startNextDialogue;
		doof.skipDialogueThing = PlayState.instance.skipDialogue;
	}
	
	function schoolIntro():Void
	{
		inCutscene = true;
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		if (songName.startsWith('senpai')) add(black);

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
				tmr.reset(0.3);
			else
			{
				if (doof != null)
					add(doof);
				else
					startCountdown();

				remove(black);
				black.destroy();
			}
		});
	}*/
}