package states.stages;

import states.stages.objects.*;

class StageErect extends BaseStage
{
	override function create()
	{
		var back:BGSprite = new BGSprite('erect/backDark', 729, -170, 1, 1);
		add(back);

		var crowd:BGSprite = new BGSprite('erect/crowd', 560, 290, 0.8, 0.8, ['Symbol 2 instance 1'], true, 12);
		add(crowd);

		if (!ClientPrefs.data.lowQuality) {
            var lightSmall:BGSprite = new BGSprite('erect/brightLightSmall', 967, -103, 1.2, 1.2);
            add(lightSmall);
        }

		var bg:BGSprite = new BGSprite('erect/bg', -603, -277, 1, 1);
		bg.setGraphicSize(Std.int(bg.width * 1.1));
		bg.updateHitbox();
		add(bg);

		var server:BGSprite = new BGSprite('erect/server', -361, 215, 1, 1);
		add(server);

		if (!ClientPrefs.data.lowQuality) {
            var greenLight:BGSprite = new BGSprite('erect/lightgreen', -171, 242, 1, 1);
            add(greenLight);

            // haha scuid games
            var redLight:BGSprite = new BGSprite('erect/lightred', -101, 560, 1, 1);
            add(redLight);

            var orangeLight:BGSprite = new BGSprite('erect/orangeLight', 189, -195, 1, 1);
            add(orangeLight);
        }
	}

	override function createPost() {
		var lights:BGSprite = new BGSprite('erect/lights', -601, -147, 1.2, 1.2);
		add(lights);

		if (!ClientPrefs.data.lowQuality) {
			var lightAbove:BGSprite = new BGSprite('erect/lightAbove', 804, -117, 1, 1);
			add(lightAbove);
		}
	}
}