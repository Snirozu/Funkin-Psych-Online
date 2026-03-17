package online.s3d.objects;

import away3d.cameras.Camera3D;
import openfl.Lib;
import openfl.events.MouseEvent;
import openfl.events.KeyboardEvent;
import openfl.events.Event;
import openfl.display.Sprite;

class PersonCameraController extends flx3d.util.PersonCameraController {
	override function get_focused() {
		if (online.gui.sidebar.SideUI.instance?.active || Lib.current.stage.focus != null)
			return false;
		return enabled;
	}
}