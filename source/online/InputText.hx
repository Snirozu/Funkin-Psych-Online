package online;

import flixel.addons.ui.FlxInputText;

class InputText extends FlxInputText {
    public function new(x:Float, y:Float, width:Float, onEnter:(text:String)->Void) {
        super(x, y, Std.int(width));

		backgroundColor = FlxColor.TRANSPARENT;
		fieldBorderColor = FlxColor.TRANSPARENT;
		caretColor = FlxColor.WHITE;

		callback = (text, action) -> {
            if (action == FlxInputText.ENTER_ACTION) {
				hasFocus = false; //allow event to overwrite it
				onEnter(text);
            }
        };
    }

    override function update(elapsed) {
        super.update(elapsed);

		if (hasFocus && (FlxG.keys.justPressed.ESCAPE || (FlxG.mouse.justPressed && !FlxG.mouse.overlaps(this)))) {
            hasFocus = false;
        }
    }
}