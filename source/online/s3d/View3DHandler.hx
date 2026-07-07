package online.s3d;

import online.s3d.util.AudioUtil;
import away3d.audio.Sound3D;
import lime.ui.FileDialog;
import feathers.events.TriggerEvent;
import feathers.controls.Button;
import feathers.controls.Header;
import feathers.controls.TextInput;
import feathers.layout.HorizontalLayoutData;
import feathers.controls.NumericStepper;
import feathers.layout.VerticalLayoutData;
import feathers.controls.TabBar;
import feathers.data.ArrayHierarchicalCollection;
import feathers.controls.GroupListView;
import feathers.layout.VerticalLayout;
import feathers.style.Theme;
import feathers.style.IDarkModeTheme;
import feathers.controls.navigators.TabItem;
import feathers.data.ArrayCollection;
import feathers.controls.navigators.TabNavigator;
import feathers.skins.RectangleSkin;
import feathers.layout.HorizontalLayout;
import feathers.controls.Label;
import feathers.controls.ScrollContainer;
import feathers.controls.LayoutGroup;
import away3d.entities.Mesh;
import away3d.events.MouseEvent3D;
import away3d.core.pick.PickingType;
import online.s3d.objects.GizmoMover;
import online.s3d.objects.PersonCameraController;
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
import openfl.ui.Mouse;

class PropertiesView extends ScrollContainer {
	var objId:TextInput;
	var posSteppers:Array<NumericStepper> = [];
	var rotSteppers:Array<NumericStepper> = [];
	var sclSteppers:Array<NumericStepper> = [];

    public function new() {
        super();

        var header = new Header();
		header.text = "ID/Name";
		addChild(header);

		objId = new TextInput();
		addChild(objId);
		objId.addEventListener(Event.CHANGE, (e) -> {
			final targetObject = View3DHandler.instance.getSelectedObject();
			if (targetObject == null)
				return;

			targetObject.id = objId.text;
		});

		var header = new Header();
		header.text = "Position";
		addChild(header);

		posSteppers = addXYZSteppers();
		for (i => stepper in posSteppers) {
			stepper.addEventListener(Event.CHANGE, e -> {
				final targetObject = View3DHandler.instance.getSelectedObject();
				if (targetObject == null)
					return;
				
				switch (i) {
					case 0:
						targetObject.x = stepper.value;
					case 1:
						targetObject.y = stepper.value;
					case 2:
						targetObject.z = stepper.value;
				}
			});
		}

		var header = new Header();
		header.text = "Rotation";
		addChild(header);

		rotSteppers = addXYZSteppers([-360, 360]);
		for (i => stepper in rotSteppers) {
			stepper.addEventListener(Event.CHANGE, e -> {
				final targetObject = View3DHandler.instance.getSelectedObject();
				if (targetObject == null)
					return;
				
				switch (i) {
					case 0:
						targetObject.rotationX = stepper.value;
					case 1:
						targetObject.rotationY = stepper.value;
					case 2:
						targetObject.rotationZ = stepper.value;
				}
			});
		}

		var header = new Header();
		header.text = "Scale";
		addChild(header);

		sclSteppers = addXYZSteppers();
		for (i => stepper in sclSteppers) {
			stepper.addEventListener(Event.CHANGE, e -> {
				final targetObject = View3DHandler.instance.getSelectedObject();
				if (targetObject == null)
					return;
				
				switch (i) {
					case 0:
						targetObject.scaleX = stepper.value;
					case 1:
						targetObject.scaleY = stepper.value;
					case 2:
						targetObject.scaleZ = stepper.value;
				}
			});
		}

		var verticalLayout = new VerticalLayout();
		verticalLayout.horizontalAlign = JUSTIFY;
		layout = verticalLayout;
    }

	override function update() {
		super.update();

		final targetObject = View3DHandler.instance.getSelectedObject();
		if (targetObject == null) {
			return;
		}

		objId.text = targetObject.id;

		for (i => stepper in posSteppers) {
			switch (i) {
				case 0:
					stepper.value = targetObject.x;
					stepper.step = View3DHandler.instance.gizmo.grid.x;
				case 1:
					stepper.value = targetObject.y;
					stepper.step = View3DHandler.instance.gizmo.grid.y;
				case 2:
					stepper.value = targetObject.z;
					stepper.step = View3DHandler.instance.gizmo.grid.z;
			}
		}

		for (i => stepper in rotSteppers) {
			stepper.step = 1;
			switch (i) {
				case 0:
					stepper.value = targetObject.rotationX;
				case 1:
					stepper.value = targetObject.rotationY;
				case 2:
					stepper.value = targetObject.rotationZ;
			}
		}

		for (i => stepper in sclSteppers) {
			stepper.step = 0.1;
			switch (i) {
				case 0:
					stepper.value = targetObject.scaleX;
				case 1:
					stepper.value = targetObject.scaleY;
				case 2:
					stepper.value = targetObject.scaleZ;
			}
		}
	}

	function addXYZSteppers(?minAndMax:Array<Null<Float>>) {
		minAndMax ??= [];
		if (minAndMax[0] == null)
			minAndMax[0] = -2147483647;
		if (minAndMax[1] == null)
			minAndMax[1] = 2147483647;

		var xyzRow = new LayoutGroup();
		var rowLayout = new HorizontalLayout();
		rowLayout.gap = 12.0;
		xyzRow.layout = rowLayout;

		var groupLayoutData = new HorizontalLayoutData();
		groupLayoutData.percentWidth = 100.0;

		var stepperLayoutData = new HorizontalLayoutData();
		stepperLayoutData.percentWidth = 100.0;

		var subGroupLayout = new HorizontalLayout();
		subGroupLayout.gap = 4.0;
		subGroupLayout.verticalAlign = MIDDLE;

		var xGroup = new LayoutGroup();
		xGroup.layout = subGroupLayout;
		xGroup.layoutData = groupLayoutData;

		var xLabel = new Label();
		xLabel.text = "X:";

		var xStepper = new NumericStepper();
		xStepper.layoutData = stepperLayoutData;

		xGroup.addChild(xLabel);
		xGroup.addChild(xStepper);

		var yGroup = new LayoutGroup();
		yGroup.layout = subGroupLayout;
		yGroup.layoutData = groupLayoutData;

		var yLabel = new Label();
		yLabel.text = "Y:";

		var yStepper = new NumericStepper();
		yStepper.layoutData = stepperLayoutData;

		yGroup.addChild(yLabel);
		yGroup.addChild(yStepper);

		var zGroup = new LayoutGroup();
		zGroup.layout = subGroupLayout;
		zGroup.layoutData = groupLayoutData;

		var zLabel = new Label();
		zLabel.text = "Z:";

		var zStepper = new NumericStepper();
		zStepper.layoutData = stepperLayoutData;

		zGroup.addChild(zLabel);
		zGroup.addChild(zStepper);

		xyzRow.addChild(xGroup);
		xyzRow.addChild(yGroup);
		xyzRow.addChild(zGroup);

		addChild(xyzRow);

		xStepper.textInputFactory = () -> {
			var input = new TextInput();
			input.autoSizeWidth = false;
			input.maxWidth = 40;
			return input;
		};
		xStepper.minimum = minAndMax[0];
		xStepper.maximum = minAndMax[1];

		yStepper.textInputFactory = () -> {
			var input = new TextInput();
			input.autoSizeWidth = false;
			input.maxWidth = 40;
			return input;
		};
		yStepper.minimum = minAndMax[0];
		yStepper.maximum = minAndMax[1];

		zStepper.textInputFactory = () -> {
			var input = new TextInput();
			input.autoSizeWidth = false;
			input.maxWidth = 40;
			return input;
		};
		zStepper.minimum = minAndMax[0];
		zStepper.maximum = minAndMax[1];

		return [xStepper, yStepper, zStepper];
	}
}

class ObjectsView extends ScrollContainer {
	var listView:GroupListView;

    public function new() {
        super();

		listView = new GroupListView();
		listView.itemToText = item -> item.text;
		listView.itemToHeaderText = item -> item.text;
		listView.selectable = true;
		listView.enabled = true;

		var layoutData = new VerticalLayoutData();
		layoutData.percentHeight = 95.0;
		listView.layoutData = layoutData;

        addChild(listView);

		var verticalLayout = new VerticalLayout();
		verticalLayout.horizontalAlign = JUSTIFY;
		layout = verticalLayout;

		listView.addEventListener(Event.CHANGE, pickObject);
    }

	function pickObject(event:Event):Void {
		if (listView.selectedLocation == null)
			return;

		if (listView.selectedLocation[0] == 0) {
			View3DHandler.instance.selectedObject = listView.selectedLocation[1];
		}

		if (listView.selectedLocation[0] == 1) {
			final point = View3DHandler.instance.funkinStage.cameraPoints.get(listView.itemToText(listView.selectedItem));
			if (point == null)
				return;
			View3DHandler.instance.camera.x = point.position[0];
			View3DHandler.instance.camera.y = point.position[1];
			View3DHandler.instance.camera.z = point.position[2];
			View3DHandler.instance.camera.rotationX = point.rotation[0];
			View3DHandler.instance.camera.rotationY = point.rotation[1];
			View3DHandler.instance.camera.rotationZ = point.rotation[2];
		}
	}

	override function update() {
		super.update();

		var sceneObjects = [];
		for (i in 0...View3DHandler.instance.scene.numChildren) {
			final child = View3DHandler.instance.scene.getChildAt(i);
			final objTracked = View3DHandler.instance.funkinStage.stageData.stage3D.objects.exists(child.id);
			sceneObjects.push({
				text: child?.id ?? '???' + (!objTracked ? ' (UNTRACKED)' : '')
			});
		}

		var cameraPoints = [];
		for (name => point in View3DHandler.instance.funkinStage.cameraPoints) {
			cameraPoints.push({
				text: name
			});
		}

		listView.dataProvider = new ArrayHierarchicalCollection([{ text: "Scene", children: sceneObjects}, { text: "Camera Points (READ-ONLY)", children: cameraPoints}], (item:Dynamic) -> item.children);
	
		listView.selectedLocation = [0, View3DHandler.instance.selectedObject];
	}
}

class EditorView extends ScrollContainer {
    public function new() {
        super();
		
        var message = new Label();
        message.text = "Psych Online 3D Editor - EARLY ALPHA";
        addChild(message);

		var save = new Button();
		save.text = "Save Stage";
		addChild(save);
		save.addEventListener(TriggerEvent.TRIGGER, (e) -> {
			final stageData = View3DHandler.instance.funkinStage.stageData;

			for (id => data in stageData.stage3D.objects) {
				final obj = View3DHandler.instance.getObjectOfID(id);
				if (obj == null)
					continue;

				data.position = [obj.x, obj.y, obj.z];
				data.rotation = [obj.rotationX, obj.rotationY, obj.rotationZ];
				data.scale = [obj.scaleX, obj.scaleY, obj.scaleZ];
			}
			
			untyped {
				stageData.stage3D.objects = ShitUtil.mapToObj(stageData.stage3D.objects);
				stageData.stage3D.cameraPoints = ShitUtil.mapToObj(stageData.stage3D.cameraPoints);
			}

			var fileDialog = new FileDialog();
			fileDialog.onSave.add(path -> Alert.alert("Stage saved in:", path));
			fileDialog.save(haxe.Json.stringify(stageData), "json", online.util.FileUtils.joinNativePath([Sys.getCwd(), 'stage.json']), "Save Stage File");

			stageData.stage3D.objects = cast ShitUtil.objToMap(stageData.stage3D.objects);
			stageData.stage3D.cameraPoints = cast ShitUtil.objToMap(stageData.stage3D.cameraPoints);
		});

		var exit = new Button();
		exit.text = "Exit Editor";
		addChild(exit);
		exit.addEventListener(TriggerEvent.TRIGGER, (e) -> {
			View3DHandler.instance.debugMode = false;
		});

		layout = new VerticalLayout();
    }
}

class View3DEditor extends TabNavigator {
	public function new() {
		var theme = cast(Theme.fallbackTheme, IDarkModeTheme);
		theme.darkMode = true;

		super();

		width = 400;
		height = 600;

		dataProvider = new ArrayCollection([
			TabItem.withClass("Properties", PropertiesView),
			TabItem.withClass("Objects", ObjectsView),
			TabItem.withClass("Editor", EditorView),
		]);
	}
}

class View3DHandler extends View3D {
	public static var instance:View3DHandler;

	var skyboxTexture:BitmapCubeTexture;
	var _skyBox:SkyBox;
	public var onDebug:Bool->Void = null;

	public var debugMode(default, set):Bool = false;
	function set_debugMode(v) {
		debugMode = v;
		updateDebugMode();
		if (onDebug != null)
			onDebug(debugMode);
		return debugMode;
	}
	public var selectedObject(default, set):Int = 0;

	var personCam:PersonCameraController;
	public var gizmo:GizmoMover;
	var cursor:Bitmap;
	var editor:View3DEditor;

	public var funkinStage:FunkinStage3D;

	public function new(funkinStage:FunkinStage3D) {
		instance = this;

		this.funkinStage = funkinStage;

		super();

		if (stage != null)
			init();
		else
			addEventListener(Event.ADDED_TO_STAGE, init);
	}

	private function init(?_:Event):Void {
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

		// TODO FlxSound -> FlxSound3D proxy

		// var soundInst = new Sound3D(AudioUtil.loadMonoSound("assets/songs/thorns/Inst-erect.ogg"), camera, null, 1, 10000);
		// soundInst.id = 'sound-inst';
		// scene.addChild(soundInst);

        // var soundOpponent = new Sound3D(AudioUtil.loadMonoSound("assets/songs/thorns/Voices-erect-Opponent.ogg"), camera, null, 1, 10000);
		// soundOpponent.id = 'sound-opponent';
		// scene.addChild(soundOpponent);

        // var soundPlayer = new Sound3D(AudioUtil.loadMonoSound("assets/songs/thorns/Voices-erect-Player.ogg"), camera, null, 1, 10000);
		// soundPlayer.id = 'sound-player';
		// scene.addChild(soundPlayer);

		// soundInst.play();
		// soundOpponent.play();
		// soundPlayer.play();

		personCam = new PersonCameraController(camera);
		addChild(personCam);

		gizmo = new GizmoMover(this);
		gizmo.id = 'gizmo';
		scene.addChild(gizmo);
		
		editor = new View3DEditor();
		editor.visible = editor.enabled = false;
		editor.mouseEnabled = editor.mouseChildren = false;
		addChild(editor);

		cursor = new Bitmap(new GraphicCursor(0, 0));
		cursor.visible = false;
		addChild(cursor);

		addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, rightMouseDown, true);
		addEventListener(MouseEvent.RIGHT_MOUSE_UP, rightMouseUp, true);
		addEventListener(MouseEvent.MOUSE_MOVE, mouseMove, true);
		addEventListener(MouseEvent.MOUSE_UP, mouseUp, true);
		addEventListener(Event.REMOVED, (e) -> {
			removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, rightMouseDown);
			removeEventListener(MouseEvent.RIGHT_MOUSE_UP, rightMouseUp);
			removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
		});

		updateDebugMode();
	}

	function mouseUp(e:MouseEvent) {
		if (gizmo.direction != null) {
			gizmo.direction = null;
			if (@:privateAccess editor.activeItemView is ScrollContainer)
				@:privateAccess cast (editor.activeItemView, ScrollContainer).update();
		}
	}

	function mouseMove(e:MouseEvent) {
		cursor.x = e.stageX;
		cursor.y = e.stageY;
	} 

	function rightMouseDown(e:MouseEvent) {
		if (!debugMode)
			return;

		personCam.enabled = true;
		personCam.focused = true;
		cursor.visible = false;
		editor.visible = editor.enabled = false;
		editor.mouseEnabled = editor.mouseChildren = false;
	}

	function rightMouseUp(e:MouseEvent) {
		if (!debugMode)
			return;

		personCam.enabled = false;
		personCam.focused = false;
		cursor.visible = true;
		editor.visible = editor.enabled = true;
		editor.mouseEnabled = editor.mouseChildren = true;
	}

	var _prevMouseVis:Null<Bool> = null;
	function updateDebugMode() {
		// if (_skyBox != null) {
		// 	_skyBox.visible = debugMode;
		// }

		cursor.visible = debugMode;
		editor.visible = editor.enabled = debugMode;
		editor.mouseEnabled = editor.mouseChildren = debugMode;

		if (!debugMode) {
			personCam.enabled = false;
			gizmo.target = null;
		}
	}

	function set_selectedObject(v) {
		selectedObject = v;
		var targetObject = scene.getChildAt(selectedObject);
		if (targetObject is Object3D && targetObject != null) {
			gizmo.target = targetObject;
		}
		return selectedObject;
	}

	public function getSelectedObject() {
		var targetObject = scene.getChildAt(selectedObject);
		if (targetObject is Object3D && targetObject != null) {
			return targetObject;
		}
		return null;
	}

	public function getObjectOfID(id:String) {
		for (i in 0...scene.numChildren) {
			final child = scene.getChildAt(i);
			if (child?.id == id)
				return child;
		}
		return null;
	}

	override function __enterFrame(_delta:Int) {
		super.__enterFrame(_delta);

		editor.x = Lib.application.window.width - editor.width - 10;
		editor.y = 10;

		gizmo.update();

		// if (!debugMode && !PlayState.instance?.paused) {
		// 	stageScene.update(_delta / 1000);
		// }

		// camera.rotationX = FlxMath.bound(camera.rotationX, -90, 90);
		// camera.rotationY = wrapDegreesCloserToZero(camera.rotationY);

		render();
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
}

@:bitmap("assets/images/ui/cursor.png")
private class GraphicCursor extends BitmapData {}