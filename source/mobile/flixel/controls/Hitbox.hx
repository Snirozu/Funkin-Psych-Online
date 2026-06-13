package mobile.flixel.controls;

#if flixel
import flixel.FlxG;
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
        
        // In your JSON, scale is used as absolute [Width, Height]
        var w:Int = data.scale != null ? Std.int(data.scale[0]) : Std.int(FlxG.width / 4);
        var h:Int = data.scale != null ? Std.int(data.scale[1]) : FlxG.height;
        var colorHex:Int = data.color != null ? Std.parseInt(data.color) : 0xFFFFFFFF;

        // Generate the graphic manually and assign it
        baseGraphic.pixels = createHintGraphic(w, h, colorHex, false);
        baseGraphic.alpha = 0.00001; // Keep it active for overlaps, but invisible
        
        subGraphic.visible = false; // Hitboxes don't need subgraphics
        name = data.name;
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
            // Properly formatted OpenFL Radial Gradient
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

    override public function updateInputs() {
        var isHit = false;
        var cam = cameras[0] != null ? cameras[0] : FlxG.camera;
        disableBright = true;

        #if (FLX_TOUCH || FLX_MOUSE)
        #if FLX_TOUCH
        for (touch in FlxG.touches.list) {
            if (touch.overlaps(baseGraphic, cam)) {
                isHit = true;
                break;
            }
        }
        #end
        #if FLX_MOUSE
        if (!isHit && FlxG.mouse.pressed && FlxG.mouse.overlaps(baseGraphic, cam)) {
            isHit = true;
        }
        #end
        #end

        if (isHit) {
            activeIDs.push(controlID);
            baseGraphic.alpha = 0.6; // Reveal the Hint Graphic
        } else {
            baseGraphic.alpha = 0.00001; // Hide it instantly
        }
    }
}
#end