package mobile.flixel.controls;

#if flixel
class InputHandler extends FlxSpriteGroup {
    public var activeIDs:Array<String> = [];
    public var lastActiveIDs:Array<String> = [];

    public var disabled:Bool = false;
    public var disableBright:Bool = false;
    public var showBounds:Bool = false;

    public var baseGraphic:FlxSprite;
    public var subGraphic:FlxSprite;

    public var hitboxes:Array<FlxSprite> = [];
    
    // Updated Signal Tracking
    public var onButtonDown:FlxTypedSignal<(InputHandler, String) -> Void> = new FlxTypedSignal<(InputHandler, String) -> Void>();
    public var onButtonUp:FlxTypedSignal<(InputHandler, String) -> Void> = new FlxTypedSignal<(InputHandler, String) -> Void>();

    public function new(x:Float, y:Float, showBounds:Bool = false) {
        super(x, y);
        this.showBounds = showBounds;

        baseGraphic = new FlxSprite(0, 0);
        subGraphic = new FlxSprite(0, 0);

        add(baseGraphic);
        add(subGraphic);
    }

    public function loadElementGraphics(graphicName:String, subName:String, sheetName:String, basePath:String, colorHex:String, scaleVal:Float) {
        var loadFrames = function(target:FlxSprite, gName:String, sName:String, sPath:String) {
            var pngPath = sPath + sName + ".png";
            var xmlPath = sPath + sName + ".xml";

            if (FileSystem.exists(pngPath) && FileSystem.exists(xmlPath)) {
                var bmd = FileSystem.getBitmapData(pngPath);
                var xmlText = File.getContent(xmlPath);
                if (bmd != null && xmlText != null) {
                    var graphic = flixel.graphics.FlxGraphic.fromBitmapData(bmd);
                    target.frames = FlxAtlasFrames.fromSparrow(graphic, xmlText);
                    target.animation.addByPrefix("idle", gName, 24, true);
                    target.animation.play("idle");
                    return true;
                }
            }
            return false;
        };

        if (sheetName != null && sheetName != "") {
            if (!loadFrames(baseGraphic, graphicName, sheetName, basePath))
                baseGraphic.loadGraphic(FileSystem.getBitmapData(basePath + graphicName + ".png"));
        } else if (graphicName != null)
            baseGraphic.loadGraphic(FileSystem.getBitmapData(basePath + graphicName + ".png"));

        if (subName != null && subName != "") {
            if (sheetName != null && sheetName != "") {
                if (!loadFrames(subGraphic, subName, sheetName, basePath))
                    subGraphic.loadGraphic(FileSystem.getBitmapData(basePath + subName + ".png"));
            } else
                subGraphic.loadGraphic(FileSystem.getBitmapData(basePath + subName + ".png"));
        } else
            subGraphic.visible = false;

        baseGraphic.scale.set(scaleVal, scaleVal);
        subGraphic.scale.set(scaleVal, scaleVal);
        baseGraphic.updateHitbox();
        subGraphic.updateHitbox();

        centerSubGraphic();

        if (colorHex != null && colorHex != "") {
            var col:FlxColor = FlxColor.fromString(colorHex);
            baseGraphic.color = col;
            subGraphic.color = col;
        }
    }

    public function centerSubGraphic() {
        if (subGraphic != null && baseGraphic != null && subGraphic.visible) {
            subGraphic.x = baseGraphic.x + (baseGraphic.width - subGraphic.width) / 2;
            subGraphic.y = baseGraphic.y + (baseGraphic.height - subGraphic.height) / 2;
        }
    }

    public function createBoundHitbox(relX:Float, relY:Float, w:Int, h:Int):FlxSprite {
        var box = new FlxSprite(relX, relY);
        box.makeGraphic(w, h, FlxColor.WHITE);
        box.visible = showBounds;
        box.alpha = 0.4;
        add(box);
        hitboxes.push(box);
        return box;
    }

    public function updateBoundBrightness(box:FlxSprite, isPressed:Bool) {
        if (!showBounds) return;
        box.color = isPressed ? FlxColor.GREEN : FlxColor.WHITE;
        box.alpha = isPressed ? 0.8 : 0.4;
    }

    override public function update(elapsed:Float) {
        if (disabled) return;

        lastActiveIDs = activeIDs.copy();
        activeIDs = [];

        updateInputs();

        // Native signal dispatching per individual ID!
        for (id in activeIDs) {
            if (!lastActiveIDs.contains(id) && onButtonDown != null) onButtonDown.dispatch(this, id);
        }
        for (id in lastActiveIDs) {
            if (!activeIDs.contains(id) && onButtonUp != null) onButtonUp.dispatch(this, id);
        }

        super.update(elapsed);
    }

    public dynamic function updateInputs() {}

    public function checkOverlap(rect:FlxSprite):Bool {
        var overlap = false;
        #if FLX_TOUCH
        for (touch in FlxG.touches.list) {
            if (touch.overlaps(rect, camera)) overlap = true;
        }
        #end
        #if FLX_MOUSE
        if (FlxG.mouse.overlaps(rect, camera) && FlxG.mouse.pressed) overlap = true;
        #end
        return overlap;
    }

    public function pressed(id:String):Bool { return activeIDs.contains(id); }
    public function justPressed(id:String):Bool { return activeIDs.contains(id) && !lastActiveIDs.contains(id); }
    public function justReleased(id:String):Bool { return !activeIDs.contains(id) && lastActiveIDs.contains(id); }
    public function released(id:String):Bool { return !activeIDs.contains(id); }

    public function resetInputs() {
        activeIDs = [];
        lastActiveIDs = [];
        centerSubGraphic();
        applyBrightness(false);
        for (box in hitboxes) {
            if (box != null) updateBoundBrightness(box, false);
        }
    }

    public function applyBrightness(isPressed:Bool) {
        if (disableBright) return;
        var targetColor = isPressed ? 0xFFAAAAAA : FlxColor.WHITE;
        baseGraphic.color = targetColor;
        if (subGraphic.visible) subGraphic.color = targetColor;
    }
}
#end