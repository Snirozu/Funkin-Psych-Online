package online;

import tea.SScript;
import sys.io.File;
import sys.FileSystem;

class SyncScript extends SScript {
	public static var syncScript:SyncScript;
	public static var data:Any = {};
    
	public static function resyncScript(threaded:Bool = true, ?onDone:Void->Void) {
		if (threaded) {
			Thread.run(() -> {
				var fetch = retrieveScript();
				online.Waiter.put(() -> {
					loadScript(fetch, onDone);
				});
			});
		}
		else {
			loadScript(retrieveScript(), onDone);
		}
	}

	static function retrieveScript():String {
		if (FileSystem.exists("sync.hxs")) {
			if (ClientPrefs.isDebug())
				trace("loading sync script from local storage...");
			return File.getContent("sync.hxs");
		}
		else {
			if (ClientPrefs.isDebug())
				trace("loading sync script from git...");
			var http = new haxe.Http("https://raw.githubusercontent.com/Snirozu/Funkin-Psych-Online/main/sync.hxs");
			if (ClientPrefs.isDebug())
				http.onError = function(error) {
					trace('error: $error');
				}
			http.request();
			return http.responseData;
		}
	}

	static function loadScript(script:String, ?onDone:Void->Void) {
		syncScript = new SyncScript();
		syncScript.doString(script);

		if (onDone != null)
			onDone();
	}

	public static function dispatch(func:String, ?args:Array<Any>) {
		if (syncScript != null && !syncScript._destroyed) {
			return syncScript.call(func, args).returnValue;
		}
		return null;
	}

	override function preset() {
		super.preset();

		set("data", data);
		set("print", s -> Sys.println(s));
		set("typeof", s -> Type.getClassName(Type.getClass(s)));
	}
}