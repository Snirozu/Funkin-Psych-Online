package online.away;

import backend.StageData;
import away3d.textures.BitmapCubeTexture;
import openfl.Lib;
import openfl.ui.Keyboard;
import away3d.core.base.Object3D;
import openfl.text.TextFormat;
import openfl.text.TextField;
import openfl.Assets;
import away3d.containers.*;
import away3d.primitives.*;
import openfl.display.*;
import openfl.events.*;
import away3d.cameras.Camera3D;

class View3DHandler extends View3D {
	var skyboxTexture:BitmapCubeTexture;
	var _skyBox:SkyBox;
	static var debugText:TextField;
	public static var stageScene:AwayStage3D;

	public var onDebug:Bool->Void = null;

	public var debugMode(default, set):Bool = false;
	function set_debugMode(v) {
		debugMode = v;
		updateDebugMode();
		if (onDebug != null)
			onDebug(debugMode);
		return debugMode;
	}
	var freeCam:Bool = false; 
	var debugSprite:Int = 0;
	var _keysJustPressed:Array<Int> = [];

	public function new() {
		super();

		width = FlxG.width;
		height = FlxG.height;
		backgroundAlpha = 0;

		if (stage != null)
			init();
		else
			addEventListener(Event.ADDED_TO_STAGE, init);
	}

	private function init(?_:Event):Void {
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP;

		debugText = new TextField();
		debugText.selectable = false;
		debugText.defaultTextFormat = new TextFormat(Assets.getFont('assets/fonts/vcr.ttf').fontName, 16, 0xFFFFFFFF);
		debugText.multiline = true;
		debugText.wordWrap = false;
		debugText.visible = false;
		addChild(debugText);

		// here lies the skybox which fucking died for no reason in the middle of programming this stage
		// skyboxTexture = new BitmapCubeTexture(
		// 	GAssets.image("skybox_positive_x"),
		// 	GAssets.image("skybox_negative_x"),
		// 	GAssets.image("skybox_positive_y"),
		// 	GAssets.image("skybox_negative_y"),
		// 	GAssets.image("skybox_positive_z"),
		// 	GAssets.image("skybox_negative_z")
		// );

		// ... but it's still needed because other assets would flicker lol
		// if there's no skybox (even though it's NOT visible) the stage glitches but it only happens while flixel is active so guess what can i blame for that
		var blankBitmap:BitmapData = new BitmapData(1, 1, false, 0x000000);
		skyboxTexture = new BitmapCubeTexture(
			blankBitmap,
			blankBitmap,
			blankBitmap,
			blankBitmap,
			blankBitmap,
			blankBitmap
		);
		
		_skyBox = new SkyBox(skyboxTexture);
		_skyBox.id = 'skybox';
		scene.addChild(_skyBox);

		stage.addEventListener(Event.RESIZE, onResize);
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		// addEventListener(Event.REMOVED, (e) -> {
		// 	stage.removeEventListener(Event.RESIZE, onResize);
		// 	stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		// 	stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		// });

		FlxG.signals.preStateSwitch.add(() -> {
			removeScene();
		});

		onResize();
	}

	function onKeyDown(e:KeyboardEvent) {
		if (stageScene == null) {
			return;
		}

		if (!_keysJustPressed.contains(e.keyCode))
			_keysJustPressed.push(e.keyCode);
	}

	function onMouseMove(e:MouseEvent) {
		if (!freeCam)
			return;

		camera.rotationY += (Lib.current.mouseX - Lib.application.window.width / 2) / 10;
		camera.rotationX += (Lib.current.mouseY - Lib.application.window.height / 2) / 10;
		//Lib.application.window.mouseLock = true;

		Lib.application.window.warpMouse(Std.int(Lib.application.window.width / 2), Std.int(Lib.application.window.height / 2));
	}

	function updateDebugMode() {
		debugText.visible = debugMode;
		// if (_skyBox != null) {
		// 	_skyBox.visible = debugMode;
		// }

		if (!debugMode) {
			freeCam = false;
		}
	}

	public function setupScene(stageData:StageFile) {
		removeScene();
		camera = new Camera3D();
		scene.addChild(stageScene = new AwayStage3D());
		stageScene.setup(stageData);
		render();
		return stageScene;
	}

	public function removeScene() {
		if (stageScene == null)
			return;
		
		scene.removeChild(stageScene);
		stageScene.dispose();
		stageScene = null;
		onDebug = null;
		debugSprite = 0;
		render();
	}

	override function __enterFrame(_delta:Int) {
		super.__enterFrame(_delta);

		if (stageScene == null) {
			return;
		}

		if (!debugMode && !PlayState.instance?.paused) {
			stageScene.update(_delta / 1000);
		}

		camera.rotationX = FlxMath.bound(camera.rotationX, -90, 90);
		camera.rotationY = wrapDegreesCloserToZero(camera.rotationY);

		if (debugMode) {
			var moveSpeed = 0.02 * (FlxG.keys.pressed.CONTROL ? 10 : 1) * (FlxG.keys.pressed.ALT ? 100 : 1);

			var targetObject = stageScene.getChildAt(debugSprite);
			if (targetObject is Object3D && targetObject != null) {
				debugText.text = 'SPRITE: ${targetObject.id}\nX: ${targetObject.x}\nY: ${targetObject.y}\nZ: ${targetObject.z}\nSX: ${targetObject.scaleX}\n\n';
				debugText.width = debugText.textWidth;
				debugText.height = debugText.textHeight;
			
				if (FlxG.keys.pressed.LBRACKET) {
					targetObject.scaleX = targetObject.scaleX -= moveSpeed;
					targetObject.scaleY = targetObject.scaleY -= moveSpeed;
				}
				if (FlxG.keys.pressed.RBRACKET) {
					targetObject.scaleX = targetObject.scaleX += moveSpeed;
					targetObject.scaleY = targetObject.scaleY += moveSpeed;
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

				if (freeCam) {
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
			}
		}

		for (key in _keysJustPressed) {
			switch (key) {
				case Keyboard.F3:
					debugMode = !debugMode;

				case Keyboard.F4:
					if (debugMode)
						freeCam = !freeCam;

				case Keyboard.F5:
					var targetObject = stageScene.getChildAt(debugSprite);
					if (targetObject is Object3D && targetObject != null) {
						trace('SPRITE: \nX: ${targetObject.x}\nY: ${targetObject.y}\nZ: ${targetObject.z}\nSX: ${targetObject.scaleX}\n');
					}
					trace('CAMERA: \nCX: ${camera.x}\nCY: ${camera.y}\nCZ: ${camera.z}'
						+ '\nCRX: ${camera.rotationX}\nCRY: ${camera.rotationY}\nCRZ: ${camera.rotationZ}');

				case Keyboard.NUMBER_1, Keyboard.NUMBER_2:
					if (debugMode) {
						if (key == Keyboard.NUMBER_1)
							debugSprite--;
						else
							debugSprite++;
						
						if (debugSprite != 0 && debugSprite >= stageScene.numChildren)
							debugSprite = 0;
						var targetObject = stageScene.getChildAt(debugSprite);
						if (targetObject is Object3D && targetObject != null) {
							// calc the average vector between 3 different points

							// var v1 = targetObject.rightVector.add(targetObject.leftVector);
							// v1.w = 2;
							// v1.project();
							// var v2 = targetObject.upVector.add(targetObject.downVector);
							// v2.w = 2;
							// v2.project();
							// var v3 = targetObject.forwardVector.add(targetObject.backVector);
							// v3.w = 2;
							// v3.project();

							// // now add all of the averages
							// var centerVector = v1.add(v2).add(v3);
							// // and average them again
							// centerVector.w = 2;
							// centerVector.project();

							// camera.lookAt(targetObject.position);
						}
					}
			}
		}
		_keysJustPressed = [];

		render();
	}

	public function move(angleDeg:Float, isNegative:Bool) {
		camera.x += Math.sin(radians(angleDeg)) * (isNegative ? -3.0 : 3.0);
		camera.z += Math.cos(radians(angleDeg)) * (isNegative ? -3.0 : 3.0);
	}

	public static function radians(value:Float) {
		return value * Math.PI / 180;
	}

	//away doesn't wrap angles so they can exceed (-)360 degrees
	static function wrapDegreesCloserToZero(v:Float) {
		var v1 = v % 360;
		if (v1 < -180)
			return v1 + 360;
		if (v1 > 180)
			return v1 - 360;
		return v1;
	}

	/**
	 * stage listener for resize events
	 */
	private function onResize(event:Event = null):Void {
		width = stage.stageWidth;
		height = stage.stageHeight;
	}
}