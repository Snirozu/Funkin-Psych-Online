package mobile.openfl.controls;

import openfl.display.Shape;
import openfl.display.BitmapData;
import openfl.geom.Matrix;
import openfl.display.GradientType;

class Hitbox extends InputHandler {
    public var controlID:String;

    public function new(data:Dynamic) {
        var posX:Float = data.position != null ? data.position[0] : 0;
        var posY:Float = data.position != null ? data.position[1] : 0;
        super(posX, posY, false);

        controlID = data.id;

        var w:Int = data.scale != null ? Std.int(data.scale[0]) : 320;
        var h:Int = data.scale != null ? Std.int(data.scale[1]) : 720;
        var colorHex:Int = data.color != null ? Std.parseInt(data.color) : 0xFFFFFFFF;

        baseGraphic.bitmapData = createHintGraphic(w, h, colorHex, false);
        baseGraphic.alpha = 0.00001;
        subGraphic.visible = false;
    }

    private function createHintGraphic(Width:Int, Height:Int, Color:Int = 0xFFFFFF, ?isLane:Bool = false):BitmapData {
        var shape:Shape = new Shape();
        shape.graphics.beginFill(Color);
        shape.graphics.lineStyle(3, Color, 1);
        shape.graphics.drawRect(0, 0, Width, Height);
        shape.graphics.lineStyle(0, 0, 0);
        shape.graphics.drawRect(3, 3, Width - 6, Height - 6);
        shape.graphics.endFill();
        
        if (isLane) {
            shape.graphics.beginFill(Color);
        } else {
            var matrix = new Matrix();
            matrix.createGradientBox(Width, Height, 0, 0, 0);
            shape.graphics.beginGradientFill(GradientType.RADIAL, [Color, Color], [0.6, 0], [0, 255], matrix, openfl.display.SpreadMethod.PAD, openfl.display.InterpolationMethod.LINEAR_RGB, 0.5);
        }
        
        shape.graphics.drawRect(3, 3, Width - 6, Height - 6);
        shape.graphics.endFill();

        var bitmap:BitmapData = new BitmapData(Width, Height, true, 0);
        bitmap.draw(shape);
        return bitmap;
    }

    override public function updateInputs(pointers:Map<Int, MobileControls.Pointer>) {
        if (disabled) return;
        super.updateInputs(pointers);
        disableBright = true;

        var isHit = false;

        // Uses OpenFL's native display bounding logic
        for (p in pointers) {
            if (p != null && p.isDown && baseGraphic.hitTestPoint(p.x, p.y, true)) {
                isHit = true;
                break;
            }
        }

        if (isHit) {
            activeIDs.push(controlID);
            baseGraphic.alpha = 0.6;
        } else {
            baseGraphic.alpha = 0.00001;
        }
    }
}