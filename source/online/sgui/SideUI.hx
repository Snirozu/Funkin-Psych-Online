package online.sgui;

import flixel.FlxG;
import flixel.util.FlxColor;
import openfl.Lib;

class SideUI extends Sprite {
	public var shown(default, set):Bool;
	public var cursor:Bitmap;

	var _wasMouseShown:Bool = false;

	var curTab:TabSprite = null;

	public function new() {
		super();

		if (stage != null)
			init();
		else
			addEventListener(Event.ADDED_TO_STAGE, init);
	}

	function init(?e:Event) {
		var bitmap = new Bitmap(new BitmapData(500, Lib.application.window.height, true, FlxColor.fromRGB(0, 0, 0, 190)));
		addChild(bitmap);

		cursor = new Bitmap(new GraphicCursor(0, 0));
		cursor.visible = false;
		stage.addChild(cursor);

		alpha = 0;
		x = -width;


		stage.addEventListener(KeyboardEvent.KEY_DOWN, (e:KeyboardEvent) -> {
			if (e.keyCode == 192) {
				shown = !shown;
			}
			
			if (shown)
				curTab.keyDown(e);
		});
		stage.addEventListener(MouseEvent.MOUSE_MOVE, (e:MouseEvent) -> {
			cursor.x = e.stageX;
			cursor.y = e.stageY;

			if (shown)
				curTab.mouseMove(e);
		});
		stage.addEventListener(MouseEvent.MOUSE_DOWN, (e:MouseEvent) -> {
			if (e.localX >= width)
				shown = false;

			if (shown)
				curTab.mouseDown(e);
		});

		curTab = new MainTab(bitmap.width);
	}

	function set_shown(show:Bool) {
		if (show == shown)
			return shown;

		Actuate.stop(this);

		FlxG.mouse.enabled = !show;
		FlxG.keys.enabled = !show;
		cursor.visible = show;

		if (show) {
			addChild(curTab);
			_wasMouseShown = FlxG.mouse.visible;
			FlxG.mouse.visible = false;

			Actuate.tween(this, 1, {alpha: 1, x: 0});
		}
		else {
			FlxG.mouse.visible = _wasMouseShown;

			Actuate.tween(this, 1, {alpha: 0, x: -width}).onComplete(() -> {
				removeChild(curTab);
			});
		}
		return shown = show;
	}
}

@:bitmap("assets/images/ui/cursor.png")
private class GraphicCursor extends BitmapData {}
