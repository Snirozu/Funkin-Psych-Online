package flxanimate;

import animate.FlxAnimate;
import flixel.system.FlxAssets.FlxGraphicAsset;

class FlxAnimate extends animate.FlxAnimate {

    //Kept for backwards compatibility.
    public var showPivot = false;

    public function new(?x:Float = 0, ?y:Float = 0, ?simpleGraphic:FlxGraphicAsset) {
        super(x,y,simpleGraphic);

        // applyStageMatrix = true;
    }
}