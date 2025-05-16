package psychlua;

class CallbackHandler
{
	public static inline function call(l:State, fname:String):Int
	{
		try
		{
			var cbf:Dynamic = Lua_helper.callbacks.get(fname);

			//Local functions have the lowest priority
			//This is to prevent a "for" loop being called in every single operation,
			//so that it only loops on reserved/special functions
			if(cbf == null) 
			{
				//trace('looping thru scripts');
				for (script in PlayState.instance.luaArray)
					if(script != null && script.lua == l)
					{
						//trace('found script');
						cbf = script.callbacks.get(fname);
						break;
					}
			}
			
			if(cbf == null) return 0;

			var nparams:Int = Lua.gettop(l);
			var args:Array<Dynamic> = [];

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
			if (!ClientPrefs.isDebug() || e == null) {
				return 0;
			}
			trace(fname);
			var alertMsg:String = "";
			var daError:String = "";
			var callStack = haxe.CallStack.exceptionStack(true);
			var dateNow = Date.now().toString();

			alertMsg += e + "\n";
			daError += haxe.CallStack.toString(callStack) + "\n";
			if (e is haxe.Exception)
				daError += "\n" + cast(e, haxe.Exception).stack.toString() + "\n";
			alertMsg += daError;

			trace(alertMsg);
			if(Lua_helper.sendErrorsToLua) {LuaL.error(l, 'CALLBACK ERROR! ${if(e.message != null) e.message else e}');return 0;}
			// throw(e);
		}
		return 0;
	}
}