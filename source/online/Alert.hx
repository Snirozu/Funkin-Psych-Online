package online;

import openfl.Lib;
import openfl.Assets;
import openfl.text.TextFormat;
import openfl.text.TextField;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.display.Sprite;

class Alert extends Sprite {
    static var bg:Bitmap;
    static var text:TextField;
    static var _targetAlpha:Float = 0;
    static var instance:Alert;

    public function new() {
        super();

        instance = this;

		bg = new Bitmap(new BitmapData(1, 1, true, 0xFF000000));
		bg.alpha = 0.6;
        addChild(bg);

		text = new TextField();
		text.selectable = false;
		text.defaultTextFormat = new TextFormat(Assets.getFont('assets/fonts/vcr.ttf').fontName, 20, 0xFFFFFFFF);
		addChild(text);

		_targetAlpha = 0;
    }

    public static function alert(title:String, ?message:String) {
		text.text = title + (message != null ? "\n\n" + message : "") + "\n\n"; // openfl bugs lol
		text.width = text.textWidth;
		text.height = text.textHeight;

		bg.scaleX = text.width + 50;
		bg.scaleY = text.height + 50;

		bg.x = Lib.application.window.width / 2 - bg.scaleX / 2;
		text.x = Lib.application.window.width / 2 - text.width / 2;
        text.y = bg.scaleY / 2 - text.height / 2;

		_targetAlpha = 5;
    }

    override function __enterFrame(delta) {
        super.__enterFrame(delta);

		if (_targetAlpha > 0.)
			_targetAlpha -= delta * 0.001;

		alpha = _targetAlpha;
    }
}