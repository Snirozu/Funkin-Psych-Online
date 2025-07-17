package online.flx3d;

import away3d.containers.View3D;
import openfl.events.Event;
import openfl.display.StageAlign;
import openfl.display.StageScaleMode;
import openfl.events.Event;
import online.away.PersonCameraController;
import openfl.Lib;
import away3d.containers.ObjectContainer3D;
import flixel.input.keyboard.FlxKey;
import flixel.FlxState;
import tea.SScript;
import sys.io.File;
import sys.FileSystem;
import away3d.cameras.lenses.PerspectiveLens;

// state for testing

class FlxScriptedState3D extends FlxState3D {
	public var camera3DController:PersonCameraController;
	public var camera3DLens:PerspectiveLens;

	override function create() {
		super.create();

		FlxG.mouse.visible = false;

		FlxG.cameras.reset(new FlxCamera());
		FlxG.camera.bgColor = FlxColor.TRANSPARENT;

		view3D.addChild(camera3DController = new PersonCameraController(view3D.camera));
		view3D.camera.lens = camera3DLens = new PerspectiveLens(60);
		camera3DLens.far = 10000;

		setupScript('test3d.hx');
		dispatch('create');
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		dispatch('update', [elapsed]);

		if (FlxG.keys.justPressed.ESCAPE) {
			FlxG.switchState(() -> new states.MainMenuState());
		}
		if (FlxG.keys.justPressed.DELETE) {
			FlxG.switchState(() -> new FlxScriptedState3D());
		}
	}

	override function destroy() {
		dispatch('destroy');
		script.destroy();
		script = null;

		super.destroy();
	}

	function setupScript(file:String) {
		var scriptToLoad:String = Paths.modFolders(file);
		if (!FileSystem.exists(scriptToLoad))
			scriptToLoad = Paths.getPreloadPath(file);

		if (FileSystem.exists(scriptToLoad)) {
			initScript(scriptToLoad);
			return true;
		}
		return false;
	}

	@:unreflective
	var script:SScript;
	function initScript(path:String) {
		trace(path);
		script = new SScript(path);
		script.set("this", this);
		script.set("print", s -> Sys.println(s));
		script.set("typeof", s -> Type.getClassName(Type.getClass(s)));
		script.set("alert", (title, ?message) -> Alert.alert(title, message));
		for (cls in CompileTime.getAllClasses('away3d')) {
			if (cls == null)
				continue;
			script.set(Type.getClassName(cls).split('.').pop(), cls);
		}
		for (block in Deflection.classBlacklist) {
			script.notAllowedClasses.push(block);
		}
	}

	function dispatch(func:String, ?args:Array<Any>) {
		if (script != null && @:privateAccess !script._destroyed) {
			return script.call(func, args).returnValue;
		}
		return null;
	}
}