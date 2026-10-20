package psychlua;

import haxe.ds.StringMap;
import haxe.ds.IntMap;
import haxe.ds.ObjectMap;
import haxe.ds.EnumValueMap;
import haxe.Constraints.IMap;
import haxe.Exception;
import sys.io.File;
import sys.FileSystem;

#if HSCRIPT_ALLOWED
import hscript.*;
import hscript.Expr.Error;
import hscript.Parser;
#end

// much much code from codename shototutouts
// this is meant to be a substite of SScript

class PScript {
	@:unreflective public var interp(default, null):Interp;
	@:unreflective public var parser:Parser;
	@:unreflective public var expr:Expr;
	public var code:String = null;
	public var codeLines:Array<String> = null;
	public var scriptFile:String = null;
    public var active:Bool = true;
    @:noPrivateAccess var _destroyed(default, null):Bool = false;
	public var parsingException(default, null):Error;
	public var returnValue(default, null):Null<Dynamic>;
	@:unreflective public static var globalVariables:Map<String, Dynamic> = new Map<String, Dynamic>();
	@:unreflective public static var global(default, null):Map<String, PScript> = [];
	static var IDCount:Int = 0;
	var scriptID:String = Std.string(IDCount);

	public function new() {
		interp = new Interp();
		parser = getParser();
        preset();
	}

	public function destroy() {
		returnParser(parser);
		parser = null;
		interp = null;
        active = false;
        _destroyed = true;
		parsingException = null;
		returnValue = null;
		if (global.exists(scriptID))
			global.remove(scriptID);
	}
	public function set(field:String, value:Dynamic) {
        if (!active || _destroyed) return;

		interp.variables.set(field, value);
		// A runtime-injected variable may shadow a previously-cached VNotFound/type-resolve result, so drop stale cache entries.
		interp.invalidateCache();
	}
	public function exists(field:String) {
        if (!active || _destroyed) return false;

		if (interp.locals.exists(field))
			return true;
		return interp.variables.exists(field);
	}

    // public function execute() {
	// 	returnValue = null;

    //     @:privateAccess
	// 	interp.execute(parser.mk(EBlock([]), 0, 0));
	// 	if (expr != null) {
	// 		var r = interp.execute(expr);
	// 		returnValue = r;
	// 		call("new", []);
	// 	}
    // }

    public function preset() {
		// interp.importBlocklist = Deflection.classPathsBlacklist.copy();
		// localImportRedirects = online.backend.Deflection.CLASS_ALIASES.copy();

		interp.errorHandler = _errorHandler;
		interp.warnHandler = _warnHandler;

		for (i => k in globalVariables) {
			if (i != null)
				set(i, k);
		}
    }

    public function setSpecialObject(obj:Dynamic) {
        interp.scriptObject = obj;
    }

	/**
	 * Shared empty argument array, used when calling scripts without parameters (avoids allocations).
	 */
	private static final _EMPTY_ARRAY:Array<Dynamic> = [];
	private static final _EMPTY_ARRAY_EXC:Array<Exception> = [];
	public function call(field:String, ?args:Array<Dynamic>):AriCall {
		var value:Dynamic = null;
		try {
			if (_destroyed || !active) return throw new Exception('Script either destroyed or not active!');

			var func = interp.variables.get(field);
			func ??= interp.locals.get(field)?.r;
			
			if (func == null || !Reflect.isFunction(func)) {
				return throw new Exception('Field "${field}" doesn\'t exist or is not a function!');
			}

			value = Reflect.callMethod(null, func, args == null ? _EMPTY_ARRAY : args);			
		}
		catch (exc) {
			return {
				exceptions: [
					exc
				],
				calledFunction: field,
				succeeded: false,
				returnValue: null
			};
		}

		return {
			exceptions: _EMPTY_ARRAY_EXC,
			calledFunction: field,
			succeeded: true,
			returnValue: value
		};
	}

	//TODO rework it so scriptFile in a lua function pins to lua file
	public function doScript(code:String, ?scriptFile:String) {
		if (_destroyed || !active) return null;

		parsingException = null;

		try {
			if (code == null && scriptFile != null) {
				if (FileSystem.exists(scriptFile))
					code = File.getContent(scriptFile);
				else {
					code = scriptFile;
				}
			}
            

			if (code == null || code.length == 0)
				return null;

			this.code = code;
			this.codeLines = code?.split('\n');
			this.scriptFile = scriptFile;

			scriptID = scriptFile ?? (Std.string(IDCount++));

			global[scriptID] = this;

			expr = parser.parseString(code, scriptFile);
			if (expr != null)
				return interp.execute(expr);
		} 
		catch(e:Error) {
			parsingException = e;
			FunkinLua.trace(Std.string(e));
		}
		catch(e) {
			parsingException = new Error(ECustom(e.toString()), 0, 0, scriptFile, 0);
			FunkinLua.trace(Std.string(e));
		}

		return null;
	}

    public function doString(code:String, ?origin:String) {
        return doScript(code, origin);
    }

    public function doFile(scriptFile:String) {
        return doScript(null, scriptFile);
    }

	public static function initParser() {
		var parser = new Parser();
		parser.allowJSON = parser.allowMetadata = parser.allowTypes = true;
		return parser;
	}

	/** Pool of idle parsers, reused across script instances to avoid repeated Parser construction. **/
	private static var __parserPool:Array<Parser> = [];
	private static function getParser():Parser {
		var parser = __parserPool.pop();
		if (parser == null)
			return initParser();
		parser.line = 1; // reusing a parser only requires resetting `line`; all other vars get reset on parse
		return parser;
	}
	private static function returnParser(parser:Parser) {
		if (parser != null)
			__parserPool.push(parser);
	}

	private function _errorHandler(error:Error) {
		var fn = '${error.origin}:${error.line}: ';
		var err = error.toString();
		while(err.startsWith(fn)) {
			if (err.startsWith(fn)) err = err.substr(fn.length);
		}
		FunkinLua.trace('[ERROR] ${scriptFile}: ${error.line}::${codeLines[error.line - 1]?.trim()} -> ${err}');
	}

	private function _warnHandler(error:Error) {
		var fn = '${error.origin}:${error.line}: ';
		var err = error.toString();
		while(err.startsWith(fn)) {
			if (err.startsWith(fn)) err = err.substr(fn.length);
		}
		FunkinLua.trace('[WARNING] ${scriptFile}: ${error.line}::${codeLines[error.line - 1]?.trim()} -> ${err}');
	}
}

typedef AriCall = {
	/**
		Script's file name. Will be null if the script is not from a file. 

		Also not available on JavaScript.
	**/
	// public var ?fileName(default, null):String;

	/**
		If call's been successful or not. 
	**/
	public var succeeded(default, null):Bool;

	/**
		Function's name that has been called. 
	**/
	public var calledFunction(default, null):String;

	/**
		Function's return value. Will be if null if there is no value.
	**/
	public var returnValue(default, null):Null<Dynamic>;

	/**
		Errors in this call. Will be empty if there are not any.
	**/
	public var exceptions(default, null):Array<Exception>;
}

typedef PScriptGlobalMap = PScriptTypedGlobalMap<String, Dynamic>;

@:transitive
@:multiType(@:followWithAbstracts K)
@:access(psychlua.PScript)
abstract PScriptTypedGlobalMap<K, V>(Map.IMap<K, V>) {
	public function new();

	public inline function set(key:K, value:V) {
		this.set(key, value);

		var key:String = cast key;
		var value:Dynamic = cast value;
		for (i in PScript.global) {
			if (!i._destroyed)
				i.set(key, value);
		}
	}

	@:arrayAccess public inline function get(key:K)
		return this.get(key);

	public inline function exists(key:K)
		return this.exists(key);

	public inline function remove(key:K)
		return this.remove(key);

	public inline function keys():Iterator<K>
		return this.keys();

	public inline function iterator():Iterator<V>
		return this.iterator();

	public inline function keyValueIterator():KeyValueIterator<K, V>
		return this.keyValueIterator();

	public inline function copy():Map<K, V>
		return cast this.copy();

	public inline function toString():String
		return this.toString();

	public inline function clear():Void
		this.clear();

	@:arrayAccess @:noCompletion public inline function arrayWrite(k:K, v:V):V {
		this.set(k, v);
		var key:String = cast k;
		var value:Dynamic = cast v;
		for (i in PScript.global) {
			if (!i._destroyed)
				i.set(key, value);
		}
		return v;
	}

	@:to static inline function toStringMap<K:String, V>(t:IMap<K, V>):StringMap<V>
		return new StringMap<V>();

	@:to static inline function toIntMap<K:Int, V>(t:IMap<K, V>):IntMap<V>
		return new IntMap<V>();

	@:to static inline function toEnumValueMapMap<K:EnumValue, V>(t:IMap<K, V>):EnumValueMap<K, V>
		return new EnumValueMap<K, V>();

	@:to static inline function toObjectMap<K:{}, V>(t:IMap<K, V>):ObjectMap<K, V>
		return new ObjectMap<K, V>();

	@:from static inline function fromStringMap<V>(map:StringMap<V>):PScriptTypedGlobalMap<String, V>
		return cast map;

	@:from static inline function fromIntMap<V>(map:IntMap<V>):PScriptTypedGlobalMap<Int, V>
		return cast map;

	@:from static inline function fromObjectMap<K:{}, V>(map:ObjectMap<K, V>):PScriptTypedGlobalMap<K, V>
		return cast map;
}