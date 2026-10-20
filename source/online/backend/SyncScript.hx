package online.backend;

#if HSCRIPT_ALLOWED
import hscript.Interp;
import sys.io.File;
import sys.FileSystem;

class SyncScript extends psychlua.PScript {
	public static var syncScript:SyncScript;
	public static var data:Any = {};
	public static var activeUpdate:Bool = false;

	public static function initScript(threaded:Bool = false) {
		resyncScript(threaded, () -> {
			dispatch("init");
		});
	}
    
	public static function resyncScript(threaded:Bool = true, ?onDone:Void->Void) {
		if (threaded) {
			Thread.run(() -> {
				var fetch = retrieveScript();
				online.backend.Waiter.putPersist(() -> {
					loadScript(fetch, onDone);
				});
			});
		}
		else {
			loadScript(retrieveScript(), onDone);
		}
	}

	static function retrieveScript():String {
		if (FileSystem.exists("sync.hxs") && ClientPrefs.isDebug()) {
			Alert.alert("[WARNING] Loaded some script from the local storage!!!");
			Log.info("loading sync script from local storage...");
			return File.getContent("sync.hxs");
		}
		else {
			if (ClientPrefs.isDebug())
				Log.info("loading sync script from git...");

			var url:String = '';
			switch (Main.repoHost) {
				case 'github':
					url = "https://raw.githubusercontent.com/Snirozu/Funkin-Psych-Online/main/sync.hxs";
				case 'codeberg':
					url = "https://codeberg.org/Snirozu/Funkin-Psych-Online/raw/branch/main/sync.hxs";
			}
			var http = new haxe.Http(url);
			if (ClientPrefs.isDebug())
				http.onError = function(error) {
					Log.errorTrace(error);
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
		set("print", s -> Log.println(s));
		set("typeof", s -> Type.getClassName(Type.getClass(s)));
		set("parent", this);
		set("alert", (title, ?message) -> Alert.alert(title, message));
	}
}
#end