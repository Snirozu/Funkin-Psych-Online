package online.gui;

import openfl.Lib;
import openfl.Assets;
import openfl.text.TextFormat;
import openfl.text.TextField;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.display.Sprite;

@:access(online.gui.Alert)
class AlertMessage extends Sprite implements IMousable {
	final MAX_WIDTH:Float = 600;
	public var bg:Bitmap;
	var bar:Bitmap;
    var title:TextField;
    var content:TextField;

	var freeze:Bool = false;
    var displayTime:Float = 0;
    var _targetAlpha:Float = 0;
	
	var onClick:Void->Void;

    public function new() {
        super();

		bg = new Bitmap(new BitmapData(1, 1, true, 0xFF000000));
        addChild(bg);

		bar = new Bitmap(new BitmapData(1, 5, true, 0xFFFFFFFF));
        addChild(bar);

		title = new TextField();
		title.selectable = false;
		title.multiline = true;
		title.defaultTextFormat = new TextFormat(Assets.getFont('assets/fonts/vcr.ttf').fontName, 18, 0xFFFFFFFF);
		title.antiAliasType = ADVANCED;
		title.embedFonts = true;
		addChild(title);

		content = new TextField();
		content.selectable = false;
		content.multiline = true;
		content.defaultTextFormat = new TextFormat(Assets.getFont('assets/fonts/vcr.ttf').fontName, 15, 0xFFFFFFFF);
		content.antiAliasType = ADVANCED;
		content.embedFonts = true;
		addChild(content);

		create();
    }

	// for recycling
	public function create(?titleText:String, ?messageText:String, ?onClick:Void->Void) {
		this.onClick = onClick;
		freeze = false;

		title.setText(ShitUtil.wordWrapText(titleText, 55), MAX_WIDTH - title.x * 2);
		content.setText(ShitUtil.wordWrapText(messageText, 55), MAX_WIDTH - title.x * 2);
		
		title.x = 10;
		content.x = title.x;

		title.y = 10;
		content.y = title.y + title.getTextHeight() + 10;

		bg.alpha = 0.8;
		bg.scaleX = Math.max(title.getTextWidth(), content.getTextWidth()) + 20;
		if ((messageText ?? '').trim().length == 0 || content.getTextHeight() == 0)
			bg.scaleY = title.y + title.getTextHeight() + 25;
		else
			bg.scaleY = content.y + content.getTextHeight() + 25;

		bar.y = bg.scaleY - 5;
		bar.scaleX = _targetAlpha / displayTime * bg.scaleX;

		displayTime = Math.min(5 + (titleText.length + messageText.length) * 0.05, 20);
		_targetAlpha = displayTime;

		return this;
	}

	private function mouseMove(event:MouseEvent) {
		freeze = this.overlapsMouse();
		if (freeze)
			_targetAlpha = displayTime;

	}
	private function mouseDown(event:MouseEvent) {
		if (this.overlapsMouse()) {
			if (onClick != null)
				onClick();
			kill();
		}
	}

	override function __enterFrame(delta) {
        super.__enterFrame(delta);

		if (delta > 500)
			return;

		if (_targetAlpha > 0. && !freeze)
			_targetAlpha -= delta * 0.001;

		bar.scaleX = _targetAlpha / displayTime * bg.scaleX;
		alpha = _targetAlpha;

		if (_targetAlpha <= 0)
			kill();
    }

	public function kill() {
		parent.removeChild(this);
		Alert.trashedObjects.push(this);
	}
}

class Alert extends Sprite {
	static var instance:Alert;
	static var trashedObjects:Array<AlertMessage> = [];

	public function new() {
        super();

		instance = this;

		if (Main.LOW_STORAGE) alert(haxe.crypto.Base64.decode('UlVOTklORyBPTiBBIFVOT0ZGSUNJQUwgQlVJTEQhISEh').toString());

		if (stage != null)
			init();
		else
			addEventListener(Event.ADDED_TO_STAGE, init);
	}

	function init(?e:Event) {
		stage.addEventListener(MouseEvent.MOUSE_MOVE, (e:MouseEvent) -> {
			for (child in __children) {
				if (child is IMousable)
					(cast child).mouseMove(e);
			}
		});
		stage.addEventListener(MouseEvent.MOUSE_DOWN, (e:MouseEvent) -> {
			for (child in __children) {
				if (child is IMousable)
					(cast child).mouseDown(e);
			}
		});
	}

	public static function alert(title:String, ?message:String, ?onClick:Void->Void) {
		if (title.startsWith("RUNNING ON A UNOFFICIAL BUILD"))
			Main.UNOFFICIAL_BUILD = true;

		if (trashedObjects.length <= 0) {
			trashedObjects.push(new AlertMessage());
		}

		instance.addChild(trashedObjects.pop().create(title, message, onClick));
	}

	public static function isAnyFreezed() {
		if (instance == null) return false;
		for (child in instance.__children) {
			if (child is AlertMessage && (cast child).freeze)
				return true;
		}
		return false;
	}

	var _lastY:Float = 0;
	override function __enterFrame(delta) {
		super.__enterFrame(delta);

		_lastY = Lib.application.window.height - 10;
		for (child in __children) {
			if (!(child is AlertMessage)) {
				continue;
			}

			var msg:AlertMessage = cast child; 
			msg.x = Lib.application.window.width - msg.bg.scaleX - 10;
			_lastY -= msg.bg.scaleY;
			msg.y = _lastY;
			_lastY -= 10;
		}
	}
}

@:allow(online.gui.Alert)
interface IMousable {
	private function mouseDown(event:MouseEvent):Void;
	private function mouseMove(event:MouseEvent):Void;
}