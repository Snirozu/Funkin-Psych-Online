package;

import states.MainMenuState;
import externs.WinAPI;
import haxe.Exception;
import flixel.graphics.FlxGraphic;

import flixel.FlxGame;
import flixel.FlxState;
import openfl.Assets;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display.StageScaleMode;
import lime.app.Application;
import states.TitleState;

#if linux
import lime.graphics.Image;
#end

import sys.FileSystem;

//crash handler stuff
#if CRASH_HANDLER
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import haxe.io.Path;
import sys.io.File;
import sys.io.Process;
#end

class Main extends Sprite
{
	var game = {
		width: 1280, // WINDOW width
		height: 720, // WINDOW height
		initialState: TitleState, // initial game state
		zoom: -1.0, // game state bounds
		framerate: 60, // default framerate
		skipSplash: true, // if the default flixel splash screen should be skipped
		startFullscreen: false // if the game should start at fullscreen mode
	};

	public static var fpsVar:FPS;

	public static final GIT_COMMIT:String = online.Macros.getGitCommitHash();

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();

		if (stage != null)
		{
			init();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		setupGame();
	}

	private function setupGame():Void
	{
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (game.zoom == -1.0)
		{
			var ratioX:Float = stageWidth / game.width;
			var ratioY:Float = stageHeight / game.height;
			game.zoom = Math.min(ratioX, ratioY);
			game.width = Math.ceil(stageWidth / game.zoom);
			game.height = Math.ceil(stageHeight / game.zoom);
		}

		CoolUtil.setDarkMode(true);

		#if hl
		sys.ssl.Socket.DEFAULT_VERIFY_CERT = false;
		#end
	
		#if LUA_ALLOWED Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(psychlua.CallbackHandler.call)); #end
		Controls.instance = new Controls();
		ClientPrefs.loadDefaultKeys();
		addChild(new FlxGame(game.width, game.height, game.initialState, #if (flixel < "5.0.0") game.zoom, #end game.framerate, game.framerate, game.skipSplash, game.startFullscreen));

		#if !mobile
		fpsVar = new FPS(10, 3, 0xFFFFFF);
		addChild(fpsVar);
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		if(fpsVar != null) {
			fpsVar.visible = ClientPrefs.data.showFPS;
		}
		#end

		#if linux
		var icon = Image.fromFile("icon.png");
		Lib.current.stage.window.setIcon(icon);
		#end

		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end
		
		#if CRASH_HANDLER
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		#end

		#if DISCORD_ALLOWED
		DiscordClient.start();
		#end

		// shader coords fix
		FlxG.signals.gameResized.add(function (w, h) {
		     if (FlxG.cameras != null) {
			   for (cam in FlxG.cameras.list) {
				@:privateAccess
				if (cam != null && cam._filters != null)
					resetSpriteCache(cam.flashSprite);
			   }
		     }

		     if (FlxG.game != null)
			 resetSpriteCache(FlxG.game);
		});

		//ONLINE STUFF, BELOW CODE USE FOR BACKPORTING

		var http = new haxe.Http("https://raw.githubusercontent.com/Snirozu/Funkin-Psych-Online/main/server_addresses.txt");
		http.onData = function(data:String) {
			for (address in data.split(',')) {
				online.GameClient.serverAddresses.push(address.trim());
			}
		}
		http.onError = function(error) {
			trace('error: $error');
		}
		http.request();
		online.GameClient.serverAddresses.push("ws://localhost:2567");

		online.Downloader.checkDeleteDlDir();

		addChild(new online.LoadingScreen());
		addChild(new online.Alert());
		addChild(new online.DownloadAlert.DownloadAlerts());

		FlxG.plugins.add(new online.Waiter());
		
		//for some reason only cancels 2 downloads
		Lib.application.window.onClose.add(() -> {
			#if DISCORD_ALLOWED
			DiscordClient.shutdown();
			#end
			online.Downloader.cancelAll();
			online.Downloader.checkDeleteDlDir();
		});

		Lib.application.window.onDropFile.add(path -> {
			if (FileSystem.isDirectory(path))
				return;

			online.Thread.run(() -> {
				online.LoadingScreen.toggle(true);
				online.OnlineMods.installMod(path);
				online.LoadingScreen.toggle(false);
			});
		});
		
		FlxG.signals.postStateSwitch.add(() -> {
			online.SyncScript.dispatch("switchState", [FlxG.state]);

			FlxG.state.subStateOpened.add(substate -> {
				online.SyncScript.dispatch("openSubState", [substate]);
			});
		});

		online.SyncScript.resyncScript(false, () -> {
			online.SyncScript.dispatch("init");
		});
	}

	static function resetSpriteCache(sprite:Sprite):Void {
		@:privateAccess {
		        sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}

	#if CRASH_HANDLER
	function onCrash(e:UncaughtErrorEvent):Void
	{
		var alertMsg:String = "";
		var daError:String = "";
		var path:String;
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var dateNow:String = Date.now().toString();

		dateNow = dateNow.replace(" ", "_");
		dateNow = dateNow.replace(":", "'");

		path = "./crash/" + "PsychEngine_" + dateNow + ".txt";

		alertMsg += e.error + "\n";
		daError += CallStack.toString(callStack) + "\n";
		if (e.error is Exception)
			daError += cast(e.error, Exception).stack.toString() + "\n";
		alertMsg += daError;

		Sys.println(alertMsg);

		if (!FileSystem.exists("./crash/"))
			FileSystem.createDirectory("./crash/");
		File.saveContent(path, alertMsg + "\n");
		Sys.println("Crash dump saved in " + Path.normalize(path));
		
		#if (windows && cpp)
		alertMsg += "\nDo you wish to report this error on GitHub?";
		WinAPI.alert("Uncaught Exception!", alertMsg, () -> {
			daError += '\nVersion: ${MainMenuState.psychOnlineVersion} ($GIT_COMMIT)';
			FlxG.openURL('https://github.com/Snirozu/Funkin-Psych-Online/issues/new?title=${StringTools.urlEncode('Exception: ${e.error}')}&body=${StringTools.urlEncode(daError)}');
		});
		#else
		Application.current.window.alert(alertMsg, "Uncaught Exception!");
		#end
		Sys.exit(1);
	}
	#end
}
