package mobile.flixel.controls;

#if flixel
class Joystick extends InputHandler {
    public var controlIDs:Array<String> = [];
    private var maxRadius:Float = 50.0;
    public var touchZone:FlxSprite;
    private var currentTouchID:Int = -1;

    public function new(data:Dynamic) {
        var posX:Float = data.position != null ? data.position[0] : 0;
        var posY:Float = data.position != null ? data.position[1] : 0;
        super(posX, posY, data.showbounds == true);

        controlIDs = data.id;
        var scale:Float = data.scale != null ? data.scale : 1.0;
        maxRadius = (data.radius != null ? data.radius : maxRadius) * scale;

        loadElementGraphics(data.graphic, data.subgraphic, data.spritesheet, MobileControls.JOYSTICK_PATH, data.color, scale);

        var relMidX = baseGraphic.width / 2;
        var relMidY = baseGraphic.height / 2;

        if (data.border != null && data.border.length >= 2) {
            var bW:Int = Std.int(data.border[0] * scale);
            var bH:Int = Std.int(data.border[1] * scale);
            touchZone = new FlxSprite(relMidX - bW / 2, relMidY - bH / 2);
            touchZone.makeGraphic(bW, bH, 0xFFFFFFFF);
            touchZone.alpha = 0.15; 
            touchZone.visible = (data.showborder == true);
            insert(0, touchZone); 
        } else {
            touchZone = baseGraphic;
        }

        if (data.clickposition != null && data.clickbound != null) {
            for (i in 0...controlIDs.length) {
                var cPos:Array<Float> = data.clickposition[i];
                var cBnd:Array<Int> = data.clickbound[i];
                var relBoundX = relMidX + cPos[0] - (cBnd[0] / 2);
                var relBoundY = relMidY + cPos[1] - (cBnd[1] / 2);
                createBoundHitbox(relBoundX, relBoundY, cBnd[0], cBnd[1]);
            }
        }
    }

    private function isPointerInZone(px:Float, py:Float):Bool {
        if (touchZone == baseGraphic) {
            return px >= x && px <= x + baseGraphic.width && py >= y && py <= y + baseGraphic.height;
        } else {
            return px >= x + touchZone.x
                && px <= x + touchZone.x + touchZone.width
                && py >= y + touchZone.y
                && py <= y + touchZone.y + touchZone.height;
        }
    }

    override public function updateInputs() {
        var isTouching = false;
        var touchX:Float = baseGraphic.getGraphicMidpoint().x;
        var touchY:Float = baseGraphic.getGraphicMidpoint().y;

        var cam = camera != null ? camera : FlxG.camera;

        #if FLX_TOUCH
        if (currentTouchID == -1) {
            for (touch in FlxG.touches.list) {
                var tPos = touch.getWorldPosition(cam);
                if (touch.justPressed && (isPointerInZone(tPos.x, tPos.y) || checkHitboxes(touch))) {
                    currentTouchID = touch.touchPointID; 
                    break;
                }
                tPos.put();
            }
        }

        if (currentTouchID >= 0) {
            var found = false;
            for (touch in FlxG.touches.list) {
                if (touch.touchPointID == currentTouchID) {
                    if (touch.pressed) {
                        isTouching = true;
                        var tPos = touch.getWorldPosition(cam);
                        touchX = tPos.x;
                        touchY = tPos.y;
                        tPos.put();
                        found = true;
                    }
                    break;
                }
            }
            if (!found) currentTouchID = -1;
        }
        #end

        #if FLX_MOUSE
        var mPos = FlxG.mouse.getWorldPosition(cam);
        
        if (currentTouchID == -1 && FlxG.mouse.justPressed && (isPointerInZone(mPos.x, mPos.y) || checkHitboxes(FlxG.mouse))) {
            currentTouchID = -2;
        }
        
        if (currentTouchID == -2) {
            if (FlxG.mouse.pressed) {
                isTouching = true;
                touchX = mPos.x;
                touchY = mPos.y;
            } else {
                currentTouchID = -1;
            }
        }
        mPos.put();
        #end

        if (isTouching) {
            var mid = baseGraphic.getGraphicMidpoint();
            var dx = touchX - mid.x;
            var dy = touchY - mid.y;
            var dist = Math.sqrt(dx * dx + dy * dy);

            if (dist > maxRadius) {
                dx = (dx / dist) * maxRadius;
                dy = (dy / dist) * maxRadius;
            }

            subGraphic.x = mid.x + dx - (subGraphic.width / 2);
            subGraphic.y = mid.y + dy - (subGraphic.height / 2);

            var anyPressed = false;
            for (i in 0...hitboxes.length) {
                var box = hitboxes[i];
                var isPressed = checkOverlap(box);
                
                if (isPressed) {
                    activeIDs.push(controlIDs[i]);
                    anyPressed = true;
                }
                
                updateBoundBrightness(box, isPressed);
            }
            
            applyBrightness(anyPressed);

        } else {
            centerSubGraphic();
            applyBrightness(false);
            for (box in hitboxes) {
                updateBoundBrightness(box, false);
            }
        }
    }

    override public function resetInputs() {
        super.resetInputs();
        currentTouchID = -1;
    }

    private function checkHitboxes(pointer:Dynamic):Bool {
        var cam = camera != null ? camera : FlxG.camera;
        for (box in hitboxes) {
            if (pointer.overlaps(box, cam)) return true;
        }
        return false;
    }
}
#end