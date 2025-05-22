package online.objects;

import flixel.group.FlxGroup;
import flixel.effects.FlxFlicker;
import flixel.FlxObject;
import flixel.FlxBasic;

class DebugPosHelper extends FlxTypedGroup<FlxBasic> {
	var text:FlxText;

    public var editMode(default, set):Bool = false;
	function set_editMode(v) {
		text.visible = v;
		return editMode = v;
	}
    var curObject:Int = 0;
	var offsetMode:Bool = false;

	public var target(default, set):Array<FlxBasic>;
	function set_target(v) {
		curObject = 0;
		return target = v;
	}

	public function new() {
        super();

		target = FlxG.state.members;

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
        }

        if (!editMode)
            return;

		text.x = FlxG.width - text.width - 10;
		if (target == null) {
			text.text = '(EDIT MODE)\nNULL TARGET!';
			return;
		}
		if (target.length < 1) {
			text.text = '(EDIT MODE)\nTARGET HAS NO MEMBERS!';
			return;
		}
		text.text = '(EDIT MODE)\ni: $curObject';

        //maybe disable flixel inputs and listen to openfl? but it's cur not needed...

		if (FlxG.keys.justPressed.TAB) {
			if (FlxG.keys.pressed.CONTROL)
				offsetMode = !offsetMode;
			else if (FlxG.keys.pressed.SHIFT)
				curObject--;
			else
				curObject++;
		}

		if (curObject < 0)
			curObject = target.length - 1;
		if (curObject > target.length - 1)
			curObject = 0;

		if (target[curObject] is FlxObject) {
			var obj:FlxObject = cast target[curObject];
			var sprite:FlxSprite = null;
			if (obj is FlxSprite) {
				sprite = cast(obj);
			}

			if (FlxG.keys.justPressed.TAB) {
                FlxFlicker.flicker(obj, 0.2, 0.05);
            }
            
            var shiftMult = FlxG.keys.pressed.SHIFT ? 300 : 50;
            if (FlxG.keys.pressed.UP) {
				if (!offsetMode)
					obj.y -= elapsed * shiftMult;
				else if (sprite != null)
					sprite.offset.y += elapsed * shiftMult;
			}
			if (FlxG.keys.pressed.DOWN) {
				if (!offsetMode)
					obj.y += elapsed * shiftMult;
				else if (sprite != null)
					sprite.offset.y -= elapsed * shiftMult;
			}

			if (FlxG.keys.pressed.CONTROL) {
				if (FlxG.keys.pressed.LEFT)
					obj.angle -= elapsed * shiftMult / 2;
				if (FlxG.keys.pressed.RIGHT)
					obj.angle += elapsed * shiftMult / 2;
			}
			else {
				if (FlxG.keys.pressed.LEFT) {
					if (!offsetMode)
						obj.x -= elapsed * shiftMult;
					else if (sprite != null)
						sprite.offset.x += elapsed * shiftMult;
				}
				if (FlxG.keys.pressed.RIGHT) {
					if (!offsetMode)
						obj.x += elapsed * shiftMult;
					else if (sprite != null)
						sprite.offset.x -= elapsed * shiftMult;
				}
			}
			

			if (FlxG.keys.justPressed.SPACE && sprite != null && sprite.animation?.curAnim != null)
				sprite.animation.curAnim.restart();
            if (FlxG.keys.justPressed.DELETE)
                FlxG.resetState();
            
			if (!offsetMode)
				text.text = '(EDIT MODE)\ni: $curObject\nX: ${obj.x}\nY: ${obj.y}\nA: ${obj.angle}';
			else if (sprite != null)
				text.text = '(EDIT MODE)\ni: $curObject\nOX: ${sprite.offset.x}\nOY: ${sprite.offset.y}\nA: ${obj.angle}';
			if (FlxG.keys.justPressed.F11)
				trace(text.text);
        }
    }
}