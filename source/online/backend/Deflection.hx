package online.backend;

import CompileTime;

class Deflection {
	//@:unreflective public static final luaClassBlacklist:Array<String> = ['cpp', 'lib', 'reflect', 'cffi', 'process', 'lua', 'http'];
    @:unreflective public static var classBlacklist(get, default):Array<Class<Dynamic>> = null;

    public static function resolveClass(clsName:String):Class<Dynamic> {
		var cls = Type.resolveClass(clsName);

		// if (clsName == 'hxcodec.flixel.FlxVideo' || clsName == 'vlc.MP4Handler') {
		// 	return online.backend.wrapper.FlxVideoWrapper;
		// }

		if (classBlacklist.contains(cls)) {
			PlayState.instance.addTextToDebug(clsName + ' is not accessible!', FlxColor.RED);
            return null;
		}

		return cls;
    }

	private static function get_classBlacklist() {
		if (classBlacklist == null)
			initClassBlacklist();
		return classBlacklist;
	}

    private static function initClassBlacklist() {
		var blacklist:Array<Class<Dynamic>> = [];

		// Add blacklisting for prohibited classes and packages.

		// `Sys`
		// Sys.command() can run malicious processes
		blacklist.push(Sys);

		// `Reflect`
		// Reflect.callMethod() can access blacklisted packages
		blacklist.push(Reflect);

		// `Type`
		// Type.createInstance(Type.resolveClass()) can access blacklisted packages
		blacklist.push(Type);

		// `cpp.Lib`
		// Lib.load() can load malicious DLLs
		blacklist.push(cpp.Lib);

		// `haxe.Unserializer`
		// Unserializerr.DEFAULT_RESOLVER.resolveClass() can access blacklisted packages
		blacklist.push(haxe.Unserializer);

		// `lime.system.CFFI`
		// Can load and execute compiled binaries.
		blacklist.push(lime.system.CFFI);

		// `lime.system.JNI`
		// Can load and execute compiled binaries.
		blacklist.push(lime.system.JNI);

		// `lime.system.System`
		// System.load() can load malicious DLLs
		blacklist.push(lime.system.System);

		// `openfl.desktop.NativeProcess`
		// Can load native processes on the host operating system.
		blacklist.push(openfl.desktop.NativeProcess);

		// `online.net` classes can access the network without player knowing
		blacklist.push(online.network.Auth);
		blacklist.push(online.network.FunkinNetwork);
		blacklist.push(online.network.Leaderboard);

		// FileUtils accesses files duh
		blacklist.push(online.util.FileUtils);
		blacklist.push(online.http.HTTPClient);

		// SyncScript can load malicious scripts
		blacklist.push(online.backend.SyncScript);

		// `polymod.*`
		// Contains functions which may allow for un-blacklisting other modules.
		for (cls in CompileTime.getAllClasses('polymod')) {
			if (cls == null)
				continue;
			blacklist.push(cls);
		}

		// `sys.*`
		// Access to system utilities such as the file system.
		for (cls in CompileTime.getAllClasses('sys')) {
			if (cls == null)
				continue;
			blacklist.push(cls);
		}

		for (cls in CompileTime.getAllClasses('tea')) {
			if (cls == null)
				continue;
			blacklist.push(cls);
		}

		for (cls in CompileTime.getAllClasses('teaBase')) {
			if (cls == null)
				continue;
			blacklist.push(cls);
		}

		for (cls in CompileTime.getAllClasses('lumod')) {
			if (cls == null)
				continue;
			blacklist.push(cls);
		}

		blacklist.push(CompileTime);

		#if (extension_androidtools)
		// `android.jni.JNICache`
		// Same as `lime.system.JNI`
		blacklist.push(android.jni.JNICache);
		#end

		classBlacklist = blacklist;

        if (ClientPrefs.isDebug())
			trace(classBlacklist);
    }
}