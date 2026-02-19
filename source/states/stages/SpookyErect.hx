package states.stages;

import states.stages.objects.ABotSpeaker;
import objects.Character;

class SpookyErect extends BaseStage
{
	var lightList:Array<FlxSprite> = [];

	var bfDark:Character;
	var dadDark:Character;
	var gfDark:Character;

	override function create()
	{
		var trees = new BGSprite('erect/bgtrees', 200, 50, 0.8, 0.8, ['bgtrees'], true, 5);
		add(trees);

		var bgDark = new BGSprite('erect/bgDark', -360, -220, 1, 1);
		add(bgDark);
		var bgLight = new BGSprite('erect/bgLight', -360, -220, 1, 1);
		lightList.push(bgLight);
		add(bgLight);

		//PRECACHE SOUNDS
		precacheSound('thunder_1');
		precacheSound('thunder_2');
	}

	override function createPost() {
		var stairsDark = new BGSprite('erect/stairsDark', 966, -225, 1, 1);
		add(stairsDark);
		var stairsLight = new BGSprite('erect/stairsLight', 966, -225, 1, 1);
		lightList.push(stairsLight);
		add(stairsLight);

		if (!ClientPrefs.data.lowQuality) {
			lightList.push(boyfriend);
			lightList.push(dad);
			if (gf != null)
				lightList.push(gf);
			if (gf?.speaker != null && gf.speaker is ABotSpeaker) {
				lightList.push(cast (gf.speaker, ABotSpeaker).speaker);
			}

			online.util.ShitUtil.tempSwitchMod(boyfriend.modDir, () -> {
				bfDark = new Character(boyfriend.x, boyfriend.y, boyfriend.curCharacter + '-dark', boyfriend.isPlayer);
				if (bfDark.loadFailed) {
					bfDark = new Character(boyfriend.x, boyfriend.y, boyfriend.curCharacter, boyfriend.isPlayer);
					bfDark.colorTransform.redOffset = -245;
					bfDark.colorTransform.greenOffset = -240;
					bfDark.colorTransform.blueOffset = -230;
				}
				bfDark.flipX = boyfriend.flipX;
				bfDark.debugMode = true;
				addBehindBF(bfDark);
			});

			online.util.ShitUtil.tempSwitchMod(dad.modDir, () -> {
				dadDark = new Character(dad.x, dad.y, dad.curCharacter + '-dark', dad.isPlayer);
				if (dadDark.loadFailed) {
					dadDark = new Character(dad.x, dad.y, dad.curCharacter, dad.isPlayer);
					dadDark.colorTransform.redOffset = -245;
					dadDark.colorTransform.greenOffset = -240;
					dadDark.colorTransform.blueOffset = -230;
				}
				dadDark.flipX = dad.flipX;
				dadDark.debugMode = true;
				addBehindDad(dadDark);
			});

			if (gf != null) {
				online.util.ShitUtil.tempSwitchMod(gf.modDir, () -> {
					gfDark = new Character(gf.x, gf.y, gf.curCharacter + '-dark', gf.isPlayer);
					if (gfDark.loadFailed) {
						gfDark = new Character(gf.x, gf.y, gf.curCharacter, gf.isPlayer);
						gfDark.colorTransform.redOffset = -245;
						gfDark.colorTransform.greenOffset = -240;
						gfDark.colorTransform.blueOffset = -230;
					}
					gfDark.flipX = gf.flipX;
					gfDark.debugMode = true;
					gfDark.x -= gfGroup.x;
					gfDark.y -= gfGroup.y;
					addBehindGF(gfDark, true);
				});
			}
		}

		for (sprite in lightList) {
			sprite.alpha = 0;
		}
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;
	override function beatHit()
	{
		if (FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset)
		{
			lightningStrikeShit();
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (bfDark != null) {
			if (bfDark.animation.name != boyfriend.animation.name)
				bfDark.playAnim(boyfriend.animation.name, true);

			// if (!checkNullAnim(bfDark, boyfriend) && boyfriend.animation.curAnim.curFrame == 0)
			// 	bfDark.animation.curAnim.play(true, false, 0);
			if (!checkNullAnim(bfDark, boyfriend))
				bfDark.animation.curAnim.curFrame = boyfriend.animation.curAnim.curFrame;
		}

		if (dadDark != null) {
			if (dadDark.animation.name != dad.animation.name)
				dadDark.playAnim(dad.animation.name, true);

			if (!checkNullAnim(dadDark, dad))
				dadDark.animation.curAnim.curFrame = dad.animation.curAnim.curFrame;
		}

		if (gfDark != null) {
			if (gfDark.animation.name != gf.animation.name)
				gfDark.playAnim(gf.animation.name, true);

			if (!checkNullAnim(gfDark, gf))
				gfDark.animation.curAnim.curFrame = gf.animation.curAnim.curFrame;
		}

		for (sprite in lightList) {
			sprite.alpha -= elapsed / 2;
		}
	}

	inline function checkNullAnim(obj1:FlxSprite, obj2:FlxSprite) {
		return obj1.animation.curAnim?.curFrame == null || obj2.animation.curAnim?.curFrame == null;
	}

	function lightningStrikeShit():Void
	{
		FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
		if(!ClientPrefs.data.lowQuality) {
			for (sprite in lightList) {
				sprite.alpha = 1;
			}
		}

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		if(boyfriend.animOffsets.exists('scared')) {
			boyfriend.playAnim('scared', true);
		}

		if(dad.animOffsets.exists('scared')) {
			dad.playAnim('scared', true);
		}

		if(gf != null && gf.animOffsets.exists('scared')) {
			gf.playAnim('scared', true);
		}

		if (ClientPrefs.data.camZooms) {
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;

			if(!game.camZooming) { //Just a way for preventing it to be permanently zoomed until Skid & Pump hits a note
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.5);
				FlxTween.tween(camHUD, {zoom: 1}, 0.5);
			}
		}
	}
}