package psychlua;

#if LUA_ALLOWED
import hxluau.Types;

/**
 * Holds a Lua function that can be called from Haxe.
 * 
 * @see https://github.com/DragShot/linc_luajit/blob/master/llua/LuaCallback.hx
 * 
 * @author DragShot
 */
@:allow(psychlua.Convert)
class LuaFunction
{
	@:noCompletion
	private var l:Null<cpp.Pointer<Lua_State>>;

	@:noCompletion
	private var ref:Int;

	/**
	 * Creates a new LuaFunction instance.
	 * 
	 * @param l The Lua state pointer.
	 * @param ref The Lua function reference.
	 */
	private function new(l:cpp.Pointer<Lua_State>, ref:Int):Void
	{
		this.l = l;
		this.ref = ref;
	}

	/**
	 * Calls the Lua function.
	 * 
	 * @param args The function arguments.
	 * @return The function results as a Haxe array.
	 */
	public function call(args:Array<Dynamic>):Array<Dynamic>
	{
		if (l != null)
		{
			Lua.rawgeti(l.raw, Lua.REGISTRYINDEX, ref);

			return Convert.callFunctionWithoutName(l.raw, args);
		}

		return [];
	}

	/**
	 * Disposes of the Lua function reference.
	 */
	public function dispose():Void
	{
		if (l != null)
		{
			Lua.unref(l.raw, ref);
			l = null;
		}
	}
}
#end