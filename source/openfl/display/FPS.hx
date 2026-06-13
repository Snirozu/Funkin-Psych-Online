package openfl.display;

import haxe.Timer;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;
#if gl_stats
import openfl.display._internal.stats.Context3DStats;
import openfl.display._internal.stats.DrawCallContext;
#end
#if flash
import openfl.Lib;
#end

#if openfl
import openfl.system.System;
#end
import lime.system.System as LimeSystem;

/**
	The FPS class provides an easy-to-use monitor to display
	the current frame rate of an OpenFL project
**/
#if cpp
#if windows
@:cppFileCode('#include <windows.h>')
#elseif (ios || mac)
@:cppFileCode('#include <mach-o/arch.h>')
#else
@:headerInclude('sys/utsname.h')
#end
#end
#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class FPS extends TextField
{
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public var currentFPS(default, null):Int;

	@:noCompletion private var cacheCount:Int;
	@:noCompletion private var currentTime:Float;
	@:noCompletion private var times:Array<Float>;

	public var os:String = '';

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();

		if (LimeSystem.platformName == LimeSystem.platformVersion || LimeSystem.platformVersion == null)
			os = '\nOS: ${LimeSystem.platformName}' #if cpp + ' ${getArch() != 'Unknown' ? getArch() : ''}' #end;
		else
			os = '\nOS: ${LimeSystem.platformName}' #if cpp + ' ${getArch() != 'Unknown' ? getArch() : ''}' #end + ' - ${LimeSystem.platformVersion}';

		positionFPS(x, y);

		currentFPS = 0;
		selectable = false;
		mouseEnabled = false;
		defaultTextFormat = new TextFormat("_sans", 13, color);
		#if HACKER
		defaultTextFormat = new TextFormat("_sans", 16, color);
		#end
		autoSize = LEFT;
		multiline = true;
		text = "FPS: ";
		alpha = 0.9;

		cacheCount = 0;
		currentTime = 0;
		times = [];

		#if flash
		addEventListener(Event.ENTER_FRAME, function(e)
		{
			var time = Lib.getTimer();
			__enterFrame(time - currentTime);
		});
		#end
	}

	// Event Handlers
	@:noCompletion
	private #if !flash override #end function __enterFrame(deltaTime:Float):Void
	{
		currentTime += deltaTime;
		times.push(currentTime);

		while (times[0] < currentTime - 1000)
		{
			times.shift();
		}

		var currentCount = times.length;
		currentFPS = Math.round((currentCount + cacheCount) / 2);
		var optionFramerate = ClientPrefs.data.unlockFramerate ? 1000 : ClientPrefs.data.framerate;
		if (currentFPS > optionFramerate) currentFPS = optionFramerate;

		if (currentCount != cacheCount /*&& visible*/)
		{
			text = "FPS: " + currentFPS;
			
			#if cpp
			text += '\nRAM: ${flixel.util.FlxStringUtil.formatBytes(cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE))}';
			text += '\nPsych Online ' + Main.PSYCH_ONLINE_VERSION;
			#end

			#if !HACKER
			text += os;
			#end

			#if HACKER
			text = "";
			text += "Frames Per Second: " + currentFPS + "\n";
			@:privateAccess
			text += "Graphics Card: " + Std.string(flixel.FlxG.stage.context3D.gl.getParameter(flixel.FlxG.stage.context3D.gl.RENDERER)).split("/")[0].trim() + "\n";
			//text += "Operating System: " + LimeSystem.platformLabel + " " + LimeSystem.platformName + " " + LimeSystem.platformVersion + "\n";
			text += "Device Model: " + LimeSystem.deviceModel + " " + LimeSystem.deviceVendor + "\n";
			text += "Number of Connected Monitors: " + LimeSystem.numDisplays + "\n";
			text += "Game Location: " + LimeSystem.applicationDirectory + "\n";
			#end

			textColor = 0xFFFFFFFF;
			if (currentFPS <= optionFramerate / 2)
			{
				textColor = 0xFFFF0000;
			}

			#if (gl_stats && !disable_cffi && (!html5 || !canvas))
			text += "\ntotalDC: " + Context3DStats.totalDrawCalls();
			text += "\nstageDC: " + Context3DStats.contextDrawCalls(DrawCallContext.STAGE);
			text += "\nstage3DDC: " + Context3DStats.contextDrawCalls(DrawCallContext.STAGE3D);
			#end

			if (states.TitleState.inDev)
				text += "\n(" + Main.GIT_COMMIT.substr(0, 7) + ")";

			text += "\n";
		}

		cacheCount = currentCount;
	}

	public inline function positionFPS(X:Float, Y:Float, ?scale:Float = 1){
		scaleX = scaleY = #if android (scale > 1 ? scale : 1) #else (scale < 1 ? scale : 1) #end;
		x = FlxG.game.x + X;
		y = FlxG.game.y + Y;
	}

	#if cpp
	#if windows
	@:functionCode('
		SYSTEM_INFO osInfo;

		GetSystemInfo(&osInfo);

		switch(osInfo.wProcessorArchitecture)
		{
			case 9:
				return ::String("x86_64");
			case 5:
				return ::String("ARM");
			case 12:
				return ::String("ARM64");
			case 6:
				return ::String("IA-64");
			case 0:
				return ::String("x86");
			default:
				return ::String("Unknown");
		}
	')
	#elseif (ios || mac)
	@:functionCode('
		const NXArchInfo *archInfo = NXGetLocalArchInfo();
		return ::String(archInfo == NULL ? "Unknown" : archInfo->name);
	')
	#else
	@:functionCode('
		struct utsname osInfo{};
		uname(&osInfo);
		return ::String(osInfo.machine);
	')
	#end
	@:noCompletion
	private function getArch():String
	{
		return "Unknown";
	}
	#end
}