package online.gui.sidebar;

import online.network.FunkinNetwork;
import flixel.FlxG;
import flixel.util.FlxColor;
import openfl.Lib;

class SideUI extends Sprite {
	public static var instance:SideUI;

	public var active(default, set):Bool;
	public var cursor:Bitmap;

	var _wasMouseShown:Bool = false;

	public var curTab:TabSprite = null;

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
			if (e.keyCode == 192 && stage.focus == null) {
				if (FunkinNetwork.loggedIn) {
					active = !active;
					return;
				}
				else {
					Waiter.put(() -> {
						Alert.alert("Forbidden!", "Sidebar is only accessible for\npeople that are logged to the network!");
					});
				}
			}
			
			if (active)
				curTab.keyDown(e);
		});
		stage.addEventListener(MouseEvent.MOUSE_MOVE, (e:MouseEvent) -> {
			cursor.x = e.stageX;
			cursor.y = e.stageY;

			if (active)
				curTab.mouseMove(e);
		});
		stage.addEventListener(MouseEvent.MOUSE_DOWN, (e:MouseEvent) -> {
			if (e.localX >= (curTab?.widthTab ?? width))
				active = false;

			if (active)
				curTab.mouseDown(e);
		});
		stage.addEventListener(MouseEvent.MOUSE_WHEEL, (e:MouseEvent) -> {
			if (active)
				curTab.mouseWheel(e);
		});

		curTab = new MainTab(bitmap.width);

		instance = this;
	}

	function set_active(show:Bool) {
		if (show == active)
			return active;

		stage.focus = null;
		Actuate.stop(this);

		FlxG.mouse.enabled = !show;
		FlxG.keys.enabled = !show;
		cursor.visible = show;

		if (show) {
			addChild(curTab);
			curTab.onShow();
			_wasMouseShown = FlxG.mouse.visible;
			FlxG.mouse.visible = false;

			Actuate.tween(this, 1, {alpha: 1, x: 0});
		}
		else {
			FlxG.mouse.visible = _wasMouseShown;

			Actuate.tween(this, 1, {alpha: 0, x: -width}).onComplete(() -> {
				removeChild(curTab);
				curTab.onHide();
			});
		}
		return active = show;
	}
}

@:bitmap("assets/images/ui/cursor.png")
private class GraphicCursor extends BitmapData {}
