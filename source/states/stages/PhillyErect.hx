package states.stages;

import states.stages.objects.*;

class PhillyErect extends BaseStage {
	static var lightColors = [0xB66F43, 0x329A6D, 0x932C28, 0x2663AC, 0x502D64];
	var curLight:Int = 0;

	var lights:BGSprite;
	var phillyTrain:PhillyTrain;

	override function create() {
		var sky:BGSprite = new BGSprite('philly/erect/sky', -100, 0, 0.1, 0.1);
		add(sky);

		var city:BGSprite = new BGSprite('philly/erect/city', -10, 0, 0.3, 0.3);
		city.setGraphicSize(Std.int(city.width * 0.85));
		city.updateHitbox();
		add(city);

		lights = new BGSprite('philly/window', -10, 0, 0.3, 0.3);
		lights.setGraphicSize(Std.int(lights.width * 0.85));
		lights.updateHitbox();
		lights.alpha = 0;
		add(lights);

		var behindTrain:BGSprite = new BGSprite('philly/erect/behindTrain', -40, 50, 1, 1);
		add(behindTrain);

		phillyTrain = new PhillyTrain(2000, 360);
		add(phillyTrain);

		var street:BGSprite = new BGSprite('philly/erect/street', -40, 50, 1, 1);
		add(street);
	}

	override function createPost() {}

	override function update(elapsed:Float) {
		super.update(elapsed);

		lights.alpha -= (Conductor.crochet / 1000) * FlxG.elapsed * 1.5;
	}

	override function beatHit() {
		phillyTrain.beatHit(curBeat);

		if (curBeat % 4 == 0) {
			curLight = FlxG.random.int(0, lightColors.length - 1, [curLight]);
			lights.color = lightColors[curLight];
			lights.alpha = 1;
		}
	}
}