package mobile.flixel.screen;

#if android
import lime.system.JNI;
#end

using Lambda;

#if flixel
class ScreenUtil {
    public static var swipe(default, never):SwipeUtil = new SwipeUtil();
    public static var touch(default, never):TouchUtil = new TouchUtil();
    public static var wideScreen(default, never):WideScreenMode = new WideScreenMode();
    
    #if android
    public static var android(default, never):AndroidUtil = new AndroidUtil();
    #end
}

class WideScreenMode extends BaseScaleMode {
    public var enabled(default, set):Bool = false;
    public static var _enabled:Bool = false;

    override function updateGameSize(Width:Int, Height:Int):Void {
        if (_enabled) {
            super.updateGameSize(Width, Height);
            return;
        }

        var ratio:Float = FlxG.width / FlxG.height;
        var realRatio:Float = Width / Height;

        if (realRatio < ratio) {
            gameSize.set(Width, Math.floor(Width / ratio));
        } else {
            gameSize.set(Math.floor(Height * ratio), Height);
        }
    }

    override function updateGamePosition():Void {
        if (_enabled) FlxG.game.x = FlxG.game.y = 0;
        else super.updateGamePosition();
    }

    private function set_enabled(value:Bool):Bool {
        _enabled = enabled = value;
        FlxG.scaleMode = new WideScreenMode();
        return value;
    }
}

class TouchUtil {
    public function new() {}

    public var pressed(get, never):Bool;
    public var justPressed(get, never):Bool;
    public var justReleased(get, never):Bool;
    public var released(get, never):Bool;
    public var instance(get, never):FlxTouch;

    public function overlaps(obj:FlxObject, ?cam:FlxCamera):Bool {
        for (t in FlxG.touches.list) if (t.overlaps(obj, cam ?? obj.camera)) return true;
        return false;
    }

    public function overlapsComplex(spr:FlxSprite, onTouch:Void->Void = null):Bool {
        if (instance == null) return false;
        
        var cam = spr.camera ?? FlxG.camera;
        for (t in FlxG.touches.list) {
            var tPos = t.getWorldPosition(cam);
            var isHit = spr.overlapsPoint(tPos, true, cam);
            tPos.put(); // Prevent memory leaks

            if (isHit) {
                if (t.justPressed && onTouch != null) onTouch();
                return true;
            }
        }
        return false;
    }

    // Haxe 4 concise getters
    inline function get_pressed() return FlxG.touches.list.exists(t -> t.pressed);
    inline function get_justPressed() return FlxG.touches.list.exists(t -> t.justPressed);
    inline function get_justReleased() return FlxG.touches.list.exists(t -> t.justReleased);
    inline function get_released() return FlxG.touches.list.exists(t -> t.released);
    inline function get_instance() return FlxG.touches.getFirst();
}

class SwipeUtil {
    public function new() {}

    public var UP(get, never):Bool;
    public var DOWN(get, never):Bool;
    public var LEFT(get, never):Bool;
    public var RIGHT(get, never):Bool;

    public function checkSwipe(min:Float, max:Float):Bool {
        #if FLX_POINTER_INPUT
        for (s in FlxG.swipes) {
            if (s != null && s.distance > 20 && s.degrees >= min && s.degrees <= max) return true;
        }
        #end
        return false;
    }

    inline function get_UP() return checkSwipe(45, 135);
    inline function get_DOWN() return checkSwipe(-135, -45);
    inline function get_LEFT() return checkSwipe(135, 180) || checkSwipe(-180, -135);
    inline function get_RIGHT() return checkSwipe(-45, 45);
}

#if android
class AndroidUtil #if (lime >= "8.0.0") implements JNISafety #end {
    public function new() {}

    // Grouped JNI definitions
    private var _setOrient:Dynamic = JNI.createStaticMethod('org/libsdl/app/SDLActivity', 'setOrientation', '(IIZLjava/lang/String;)V');
    private var _getOrient:Dynamic = JNI.createStaticMethod('org/libsdl/app/SDLActivity', 'getCurrentOrientation', '()I');
    private var _isKeyboard:Dynamic = JNI.createStaticMethod('org/libsdl/app/SDLActivity', 'isScreenKeyboardShown', '()Z');
    private var _hasClip:Dynamic = JNI.createStaticMethod('org/libsdl/app/SDLActivity', 'clipboardHasText', '()Z');
    private var _getClip:Dynamic = JNI.createStaticMethod('org/libsdl/app/SDLActivity', 'clipboardGetText', '()Ljava/lang/String;');
    private var _setClip:Dynamic = JNI.createStaticMethod('org/libsdl/app/SDLActivity', 'clipboardSetText', '(Ljava/lang/String;)V');
    private var _backBtn:Dynamic = JNI.createStaticMethod('org/libsdl/app/SDLActivity', 'manualBackButton', '()V');
    private var _setTitle:Dynamic = JNI.createStaticMethod('org/libsdl/app/SDLActivity', 'setActivityTitle', '(Ljava/lang/String;)Z');

    // Clean API
    public inline function setOrientation(w:Int, h:Int, res:Bool, hint:String) _setOrient(w, h, res, hint);
    public inline function isScreenKeyboardShown():Bool return _isKeyboard();
    public inline function clipboardHasText():Bool return _hasClip();
    public inline function clipboardGetText():String return _getClip();
    public inline function clipboardSetText(s:String) _setClip(s);
    public inline function manualBackButton() _backBtn();
    public inline function setActivityTitle(t:String):Bool return _setTitle(t);

    public function getCurrentOrientationAsString():String {
        return switch (_getOrient()) {
            case 1: "LandscapeRight";
            case 2: "LandscapeLeft";
            case 3: "Portrait";
            case 4: "PortraitUpsideDown";
            default: "Unknown";
        }
    }
}
#end

#end