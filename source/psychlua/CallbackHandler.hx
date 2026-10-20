package psychlua;

class CallbackHandler
{
	public static inline function call(l:State, fname:String):Int
	{
		var args:Array<Dynamic> = [];
		try
		{
			var cbf:Dynamic = Lua_helper.stateStorage[l].callbacks.get(fname);

			//Local functions have the lowest priority
			//This is to prevent a "for" loop being called in every single operation,
			//so that it only loops on reserved/special functions
			if (cbf == null) {
				// Log.trace('checking last script');
				var last:FunkinLua = FunkinLua.lastCalledScript;
				if (last == null || last.lua != l) {
					// Log.trace('looping thru scripts');
					for (script in PlayState.instance.luaArray)
						if (script != FunkinLua.lastCalledScript && script != null && script.lua == l) {
							// Log.trace('found script');
							cbf = script.callbacks?.get(fname);
							break;
						}
				}
				else
					cbf = last.callbacks?.get(fname);
			}
			
			if (cbf == null) {
				return returnNil(l);
			}

			var nparams:Int = Lua.gettop(l);

			for (i in 0...nparams) {
				args[i] = Convert.fromLua(l, i + 1);
			}

			var ret:Dynamic = null;
			/* return the number of results */

			ret = Reflect.callMethod(null,cbf,args);

			if(ret != null){
				Convert.toLua(l, ret);
				return 1;
			}
		}
		catch(e:Dynamic)
		{
			if (ClientPrefs.isDebug() && e != null) {
				var alertMsg:String = "";
				var daError:String = "";
				var callStack = haxe.CallStack.exceptionStack(true);
	
				alertMsg += '${fname}(${args.join(', ')}) -> ${if (e.message != null) e.message else e}\n';
				daError += haxe.CallStack.toString(callStack) + "\n";
				if (e is haxe.Exception)
					daError += "\n" + cast(e, haxe.Exception).stack.toString() + "\n";
				alertMsg += daError;
	
				FunkinLua.trace('Lua: CALLBACK ERROR! ' + alertMsg);
				//if(Lua_helper.sendErrorsToLua) {LuaL.error(l, 'CALLBACK ERROR! ${if(e.message != null) e.message else e}');return 0;}
				// throw(e);
			}
		}
		return returnNil(l);
	}

	static function returnNil(l:State) {
		Convert.toLua(l, null);
		return 1;
	}
}