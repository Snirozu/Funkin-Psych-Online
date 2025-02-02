package online.objects;

import flixel.effects.FlxFlicker;
import flixel.FlxObject;
import flixel.FlxBasic;
import flixel.group.FlxContainer;

class DebugPosHelper extends FlxTypedGroup<FlxBasic> {
	var text:FlxText;

    var editMode:Bool = false;
    var curObject:Int = 0;

	public function new() {
        super();

        text = new FlxText(10, 10);
		text.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        text.text = '...';
        text.scrollFactor.set(0, 0);
		text.visible = false;
        add(text);
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

		if (FlxG.keys.justPressed.F12) {
			editMode = !editMode;

			text.visible = editMode;
        }

        if (!editMode)
            return;

		text.x = FlxG.width - text.width - 10;
		text.text = '(EDIT MODE)\ni: $curObject';

        //maybe disable flixel inputs and listen to openfl? but it's cur not needed...

		if (FlxG.keys.justPressed.TAB) {
			if (FlxG.keys.pressed.SHIFT)
				curObject--;
			else
				curObject++;

			if (curObject < 0)
				curObject = container.members.length - 1;
			if (curObject > container.members.length - 1)
				curObject = 0;
		}

		if (container.members[curObject] is FlxObject) {
			var obj:FlxObject = cast container.members[curObject];

			if (FlxG.keys.justPressed.TAB) {
                FlxFlicker.flicker(obj, 0.2, 0.05);
            }
            
            var shiftMult = FlxG.keys.pressed.SHIFT ? 300 : 50;
            if (FlxG.keys.pressed.UP)
				obj.y -= elapsed * shiftMult;
			if (FlxG.keys.pressed.DOWN)
				obj.y += elapsed * shiftMult;

			if (FlxG.keys.pressed.CONTROL) {
				if (FlxG.keys.pressed.LEFT)
					obj.angle -= elapsed * shiftMult / 2;
				if (FlxG.keys.pressed.RIGHT)
					obj.angle += elapsed * shiftMult / 2;
			}
			else {
				if (FlxG.keys.pressed.LEFT)
					obj.x -= elapsed * shiftMult;
				if (FlxG.keys.pressed.RIGHT)
					obj.x += elapsed * shiftMult;
			}
			

			if (FlxG.keys.justPressed.SPACE && obj is FlxSprite && cast(obj, FlxSprite).animation?.curAnim != null)
				cast(obj, FlxSprite).animation.curAnim.restart();
            if (FlxG.keys.justPressed.DELETE)
                FlxG.resetState();
            
			text.text = '(EDIT MODE)\ni: $curObject\nX: ${obj.x}\nY: ${obj.y}\nA: ${obj.angle}';
			if (FlxG.keys.justPressed.F11)
				trace(text.text);
        }
    }
}