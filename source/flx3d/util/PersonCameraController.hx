package flx3d.util;

import away3d.cameras.Camera3D;
import flixel.FlxG;
import flixel.math.FlxMath;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;

class PersonCameraController extends Sprite {
    @:isVar public var focused(get, set):Bool;
    @:isVar public var enabled(default, set):Bool = true;
    public var camera:Camera3D;
	var _lastCursorVisible:Bool = false;

	public function new(camera:Camera3D) {
		super();

		this.camera = camera;

		if (stage != null)
			init();
		else
			addEventListener(Event.ADDED_TO_STAGE, init);
	}

	private function init(?_:Event):Void {
		stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		stage.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);

		addEventListener(Event.REMOVED_FROM_STAGE, _ -> {
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			stage.removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
		});
    }

	function onMouseOut(e:MouseEvent) {
		focused = false;
	}

	function onMouseMove(e:MouseEvent) {
		if (!focused)
			return;

		camera.rotationY += (Lib.current.mouseX - Lib.application.window.width / 2) / 10;
		camera.rotationX += (Lib.current.mouseY - Lib.application.window.height / 2) / 10;

		wrapCameraRotation();
		centerMouse();
	}

	function centerMouse() {
		Lib.application.window.warpMouse(Std.int(Lib.application.window.width / 2), Std.int(Lib.application.window.height / 2));
	}

	override function __enterFrame(_delta:Int) {
		super.__enterFrame(_delta);

		wrapCameraRotation();

		if (focused && FlxG.keys.pressed.ESCAPE) {
			focused = false;
		}
		if (!focused && FlxG.mouse.justPressed) {
			focused = true;
		}

		if (!focused)
			return;

		if (FlxG.keys.pressed.SPACE) {
			camera.y += 3;
		}
		if (FlxG.keys.pressed.SHIFT) {
			camera.y -= 3;
		}

		if (FlxG.keys.pressed.W) {
			move(camera.rotationY, false);
		}
		if (FlxG.keys.pressed.S) {
			move(camera.rotationY, true);
		}

		if (FlxG.keys.pressed.D) {
			move(camera.rotationY + 90, false);
		}
		if (FlxG.keys.pressed.A) {
			move(camera.rotationY + 90, true);
        }
    }

	public function move(angleDeg:Float, isNegative:Bool) {
		camera.x += Math.sin(radians(angleDeg)) * (isNegative ? -3.0 : 3.0);
		camera.z += Math.cos(radians(angleDeg)) * (isNegative ? -3.0 : 3.0);
	}

	public static function radians(value:Float) {
		return value * Math.PI / 180;
	}

	// away doesn't wrap angles so they can exceed (-)360 degrees
	static function wrapDegreesCloserToZero(v:Float) {
		var v1 = v % 360;
		if (v1 < -180)
			return v1 + 360;
		if (v1 > 180)
			return v1 - 360;
		return v1;
	}

	function wrapCameraRotation() {
		camera.rotationX = FlxMath.bound(camera.rotationX, -90, 90);
		camera.rotationY = wrapDegreesCloserToZero(camera.rotationY);
	}

	function set_enabled(v) {
		if (!v)
			focused = false;
		return enabled = v;
	}

	function get_focused() {
		if (Lib.current.stage.focus != null)
			return false;
		return focused && enabled;
	}

	function set_focused(v) {
		if (!enabled)
			return focused = false;

		if (v)
			centerMouse();
		_lastCursorVisible = FlxG.mouse.visible;
		FlxG.mouse.visible = !_lastCursorVisible ? false : !v;
		// Lib.application.window.mouseLock = v;
		return focused = v;
	}
}