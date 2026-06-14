package mobile.openfl.controls;

typedef Pointer = {id:Int, x:Float, y:Float, isDown:Bool, justPressed:Bool, justReleased:Bool, dead:Bool, pendingUp:Bool}

class MobileControls extends Sprite {
    public static var DPAD_PATH:String = "mobile/DPad/images/";
    public static var BUTTON_PATH:String = "mobile/Button/images/";
    public static var JOYSTICK_PATH:String = "mobile/JoyStick/images/";
    
    public static var DPAD_JSON:String = "mobile/DPad/";
    public static var BUTTON_JSON:String = "mobile/Button/";
    public static var JOYSTICK_JSON:String = "mobile/JoyStick/";
    public static var HITBOX_JSON:String = "mobile/Hitbox/";

    public var designWidth:Float = 1280;
    public var designHeight:Float = 720;

    public var activePointers:Map<Int, Pointer> = new Map();

    public var controls:Array<InputHandler> = [];

    public var buttons:Array<Button> = [];
    public var dpads:Array<DPad> = [];
    public var joysticks:Array<Joystick> = [];
    public var hitboxes:Array<Hitbox> = [];

    private var isMouseTracking:Bool = false;

    public function new(designW:Float = 1280, designH:Float = 720) {
        super();
        this.designWidth = designW;
        this.designHeight = designH;

        addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
    }

    private function onAddedToStage(e:Event) {
        Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;

        stage.addEventListener(Event.RESIZE, onResize);
        stage.addEventListener(Event.DEACTIVATE, onFocusLost);
        stage.addEventListener(Event.MOUSE_LEAVE, onFocusLost);

        if (Multitouch.supportsTouchEvents) {
            stage.addEventListener(TouchEvent.TOUCH_BEGIN, onTouchBegin);
            stage.addEventListener(TouchEvent.TOUCH_MOVE, onTouchMove);
            stage.addEventListener(TouchEvent.TOUCH_END, onTouchEnd);
        }

        stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
        stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
        stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);

        addEventListener(Event.ENTER_FRAME, onEnterFrame);
        onResize(null);
    }

    private function onFocusLost(e:Event) {
        resetAllInputs();
    }

    public function getFromName(buttonName:String):InputHandler {
        for (btn in controls) {
            if (btn != null && btn.jsonName == buttonName) {
                return btn;
            }
        }
        return null;
    }

    public function addButton(name:String) {
        if (buttons.length > 0) removeButton();
        var rawContent = File.getContent(BUTTON_JSON + name + ".json");
        if (rawContent == null) return;
        var parsed:Dynamic = Json.parse(rawContent);
        for (data in (parsed.buttons : Array<Dynamic>)) {
            var btn = new Button(data);
            addControl(btn);
            buttons.push(btn);
        }
        onResize(null);
    }

    public function addDPad(name:String) {
        if (dpads.length > 0) removeDPad();
        var rawContent = File.getContent(DPAD_JSON + name + ".json");
        if (rawContent == null) return;
        var parsed:Dynamic = Json.parse(rawContent);
        for (data in (parsed.dpads : Array<Dynamic>)) {
            var dpad = new DPad(data);
            addControl(dpad);
            dpads.push(dpad);
        }
        onResize(null);
    }

    public function addJoyStick(name:String) {
        if (joysticks.length > 0) removeJoyStick();
        var rawContent = File.getContent(JOYSTICK_JSON + name + ".json");
        if (rawContent == null) return;
        var parsed:Dynamic = Json.parse(rawContent);
        for (data in (parsed.joysticks : Array<Dynamic>)) {
            var joy = new Joystick(data);
            addControl(joy);
            joysticks.push(joy);
        }
        onResize(null);
    }

    public function addHitbox(name:String) {
        if (hitboxes.length > 0) removeHitbox();
        var rawContent = File.getContent(HITBOX_JSON + name + ".json");
        if (rawContent == null) return;
        var parsed:Dynamic = Json.parse(rawContent);
        for (data in (parsed.hitboxes : Array<Dynamic>)) {
            var box = new Hitbox(data);
            addControl(box);
            hitboxes.push(box);
        }
        onResize(null);
    }

    private function addControl(c:InputHandler) {
        controls.push(c);
        addChild(c);
    }

    public function removeButton() {
        for (btn in buttons) { controls.remove(btn); if (this.contains(btn)) removeChild(btn); }
        buttons = [];
    }

    public function removeDPad() {
        for (dpad in dpads) { controls.remove(dpad); if (this.contains(dpad)) removeChild(dpad); }
        dpads = [];
    }

    public function removeJoyStick() {
        for (joy in joysticks) { controls.remove(joy); if (this.contains(joy)) removeChild(joy); }
        joysticks = [];
    }

    public function removeHitbox() {
        for (box in hitboxes) { controls.remove(box); if (this.contains(box)) removeChild(box); }
        hitboxes = [];
    }

    public function clearControls() {
        removeButton();
        removeDPad();
        removeJoyStick();
        removeHitbox();
        resetAllInputs();
    }

    public function destroy() {
        clearControls();
        removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        removeEventListener(Event.ENTER_FRAME, onEnterFrame);

        if (stage != null) {
            stage.removeEventListener(Event.RESIZE, onResize);
            stage.removeEventListener(Event.DEACTIVATE, onFocusLost);
            stage.removeEventListener(Event.MOUSE_LEAVE, onFocusLost);

            if (Multitouch.supportsTouchEvents) {
                stage.removeEventListener(TouchEvent.TOUCH_BEGIN, onTouchBegin);
                stage.removeEventListener(TouchEvent.TOUCH_MOVE, onTouchMove);
                stage.removeEventListener(TouchEvent.TOUCH_END, onTouchEnd);
            }

            stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
            stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
        }
    }

    private function onResize(e:Event) {
        if (stage == null) return;
        var screenW = stage.stageWidth;
        var screenH = stage.stageHeight;
        var scaleRatio = Math.min(screenW / designWidth, screenH / designHeight);
        var offsetX = (screenW - (designWidth * scaleRatio)) / 2;
        var offsetY = (screenH - (designHeight * scaleRatio)) / 2;

        for (c in controls) {
            c.scaleX = c.scaleY = scaleRatio;
            c.x = offsetX + (c.jsonX * scaleRatio);
            c.y = offsetY + (c.jsonY * scaleRatio);
        }
    }

    private function onEnterFrame(e:Event) {
        for (c in controls) {
            c.updateInputs(activePointers);
            c.checkSignals();
        }

        var deadKeys = [];
        for (id => p in activePointers) {
            if (p.dead) {
                deadKeys.push(id);
            } else if (p.pendingUp) {
                p.isDown = false;
                p.justPressed = false;
                p.justReleased = true;
                p.pendingUp = false;
                p.dead = true; 
            } else {
                p.justPressed = false;
                p.justReleased = false;
            }
        }
        for (k in deadKeys) activePointers.remove(k);
    }

    private function updatePointer(id:Int, px:Float, py:Float, isDown:Bool) {
        var p = activePointers.get(id);
        if (p == null) {
            p = { id: id, x: px, y: py, isDown: false, justPressed: false, justReleased: false, dead: false, pendingUp: false };
            activePointers.set(id, p);
        }

        p.x = px;
        p.y = py;

        if (isDown) {
            p.pendingUp = false;
            if (!p.isDown) {
                p.isDown = true;
                p.justPressed = true;
                p.justReleased = false;
                p.dead = false;
            }
        } else {
            if (p.isDown) {
                p.pendingUp = true;
            }
        }
    }

    private function onMouseDown(e:MouseEvent) {
        isMouseTracking = true;
        updatePointer(-1, e.stageX, e.stageY, true);
    }

    private function onMouseMove(e:MouseEvent) {
        if (isMouseTracking) updatePointer(-1, e.stageX, e.stageY, true);
    }

    private function onMouseUp(e:MouseEvent) {
        isMouseTracking = false;
        updatePointer(-1, e.stageX, e.stageY, false);
    }

    private function onTouchBegin(e:TouchEvent) { updatePointer(e.touchPointID, e.stageX, e.stageY, true); }
    private function onTouchMove(e:TouchEvent) { updatePointer(e.touchPointID, e.stageX, e.stageY, true); }
    private function onTouchEnd(e:TouchEvent) { updatePointer(e.touchPointID, e.stageX, e.stageY, false); }

    public function checkState(id:String, state:String = "pressed"):Bool {
        for (c in controls) {
            if (c == null || c.disabled) continue;
            switch (state.toLowerCase()) {
                case "pressed": if (c.pressed(id)) return true;
                case "justpressed": if (c.justPressed(id)) return true;
                case "justreleased": if (c.justReleased(id)) return true;
                case "released": if (c.released(id)) return true;
            }
        }
        return false;
    }

    public function resetAllInputs() {
        for (c in controls) c.resetInputs();
        activePointers.clear();
        isMouseTracking = false;
    }
}