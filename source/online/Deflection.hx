package online;

class Deflection {
    @:unreflective private var classBlacklist:Array<Class<Dynamic>> = null;

    public static function resolveClass(clsName:String) {
		if (classBlacklist == null)
			initClassBlacklist();

		var cls = Type.resolveClass(clsName);

		if (classBlacklist.contains(cls))
            return null;

		return cls;
    }

    private static function initClassBlacklist() {
		if (classBlacklist != null)
            return;

		// Add blacklisting for prohibited classes and packages.

		// `Sys`
		// Sys.command() can run malicious processes
		classBlacklist.push(Sys);

		// `Reflect`
		// Reflect.callMethod() can access blacklisted packages
		classBlacklist.push(Reflect);

		// `Type`
		// Type.createInstance(Type.resolveClass()) can access blacklisted packages
		classBlacklist.push(Type);

		// `cpp.Lib`
		// Lib.load() can load malicious DLLs
		classBlacklist.push(cpp.Lib);

		// `haxe.Unserializer`
		// Unserializerr.DEFAULT_RESOLVER.resolveClass() can access blacklisted packages
		classBlacklist.push(haxe.Unserializer);

		// `lime.system.CFFI`
		// Can load and execute compiled binaries.
		classBlacklist.push(lime.system.CFFI);

		// `lime.system.JNI`
		// Can load and execute compiled binaries.
		classBlacklist.push(lime.system.JNI);

		// `lime.system.System`
		// System.load() can load malicious DLLs
		classBlacklist.push(lime.system.System);

		// `openfl.desktop.NativeProcess`
		// Can load native processes on the host operating system.
		classBlacklist.push(openfl.desktop.NativeProcess);

		// `polymod.*`
		// Contains functions which may allow for un-blacklisting other modules.
		for (cls in ClassMacro.listClassesInPackage('polymod')) {
			if (cls == null)
				continue;
			classBlacklist.push(cls);
		}

		// `sys.*`
		// Access to system utilities such as the file system.
		for (cls in ClassMacro.listClassesInPackage('sys')) {
			if (cls == null)
				continue;
			classBlacklist.push(cls);
		}

		for (cls in ClassMacro.listClassesInPackage('tea')) {
			if (cls == null)
				continue;
			classBlacklist.push(cls);
		}

		for (cls in ClassMacro.listClassesInPackage('teaBase')) {
			if (cls == null)
				continue;
			classBlacklist.push(cls);
		}

		for (cls in ClassMacro.listClassesInPackage('lumod')) {
			if (cls == null)
				continue;
			classBlacklist.push(cls);
		}

        if (ClientPrefs.isDebug())
			trace(classBlacklist);
    }
}