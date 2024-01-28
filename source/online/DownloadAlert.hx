package online;

import openfl.Lib;
import openfl.Assets;
import openfl.text.TextFormat;
import openfl.text.TextField;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.display.Sprite;

@:allow(online.DownloadAlert)
class DownloadAlerts extends Sprite {
	static var instance:DownloadAlerts ;
	static var instances:Array<DownloadAlert> = [];

	public function new() {
		super();
		
		instance = this;
	}

	override function __enterFrame(delta) {
		super.__enterFrame(delta);

		var prevAlert:DownloadAlert = null;
		for (alert in instances) {
			if (prevAlert != null)
				alert.y = prevAlert.y + prevAlert.bg.height + 10;
			else
				alert.y = 0;
			alert.x = Lib.application.window.width - alert.width;

			prevAlert = alert;
		}
	}
}

class DownloadAlert extends Sprite {
	public var bg:Bitmap;
	public var bar:Bitmap;
	public var text:TextField;
	var id:String;

    public function new(id:String) {
        super();

		this.id = id;

		DownloadAlerts.instances.push(this);
		DownloadAlerts.instance.addChild(this);

		bg = new Bitmap(new BitmapData(600, 70, true, 0xFF000000));
		bg.alpha = 0.6;
        addChild(bg);

		bar = new Bitmap(new BitmapData(1, 5, true, 0xFFFFFFFF));
		addChild(bar);

		text = new TextField();
		text.text = 'Waiting to download: $id';
		text.selectable = false;
		text.defaultTextFormat = new TextFormat(Assets.getFont('assets/fonts/vcr.ttf').fontName, 15, 0xFFFFFFFF);
		addChild(text);

		text.y = 5;
		text.wordWrap = true;
		text.width = bg.width - text.y * 2;

		bar.y = bg.y + bg.height - 10;
		text.x = 10;
		bar.x = 10;

		bar.visible = false;
    }

    public function updateProgress(loaded:Float, total:Float) {
		if (text == null)
			return;
		
		bar.visible = true;
		text.text = 'Downloading $id: ${FlxMath.roundDecimal(loaded / 1000000, 1)}MB of ${FlxMath.roundDecimal(total / 1000000, 1)}MB';

		bar.scaleX = (bg.width - 20) * (loaded / total);
		// bar.x = bg.x + bg.width / 2 - bar.width / 2;
    }

	public function destroy() {
		bg = null;
		text = null;
		DownloadAlerts.instances.remove(this);
		DownloadAlerts.instance.removeChild(this);
	}

    override function __enterFrame(delta) {
        super.__enterFrame(delta);
    }
}