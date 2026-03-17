package online.s3d;

import online.s3d.objects.PersonCameraController;
import openfl.display.BitmapData;
import backend.StageData;
import away3d.cameras.lenses.PerspectiveLens;
import online.s3d.objects.StaticSprite3D;
import away3d.core.base.Object3D;
import online.s3d.objects.AnimatedSprite3D;
import openfl.Assets;
import away3d.containers.*;
import openfl.geom.Vector3D;
import away3d.cameras.Camera3D;
import flx3d.FlxGroup3D;

class FunkinStage3D extends FlxGroup3D {
	var stageData:StageFile;
	
	var cameraPoints:Map<String, Object3DPose> = new Map();
	var cameraLens:PerspectiveLens;

	var debugMode:Bool = false;

	var view2:View3DHandler;

	// stage data @:optional var objects:Array<Dynamic>;
	// but @:optional var objects3D:Array<Dynamic>;

	public function new(?stageData:StageFile) {
		//override existing view3d
		view = view2 = new View3DHandler();

		super();

		this.stageData = stageData;

		view.camera.x = 52;
		view.camera.y = 109;
		view.camera.z = -675;

		view.camera.lens = cameraLens = new PerspectiveLens(60);
		cameraLens.far = 100000; // why would you care about render distance on sprites with like 2 triangles

		view.camera.lookAt(new Vector3D());
		view.camera.rotationX = 1;
		view.camera.rotationY = 0;

		_cameraFollow = new Object3D();

		if (stageData == null)
			return;

		stageData.stage3D.objects = cast ShitUtil.objToMap(stageData.stage3D.objects);
		stageData.stage3D.cameraPoints = cast ShitUtil.objToMap(stageData.stage3D.cameraPoints);
		
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

		setFollowCamera('gf', view.camera);
		setFollowCamera('gf');
	}

	public static function load(stageData:StageFile):FunkinStage3D {
		if (stageData?.stage3D == null) {
			return null;
		}
		return new FunkinStage3D(stageData);
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
		view.scene.addChild(sprite);

		return sprite;
	}

	var _cameraFollow:Object3D;

	var _cameraPointAlts:Map<String, Array<String>> = new Map();

	public function setFollowCamera(char:String, ?object:Object3D) {
		object ??= _cameraFollow;

		var cameraPoint = cameraPoints.get(char);
		if (cameraPoint == null)
			return;

		if (cameraPoint.alts != null) {
			if (!_cameraPointAlts.exists(char)) {
				_cameraPointAlts.set(char, [char].concat(cameraPoint.alts));
			}

			final altName = FlxG.random.getObject(_cameraPointAlts.get(char));
			final newCameraPoint = cameraPoints.get(altName);
			if (newCameraPoint != null)
				cameraPoint = newCameraPoint;

			if (ClientPrefs.isDebug())
				trace("targeting alt point: " + altName);
		}

		setPositionFromArray(object, cameraPoint.position);
		setRotationFromArray(object, cameraPoint.rotation);
	}

	public function setPositionFromArray(object:Object3D, pos:Array<Float>) {
		if (pos == null)
			return;

		object.x = pos[0];
		object.y = pos[1];
		object.z = pos[2];
	}

	public function setRotationFromArray(object:Object3D, rot:Array<Float>) {
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
	override function update(elapsed:Float) {
		super.update(elapsed);
		this.elapsed = elapsed;

		view.camera.x = lerpCameraVar(view.camera.x, _cameraFollow.x);
		view.camera.y = lerpCameraVar(view.camera.y, _cameraFollow.y);
		view.camera.z = lerpCameraVar(view.camera.z, _cameraFollow.z);
		view.camera.rotationX = lerpCameraVar(view.camera.rotationX, _cameraFollow.rotationX);
		view.camera.rotationY = lerpCameraVar(view.camera.rotationY, _cameraFollow.rotationY);

		cameraLens.fieldOfView = 60 * FlxG.camera.zoom;
	}

	public function onDeath() {
		for (_ in 0...view.scene.numChildren) {
			view.scene.removeChildAt(0);
		}
	}
}