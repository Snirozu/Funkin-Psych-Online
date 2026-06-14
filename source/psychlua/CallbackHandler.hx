package psychlua;

import psychlua.FunkinLua.State;

class CallbackHandler
{
    public static inline function call(l:State, fname:String):Int
    {
        try
        {
            var cbf:Dynamic = null;

            //Local functions have the lowest priority
            //This is to prevent a "for" loop being called in every single operation,
            //so that it only loops on reserved/special functions
            if (cbf == null) {
                // trace('checking last script');
                var last:FunkinLua = FunkinLua.lastCalledScript;
                if (last == null || last.lua != l) {
                    // trace('looping thru scripts');
                    for (script in cast(PlayState.instance.luaArray, Array<Dynamic>)) {
                        var funk:FunkinLua = cast(script, FunkinLua);
                        if (funk != FunkinLua.lastCalledScript && funk != null && funk.lua == l) {
                            // trace('found script');
                            cbf = funk.callbacks.get(fname);
                            break;
                        }
                    }
                }
                else
                    cbf = last.callbacks.get(fname);
            }
            
            if (cbf == null) {
                return returnNil(l);
            }

            var nparams:Int = Lua.gettop(l);
            var args:Array<Dynamic> = [];

            for (i in 0...nparams) {
                args[i] = Convert.fromLua(l, i + 1);
            }

            var ret:Dynamic = null;
            /* return the number of results */

            ret = Reflect.callMethod(null, cbf, args);

            if(ret != null){
                Convert.toLua(l, ret);
                return 1;
            }
        }
        catch(e:Dynamic)
        {
            if (backend.ClientPrefs.isDebug() && e != null) {
                trace(fname);
                var alertMsg:String = "";
                var daError:String = "";
                var callStack = haxe.CallStack.exceptionStack(true);
    
                alertMsg += e + "\n";
                daError += haxe.CallStack.toString(callStack) + "\n";
                if (e is haxe.Exception)
                    daError += "\n" + cast(e, haxe.Exception).stack.toString() + "\n";
                alertMsg += daError;
    
                trace(alertMsg);
                FunkinLua.trace('Lua: CALLBACK ERROR! ${if (e.message != null) e.message else e}');
            }
        }
        return returnNil(l);
    }

    static function returnNil(l:State) {
        Convert.toLua(l, null);
        return 1;
    }
}