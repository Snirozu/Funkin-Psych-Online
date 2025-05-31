package online.away;

import openfl.display.BitmapData;
import backend.StageData;
import away3d.cameras.lenses.PerspectiveLens;
import online.away.StaticSprite3D;
import away3d.core.base.Object3D;
import online.away.AnimatedSprite3D;
import openfl.Assets;
import away3d.containers.*;
import openfl.geom.Vector3D;
import away3d.cameras.Camera3D;

class AwayStage3D extends ObjectContainer3D {
	var stageData:StageFile;
	
	var cameraPoints:Map<String, Object3DPose> = new Map();

	var camera(get, set):Camera3D;
	function get_camera() return Main.view3D.camera;
	function set_camera(v) return Main.view3D.camera = v;

	var cameraLens:PerspectiveLens;

	// stage data @:optional var objects:Array<Dynamic>;
	// but @:optional var objects3D:Array<Dynamic>;

	public function new() {
		super();
	}

	public function setup(stageData:StageFile) {
		this.stageData = stageData;
		stageData.stage3D.objects = cast ShitUtil.objToMap(stageData.stage3D.objects);
		stageData.stage3D.cameraPoints = cast ShitUtil.objToMap(stageData.stage3D.cameraPoints);

		camera.x = 52;
		camera.y = 109;
		camera.z = -675;

		camera.lens = cameraLens = new PerspectiveLens(60);
		cameraLens.far = 100000; // why would you care about render distance on sprites with like 2 triangles

		camera.lookAt(new Vector3D());
		camera.rotationX = 1;
		camera.rotationY = 0;

		_cameraFollow = new Object3D();

		for (objectName => object in stageData.stage3D.objects) {
			if (objectName == 'bf' || objectName == 'dad' || objectName == 'gf') {
				continue;
			}

			switch (object.type) {
				//planes
				case 'sprite':
					createSprite(objectName);
				case 'animatedSprite':
					createSprite(objectName, true);
				//models
				case '3ds':
					//TODO
			}
		}

		for (name => cameraPoint in stageData.stage3D.cameraPoints) {
			cameraPoints.set(name, cameraPoint);
		}

		setFollowCamera('gf', camera);
		setFollowCamera('gf');
	}

	public function createSprite(objectName:String, ?animated:Bool = false, ?bitmap:BitmapData):Any {
		var object = stageData.stage3D.objects.get(objectName);
		if (object == null) {
			trace('Object "${objectName}" not found in the Stage file!');
			return null;
		}

		var sprite = if (animated)
			new AnimatedSprite3D(object, bitmap)
		else
			new StaticSprite3D(object, bitmap);
		sprite.id = objectName;
		if (object.scale != null) {
			sprite.scaleX = object.scale ?? 1.0;
			sprite.scaleY = object.scale ?? 1.0;
		}
		setPositionFromArray(sprite, object.position);
		setRotationFromArray(sprite, object.rotation);
		addChild(sprite);

		return sprite;
	}

	var _cameraFollow:Object3D;

	public function setFollowCamera(char:String, ?object:Object3D) {
		object ??= _cameraFollow;

		var cameraPoint = cameraPoints.get(char);
		if (cameraPoint == null)
			return;

		setPositionFromArray(object, cameraPoint.position);
		setRotationFromArray(object, cameraPoint.rotation);
	}

	function setPositionFromArray(object:Object3D, pos:Array<Float>) {
		if (pos == null)
			return;

		object.x = pos[0];
		object.y = pos[1];
		object.z = pos[2];
	}

	function setRotationFromArray(object:Object3D, rot:Array<Float>) {
		if (rot == null)
			return;

		object.rotationX = rot[0];
		object.rotationY = rot[1];
		object.rotationZ = rot[2];
	}

	function lerpCameraVar(a:Float, b:Float) {
		// uses the camera lerp calc from psych engine v0.5
		return FlxMath.lerp(a, b, elapsed * 2.4 * PlayState.instance.cameraSpeed * PlayState.instance.playbackRate);
	}

	var elapsed:Float = 0;
	public function update(elapsed:Float) {
		this.elapsed = elapsed;

		camera.x = lerpCameraVar(camera.x, _cameraFollow.x);
		camera.y = lerpCameraVar(camera.y, _cameraFollow.y);
		camera.z = lerpCameraVar(camera.z, _cameraFollow.z);
		camera.rotationX = lerpCameraVar(camera.rotationX, _cameraFollow.rotationX);
		camera.rotationY = lerpCameraVar(camera.rotationY, _cameraFollow.rotationY);

		cameraLens.fieldOfView = 60 * FlxG.camera.zoom;
	}

	public function onDeath() {
		for (_ in 0...numChildren) {
			removeChildAt(0);
		}
	}
}