package online.util;

import flixel.math.FlxPoint;
import flixel.text.FlxBitmapFont;


class Fonts {
    public static function getTardlingFont(?suffix:String = '') {
		return FlxBitmapFont.fromMonospace(Paths.image('resultScreen/tardlingSpritesheet' + suffix),
        "AaBbCcDdEeFfGgHhiIJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz:1234567890 "
		, FlxPoint.get(49, 62));
    }
}