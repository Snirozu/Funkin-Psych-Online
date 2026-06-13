package mobile.openfl.controls;

class ControlSignal {
    private var listeners:Array<(InputHandler, String) -> Void> = [];
    public function new() {}
    public function add(listener:(InputHandler, String) -> Void) {
        if (!listeners.contains(listener)) listeners.push(listener);
    }
    public function remove(listener:(InputHandler, String) -> Void) {
        listeners.remove(listener);
    }
    public function dispatch(control:InputHandler, id:String) {
        for (l in listeners) l(control, id);
    }
}

class InputHandler extends Sprite {
    public var activeIDs:Array<String> = [];
    public var lastActiveIDs:Array<String> = [];

    public var disabled:Bool = false;
    public var disableBright:Bool = false;
    public var showBounds:Bool = false;

    public var baseGraphic:Bitmap;
    public var subGraphic:Bitmap;
    public var hitboxes:Array<Sprite> = [];

    public var jsonX:Float = 0;
    public var jsonY:Float = 0;
    public var baseScale:Float = 1.0;

    private var baseColor:ColorTransform;

    // Updated Signals
    public var onButtonDown:ControlSignal = new ControlSignal();
    public var onButtonUp:ControlSignal = new ControlSignal();

    public function new(jX:Float, jY:Float, showBounds:Bool) {
        super();
        this.jsonX = jX;
        this.jsonY = jY;
        this.showBounds = showBounds;

        baseGraphic = new Bitmap(null, PixelSnapping.NEVER);
        subGraphic = new Bitmap(null, PixelSnapping.NEVER);
        baseGraphic.smoothing = true;
        subGraphic.smoothing = true;

        addChild(baseGraphic);
        addChild(subGraphic);
    }

    public function loadElementGraphics(gName:String, subName:String, sheet:String, path:String, colorHex:String, scaleVal:Float) {
        this.baseScale = scaleVal;

        loadBitmap(baseGraphic, gName, sheet, path);
        if (subName != null && subName != "") {
            loadBitmap(subGraphic, subName, sheet, path);
            centerSubGraphic();
        }

        if (colorHex != null && colorHex != "") {
            var colInt = Std.parseInt(colorHex);
            var r = ((colInt >> 16) & 0xFF) / 255.0;
            var g = ((colInt >> 8) & 0xFF) / 255.0;
            var b = (colInt & 0xFF) / 255.0;
            baseColor = new ColorTransform(r, g, b);
            baseGraphic.transform.colorTransform = baseColor;
            subGraphic.transform.colorTransform = baseColor;
        } else {
            baseColor = new ColorTransform();
        }

        baseGraphic.scaleX = baseGraphic.scaleY = baseScale;
        subGraphic.scaleX = subGraphic.scaleY = baseScale;
    }

    private function loadBitmap(bmp:Bitmap, name:String, sheet:String, path:String) {
        if (sheet != null && sheet != "") {
            bmp.bitmapData = FileSystem.getBitmapData(path + sheet + ".png");
            bmp.smoothing = true;
            bmp.pixelSnapping = PixelSnapping.NEVER;
            var xmlText = File.getContent(path + sheet + ".xml");
            if (xmlText != null) {
                var xml = Xml.parse(xmlText).firstElement();
                for (node in xml.elementsNamed("SubTexture")) {
                    if (node.get("name").indexOf(name) == 0) {
                        var rx = Std.parseFloat(node.get("x"));
                        var ry = Std.parseFloat(node.get("y"));
                        var rw = Std.parseFloat(node.get("width"));
                        var rh = Std.parseFloat(node.get("height"));
                        bmp.scrollRect = new Rectangle(rx, ry, rw, rh);
                        return;
                    }
                }
            }
        } else if (name != null) {
            bmp.bitmapData = FileSystem.getBitmapData(path + name + ".png");
            bmp.smoothing = true;
            bmp.pixelSnapping = PixelSnapping.NEVER;
        }
    }

    public function centerSubGraphic() {
        if (subGraphic.bitmapData != null) {
            var bW = baseGraphic.scrollRect != null ? baseGraphic.scrollRect.width : baseGraphic.bitmapData.width;
            var bH = baseGraphic.scrollRect != null ? baseGraphic.scrollRect.height : baseGraphic.bitmapData.height;
            var sW = subGraphic.scrollRect != null ? subGraphic.scrollRect.width : subGraphic.bitmapData.width;
            var sH = subGraphic.scrollRect != null ? subGraphic.scrollRect.height : subGraphic.bitmapData.height;

            subGraphic.x = ((bW * baseScale) - (sW * baseScale)) / 2;
            subGraphic.y = ((bH * baseScale) - (sH * baseScale)) / 2;
        }
    }

    public function createBoundHitbox(relX:Float, relY:Float, w:Float, h:Float):Sprite {
        var box = new Sprite();
        box.graphics.beginFill(0xFFFFFF, 0.4);
        box.graphics.drawRect(0, 0, w, h);
        box.graphics.endFill();
        box.x = relX;
        box.y = relY;
        if (!showBounds) box.alpha = 0;
        addChild(box);
        hitboxes.push(box);
        return box;
    }

    public function updateBoundBrightness(box:Sprite, isPressed:Bool) {
        if (!showBounds) return;
        box.alpha = isPressed ? 0.8 : 0.4;
        box.transform.colorTransform = isPressed ? new ColorTransform(0, 1, 0) : new ColorTransform();
    }

    public function applyBrightness(isPressed:Bool) {
        if (disableBright) return;
        var mult = isPressed ? 0.7 : 1.0;
        var ct = new ColorTransform(baseColor.redMultiplier * mult, baseColor.greenMultiplier * mult, baseColor.blueMultiplier * mult);
        baseGraphic.transform.colorTransform = ct;
        subGraphic.transform.colorTransform = ct;
    }

    public function checkOverlap(rect:Sprite, pointers:Map<Int, MobileControls.Pointer>):Bool {
        for (p in pointers) {
            if (p.isDown && rect.hitTestPoint(p.x, p.y, true)) return true;
        }
        return false;
    }

    public function updateInputs(pointers:Map<Int, MobileControls.Pointer>) {
        lastActiveIDs = activeIDs.copy();
        activeIDs = [];
    }

    // Dispatches individually per ID string!
    public function checkSignals() {
        for (id in activeIDs) {
            if (!lastActiveIDs.contains(id)) onButtonDown.dispatch(this, id);
        }
        for (id in lastActiveIDs) {
            if (!activeIDs.contains(id)) onButtonUp.dispatch(this, id);
        }
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
        for (box in hitboxes) updateBoundBrightness(box, false);
    }
}