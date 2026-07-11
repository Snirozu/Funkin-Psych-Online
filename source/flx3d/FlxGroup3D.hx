package flx3d;

import away3d.core.managers.Stage3DManager;
import openfl.events.Event;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import away3d.containers.View3D;
import flixel.FlxG;
import flixel.FlxSprite;

class FlxGroup3D extends FlxBasic {
	var view:View3D;
	var members3D:Array<FlxSprite3D> = [];

    override function new(front:Bool = false) {
        super();

		if (view == null)
			view = new View3D();
		view.width = FlxG.width;
		view.height = FlxG.height;
		view.backgroundAlpha = 0;

		// view.scene.scaleMode = StageScaleMode.NO_SCALE;
		// view.scene.align = StageAlign.TOP;

		final stage3DManager = Stage3DManager.getInstance(FlxG.stage);
		final stage3DProxy = stage3DManager.getFreeStage3DProxy();
		// prevents render depth fuckery with skybox 
		view.stage3DProxy = stage3DProxy;
		view.shareContext = true;

        if (front)
            FlxG.stage.addChild(view);
        else
		    FlxG.stage.addChildAt(view, 0);

		FlxG.stage.addEventListener(Event.RESIZE, onResize);
		view.addEventListener(Event.REMOVED, (e) -> {
			FlxG.stage.removeEventListener(Event.RESIZE, onResize);
		});

		onResize();
    }

	public function add(sprite:FlxSprite, ?keep2D:Bool = false):FlxSprite3D {
		// if (keep2D) {
		// 	add(sprite);
		// 	//prevent updating two times
		// 	sprite.active = false;
		// }
		var sprite3D = new FlxSprite3D(sprite);
		members3D.push(sprite3D);
		view.scene.addChild(sprite3D);
		return sprite3D;
	}

	public function remove(sprite3D:FlxSprite3D) {
		members3D.remove(sprite3D);
		view.scene.removeChild(sprite3D);
	}

	public function removeFlxSprite(sprite:FlxSprite) {
		for (spr in members3D) {
			if (spr?.sprite != sprite)
				return;

			remove(spr);
		}
	}

	@:noCompletion override function draw() {
		view.stage3DProxy.clear();

        // game filters (shaders) are removed only for the 3d render because view3D does funky bugs when they are on
        var gameFilters = FlxG.game.filters;
        FlxG.game.filters = null;

		view.render();

		FlxG.game.filters = gameFilters;

		super.draw();

		view.stage3DProxy.present();
    }

	override function update(elapsed:Float) {
		super.update(elapsed);

		for (sprite3D in members3D) {
			sprite3D.update(elapsed);
		}

		for (i in 0...view.scene.numChildren) {
        	var obj = view.scene.getChildAt(i);
			if (obj?.extra != null && obj.extra.onUpdate != null) {
				obj.extra.onUpdate(elapsed);
			}
		}
	}

	override function destroy() {
		super.destroy();

		if (view != null) {
			FlxG.stage.removeChild(view);
			view.scene._sceneGraphRoot.disposeWithChildren();
			if (view.stage3DProxy != null) {
				view.stage3DProxy.clear();
				view.stage3DProxy.dispose();
			}
            view.dispose();
			view = null;
		}
    }

	private function onResize(event:Event = null):Void {
		view.width = FlxG.stage.stageWidth;
		view.height = FlxG.stage.stageHeight;
	}
}