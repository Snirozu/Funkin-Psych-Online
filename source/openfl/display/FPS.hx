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

/**
	The FPS class provides an easy-to-use monitor to display
	the current frame rate of an OpenFL project
**/
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

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();

		this.x = x;
		this.y = y;

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
		var optionFramerate = ClientPrefs.data.unlockFramerate ? 999 : ClientPrefs.data.framerate;
		if (currentFPS > optionFramerate) currentFPS = optionFramerate;

		if (currentCount != cacheCount /*&& visible*/)
		{
			text = "FPS: " + currentFPS;
			var memoryMegas:Float = 0;
			
			#if openfl
			memoryMegas = Math.abs(FlxMath.roundDecimal(System.totalMemory / 1000000, 1));
			text += "\nRAM: " + memoryMegas + " MB";
			#end

			#if HACKER
			text = "";
			text += "Frames Per Second: " + currentFPS + "\n";
			text += "Computer Memory: " + memoryMegas + "MB\n";
			@:privateAccess
			text += "Graphics Card: " + Std.string(flixel.FlxG.stage.context3D.gl.getParameter(flixel.FlxG.stage.context3D.gl.RENDERER)).split("/")[0].trim() + "\n";
			text += "Operating System: " + lime.system.System.platformLabel + " " + lime.system.System.platformName + " " + lime.system.System.platformVersion + "\n";
			text += "Device Model: " + lime.system.System.deviceModel + " " + lime.system.System.deviceVendor + "\n";
			text += "Number of Connected Monitors: " + lime.system.System.numDisplays + "\n";
			text += "Game Location: " + lime.system.System.applicationDirectory + "\n";
			#end

			textColor = 0xFFFFFFFF;
			if (memoryMegas > 3000 || currentFPS <= optionFramerate / 2)
			{
				textColor = 0xFFFF0000;
			}

			#if (gl_stats && !disable_cffi && (!html5 || !canvas))
			text += "\ntotalDC: " + Context3DStats.totalDrawCalls();
			text += "\nstageDC: " + Context3DStats.contextDrawCalls(DrawCallContext.STAGE);
			text += "\nstage3DDC: " + Context3DStats.contextDrawCalls(DrawCallContext.STAGE3D);
			#end

			text += "\n";
		}

		cacheCount = currentCount;
	}
}
