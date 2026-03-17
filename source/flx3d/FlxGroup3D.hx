package flx3d;

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
        // game filters (shaders) are removed only for the 3d render because view3D does funky bugs when they are on
        var gameFilters = FlxG.game.filters;
        FlxG.game.filters = null;

		view.render();

		FlxG.game.filters = gameFilters;

		super.draw();
    }

	override function update(elapsed:Float) {
		super.update(elapsed);

		for (sprite3D in members3D) {
			sprite3D.update(elapsed);
		}
	}

	override function destroy() {
		super.destroy();

		if (view != null) {
			FlxG.stage.removeChild(view);
			view.scene._sceneGraphRoot.disposeWithChildren();
            view.dispose();
			view = null;
		}
    }

	private function onResize(event:Event = null):Void {
		view.width = FlxG.stage.stageWidth;
		view.height = FlxG.stage.stageHeight;
	}
}