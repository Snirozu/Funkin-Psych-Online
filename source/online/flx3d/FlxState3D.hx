package online.flx3d;

import away3d.containers.View3D;
import flixel.FlxState;

class FlxState3D extends FlxState {
	var view3D:View3D;
	var members3D:Array<FlxSprite3D> = [];

    override function create() {
        super.create();

		view3D = new View3D();
		view3D.width = FlxG.width;
		view3D.height = FlxG.height;
		FlxG.stage.addChildAt(view3D, 0);
    }

	public function addTo3D(sprite:FlxSprite, ?keep2D:Bool = false):FlxSprite3D {
		if (keep2D) {
			add(sprite);
			//prevent updating two times
			sprite.active = false;
		}
		var sprite3D = new FlxSprite3D(sprite);
		members3D.push(sprite3D);
		view3D.scene.addChild(sprite3D);
		return sprite3D;
	}

	@:noCompletion override function draw() {
		super.draw();

        // game filters (shaders) are removed only for the 3d render because view3D does funky bugs when they are on
        var gameFilters = FlxG.game.filters;
        FlxG.game.filters = null;

		view3D.render();

		FlxG.game.filters = gameFilters;
    }

	override function update(elapsed:Float) {
		super.update(elapsed);

		for (sprite3D in members3D) {
			sprite3D.update(elapsed);
		}
	}

	override function destroy() {
		super.destroy();

		if (view3D != null) {
			FlxG.stage.removeChild(view3D);
			view3D.scene._sceneGraphRoot.disposeWithChildren();
            view3D.dispose();
			view3D = null;
		}
    }
}