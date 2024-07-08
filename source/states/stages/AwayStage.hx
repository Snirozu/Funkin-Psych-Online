package states.stages;

import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.geom.Matrix;
import openfl.text.TextFormat;
import openfl.text.TextField;
import openfl.Assets;
import away3d.textures.Anisotropy;
import away3d.textures.BitmapTexture;
import away3d.containers.*;
import away3d.entities.*;
import away3d.materials.*;
import away3d.primitives.*;
import openfl.display.*;
import openfl.events.*;
import openfl.geom.Vector3D;

class AwayStage extends Sprite {
	var _view:View3D;

	var debugText:TextField;

	var walkway:Mesh;
	var school:Mesh;
	
	var dad:Mesh;

	var scaleSchool:Float = 0.38;

	var debugSprite:Int = 0;
	var debugSprites:Array<Mesh> = [];

	public function new() {
		super();

		addEventListener(Event.ADDED_TO_STAGE, init);
		FlxG.signals.preStateSwitch.add(resetScene);
	}

	private function init(_:Event):Void {
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;

		_view = new View3D();
		addChild(_view);

		_view.camera.y = 100;
		_view.camera.lookAt(new Vector3D());

		// other stuff

		debugText = new TextField();
		debugText.selectable = false;
		debugText.defaultTextFormat = new TextFormat(Assets.getFont('assets/fonts/vcr.ttf').fontName, 16, 0xFFFFFFFF);
		debugText.multiline = true;
		debugText.wordWrap = true;
		stage.addChild(debugText);

		addEventListener(Event.ENTER_FRAME, _onEnterFrame);
		stage.addEventListener(Event.RESIZE, onResize);
		onResize();
	}

	public function setupOnlineStage() {
		switch (PlayState.SONG.song.toLowerCase()) {
			case "thorns":
				// walkway
				var _plainBitmap = Assets.getBitmapData(Paths.getLibraryPathForce("images/weeb/evilWalkway.png", "week_assets", "week6"));
				var plainBitmap = new BitmapData(1024, 1024, FlxColor.TRANSPARENT); // why THE FUCK does it need to be a power of 2 value???
				plainBitmap.draw(_plainBitmap);

				var material = new TextureMaterial(new BitmapTexture(plainBitmap, false));
				material.repeat = false;
				material.mipmap = false;
				material.anisotropy = Anisotropy.NONE;
				material.smooth = false;
				material.alphaPremultiplied = false;
				material.alphaThreshold = 1;

				var geom = new PlaneGeometry(1024, 1024);
				walkway = new Mesh(geom, material);

				walkway.x = 355;
				walkway.y = 39;
				walkway.z = -840;

				_view.scene.addChild(walkway);

				// school
				var _plainBitmap = Assets.getBitmapData(Paths.getLibraryPathForce("images/weeb/evilSchool.png", "week_assets", "week6"));
				var plainBitmap = new BitmapData(1024, 1024, true, FlxColor.TRANSPARENT);
				plainBitmap.draw(_plainBitmap);

				var material = new TextureMaterial(new BitmapTexture(plainBitmap, false));
				material.repeat = false;
				material.mipmap = false;
				material.anisotropy = Anisotropy.NONE;
				material.smooth = false;
				material.alphaPremultiplied = false;
				material.alphaThreshold = 1;

				var geom = new PlaneGeometry(1024, 1024);
				geom.scaleUV(scaleSchool, scaleSchool);

				school = new Mesh(geom, material);

				school.x = 192;
				school.y = -264;
				school.z = -482;
				school.rotationX = -90;

				_view.scene.addChild(school);

				// a ghoul... hmmmmm...
				var plainBitmap = new BitmapData(1024, 1024, true, FlxColor.TRANSPARENT);
				PlayState.instance.dad.useFramePixels = true;

				var material = new TextureMaterial(new BitmapTexture(plainBitmap, false));
				material.repeat = false;
				material.mipmap = false;
				material.anisotropy = Anisotropy.NONE;
				material.smooth = false;
				material.alphaPremultiplied = false;
				material.alphaThreshold = 1;

				var geom = new PlaneGeometry(1024, 1024);

				dad = new Mesh(geom, material);

				dad.x = 399;
				dad.y = 761;
				dad.z = 1056;
				dad.rotationX = -90;

				_view.scene.addChild(dad);

				debugSprite = 0;
				debugSprites = [school, walkway, dad];

				// var cubeTexture:BitmapCubeTexture = new BitmapCubeTexture(
				// 	plainBitmap,
				// 	plainBitmap,
				// 	plainBitmap,
				// 	plainBitmap,
				// 	plainBitmap,
				// 	plainBitmap
				// );

				// var skyBox = new SkyBox(cubeTexture);
				// skyBox.uvTransform.scale(10, 10);
				// _view.scene.addChild(skyBox);
		}

		if (ClientPrefs.isDebug()) {
			try {
				stage.removeChild(debugText);
			}
			catch (_) {
			}
			stage.addChild(debugText);
		}
	}

	public function resetScene() {
		for (i in 0..._view.scene.numChildren) {
			if (_view.scene.getChildAt(i) != null)
				_view.scene.removeChildAt(0);
		}

		scaleSchool = 0.38;

		try {
			stage.removeChild(debugText);
		}
		catch (_) {
		}

		_view.render();
	}

	var _projectVector = new Vector3D();
	var _objectVector = new Vector3D();

	// public function projectTranslate(object:FlxObject) {
	// 	_objectVector.x = object.x * assScaleX;
	// 	_objectVector.z = object.y * assScaleY;
	// 	// _objectVector.y = -object.height;
	// 	_view.camera.project(_objectVector, _projectVector);

	// 	object.setPosition(_projectVector.x, _projectVector.y);
	// 	return;
	// }

	/**
	 * render loop
	 */
	private function _onEnterFrame(e:Event):Void {
		if (_view.scene.numChildren <= 0) {
			return;
		}

		if (dad != null && PlayState.instance?.dad != null) {
			drawSpriteOnMesh(dad, PlayState.instance.dad);
		}

		// _view.camera.x = FlxG.camera.scroll.x * scrollMult;
		// _view.camera.y = FlxG.camera.scroll.y * scrollMult;
		// // camera zooms
		// _view.camera.z = (FlxG.camera.zoom - 1) * (zoomMult + 200);

		if (ClientPrefs.isDebug()) {
			var moveSpeed = 0.01 * (FlxG.keys.pressed.CONTROL ? 10 : 1) * (FlxG.keys.pressed.ALT ? 100 : 1);

			if (FlxG.keys.justPressed.TAB) {
				debugSprite++;
				if (debugSprite >= debugSprites.length)
					debugSprite = 0;
			}

			var targetObject = debugSprites[debugSprite];
			if (targetObject != null) {		
				//_view.camera.lookAt(school.position);
				debugText.text = 'SPRITE: ${targetObject.originalName}\nX: ${targetObject.x}\nY: ${targetObject.y}\nZ: ${targetObject.z}\nSX: ${scaleSchool}';
				debugText.width = debugText.textWidth;
				debugText.height = debugText.textHeight;
			
				if (FlxG.keys.pressed.LBRACKET) {
					scaleSchool -= moveSpeed;
					school.geometry.scaleUV(scaleSchool, scaleSchool);
				}
				if (FlxG.keys.pressed.RBRACKET) {
					scaleSchool += moveSpeed;
					school.geometry.scaleUV(scaleSchool, scaleSchool);
				}

				if (FlxG.keys.pressed.K) {
					targetObject.z -= moveSpeed;
				}
				if (FlxG.keys.pressed.I) {
					targetObject.z += moveSpeed;
				}

				if (FlxG.keys.pressed.J) {
					targetObject.x -= moveSpeed;
				}
				if (FlxG.keys.pressed.L) {
					targetObject.x += moveSpeed;
				}

				if (FlxG.keys.pressed.O) {
					targetObject.y -= moveSpeed;
				}
				if (FlxG.keys.pressed.P) {
					targetObject.y += moveSpeed;
				}
			}
		}

		_view.render();
	}

	/**
	 * stage listener for resize events
	 */
	private function onResize(event:Event = null):Void {
		_view.width = stage.stageWidth;
		_view.height = stage.stageHeight;
	}

	var _rect = new Rectangle();
	var _point = new Point();
	
	function drawSpriteOnMesh(mesh:Mesh, sprite:FlxSprite) {
		// note: seems that sprite.frame.parent.bitmap fucks up rendering lol

		var fullBitmap = sprite.pixels;
		var targetBitmap = cast(cast(mesh.material, TextureMaterial).texture, BitmapTexture).bitmapData;
		var frame = sprite.frames.frames[sprite.animation.frameIndex];

		if (frame == null)
			return;

		//Sys.println(sprite.animation.frameIndex + " " + frame.frame.x + " " + frame.frame.y);
		//shows correct coordinates

		//should copy these pixels correctly, but it doesnt and stays on the first frame?????
		targetBitmap.copyPixels(fullBitmap, frame.frame.copyToFlash(_rect), frame.offset.copyToFlash(_point), null, null, true);
	}
}