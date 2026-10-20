package;

import flixel.util.FlxColor;
import haxe.Exception;
import haxe.CallStack;

@:publicFields
class Log {
    // higher level printing functiones

    static function info(obj:Dynamic) {
        Log.println('[INFO] ${Std.string(obj)}', LogColor.INFO);
    }

    static function infoTrace(obj:Dynamic, ?pos:haxe.PosInfos) {
        Log.trace(Std.string(obj), LogColor.INFO, '[INFO] ', pos);
    }

    static function warn(obj:Dynamic) {
        Log.println('[WARNING] ${Std.string(obj)}', LogColor.WARNING);
    }

    static function warnTrace(obj:Dynamic, ?pos:haxe.PosInfos) {
        Log.trace(Std.string(obj), LogColor.WARNING, '[WARNING] ', pos);
    }

    static function error(objOrErrorA:Dynamic, ?objOrErrorB:Dynamic, ?pos:haxe.PosInfos) {
        Log.println('[ERROR] ${joinNotNulls(toErrorString(objOrErrorA, pos), toErrorString(objOrErrorB, pos))}', LogColor.ERROR);
    }

    static function errorTrace(objOrErrorA:Dynamic, ?objOrErrorB:Dynamic, ?pos:haxe.PosInfos) {
        Log.trace(Std.string(joinNotNulls(toErrorString(objOrErrorA, pos), toErrorString(objOrErrorB, pos))), LogColor.ERROR, '[ERROR] ', pos);
    }

    // base printing methodador

    static function trace(obj:Dynamic, ?color:FlxColor, ?prefix:String = '', ?pos:haxe.PosInfos) {
        println('${prefix}${pos.fileName}:${pos.lineNumber}: ${Std.string(obj)}', color);
    }

    static function println(obj:Dynamic, ?color:FlxColor) {
        Sys.println(toANSIFormattedString(Std.string(obj), color));
    }

    // message formatado

    static function toErrorString(exc:Dynamic, ?pos:haxe.PosInfos):Null<String> {
        if (exc == null)
            return null;

		if (exc is Exception) {
			final exc:Exception = cast exc;
            var excStack:String = exc.stack?.toString() ?? '';
            if (excStack.length <= 1)
                excStack = CallStack.toString(CallStack.exceptionStack(true));
            if (excStack.length <= 1 && pos != null) {
                excStack = 'Called from ${pos.className}.${pos.methodName} line ${pos.lineNumber}';
            }
			return '${exc.details()}\n${excStack}';
		}

        return Std.string(exc);
		// return '${Std.string(exc)}\n${CallStack.toString(CallStack.exceptionStack(true))}';
    }

    static function joinNotNulls(a:Dynamic, b:Dynamic) {
        if (a == null && b == null)
            return null;
        if (a == null)
            return b;
        if (b == null)
            return a;
        return a + ' ' + b;
    }

    // ANSI constructador

    static final ANSI_RESET = '\x1b[0m';
    static inline function toANSIFormattedString(str:String, color:FlxColor = FlxColor.WHITE) {
        return '\x1b[38;2;${color.red};${color.green};${color.blue}m${str}${ANSI_RESET}';
    }
}

enum abstract LogColor(UInt) from UInt to UInt {
    // SUCCESS = 0xccff33; maybe just use INFO to not overcomplicate
    var INFO:UInt = 0x44aaee;
    var WARNING:UInt = 0xffd755;
    var ERROR:UInt = 0xff3366;
}