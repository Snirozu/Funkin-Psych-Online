package macro;

// award for the most useless macro ever goes to sscript

import haxe.macro.Compiler;
import haxe.macro.ComplexTypeTools;
import haxe.macro.Context;
import haxe.macro.ExprTools;
import haxe.macro.MacroStringTools;
import haxe.macro.Printer;
import haxe.macro.TypeTools;
import haxe.macro.TypedExprTools;
import tea.backend.SScriptVer;
import tea.backend.crypto.Base32;
import haxe.Serializer;
import haxe.Unserializer;
#if sys
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;
#end

using StringTools;

typedef SuperlativeSettings = {
	public var showMacro:Bool;
	public var includeAll:Bool;
	public var loopCost:Int;
}

@:access(hscriptBase.Tools)
class Macro {
	public static final defaultSettings:SuperlativeSettings = {
		showMacro: false,
		includeAll: false,
		loopCost: 25
	}

	#if !macro
	public static final allClassesAvailable:Map<String, Class<Dynamic>> = hscriptBase.Tools.names.copy();
	#end

	public static var VERSION(default, null):SScriptVer = new SScriptVer(7, 7, 0);

	#if sys
	public static var isWindows(default, null):Bool = ~/^win/i.match(Sys.systemName());
	public static var definePath(get, never):String;
	#end

	static var credits:Array<String> = ["Special Thanks:", "- CrowPlexus\n",];

	public static var macroClasses:Array<Class<Dynamic>> = [
		Compiler,
		Context,
		MacroStringTools,
		Printer,
		ComplexTypeTools,
		TypedExprTools,
		ExprTools,
		TypeTools,
	];

	macro public static function initiateMacro() {
		var settings:SuperlativeSettings = defaultSettings;
		#if sys
		final defines = Context.getDefines();
		var pushedDefines:Array<String> = [];
		var string:String = "";
		for (i => k in defines) {
			if (!pushedDefines.contains(i)) {
				string += '$i|$k';
				string += '\n';
				pushedDefines.push(i);
			}
		}
		var splitString:Array<String> = string.split('\n');
		if (splitString.length > 1 && string.endsWith('\n')) {
			splitString.pop();
			string = splitString.join('\n');
		}

		var path:String = definePath;
		File.saveContent(path, new Base32().encodeString(string));
		#end

		if (defines.exists('openflPos') && (
			#if openfl
			#if (openfl < "9.2.0")
			true
			#else
			false
			#end
			#else
			true
			#end))
			#if (openfl < "9.2.0") Context.fatalError('Your openfl is outdated (${defines.get('openfl')}), please update openfl',
				(macro null).pos) #else Context.fatalError('You cannot use \'openflPos\' without targeting openfl', (macro null).pos) #end;

		Compiler.define('loop_unroll_max_cost', Std.string(settings.loopCost)); // Haxe will try to unroll big loops which may cause memory leaks
		if (settings.includeAll)
			Compiler.define('SUPERLATIVE_INCLUDE_ALL');
		return macro {}
	}

	public static function log(?log:String = "") {
		#if sys
		Sys.println(log);
		#else
		trace('\n' + log);
		#end
	}

	#if sys
	static function get_definePath():String {
		var env:String = if (isWindows) Sys.getEnv('USERPROFILE') else Sys.getEnv('HOME');
		if (isWindows && !env.endsWith('\\'))
			env += '\\';
		else if (!isWindows && !env.endsWith('/'))
			env += '/';

		return env + 'defines.cocoa';
	}
	#end
}