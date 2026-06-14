package psychlua;

import Type.ValueType;
import haxe.Constraints;

import substates.GameOverSubstate;

//
// Functions that use a high amount of Reflections, which are somewhat CPU intensive
// These functions are held together by duct tape
//

class ReflectionFunctions
{
	public static function implement(funk:FunkinLua)
	{
		var lua:State = funk.lua;
		funk.set("getProperty", function(variable:String, ?allowMaps:Bool = true) {
			backend.CoolUtil.teleStamp(true);
			variable = online.backend.Wrapper.wrapperField(variable);
			backend.CoolUtil.teleStamp();

			var split:Array<String> = variable.split('.');
			backend.CoolUtil.teleStamp();
			if(split.length > 1)
				return LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split, true, true, allowMaps), split[split.length-1], allowMaps);
			backend.CoolUtil.teleStamp();
			final ret = LuaUtils.getVarInArray(LuaUtils.getTargetInstance(), variable, allowMaps);
			backend.CoolUtil.teleStamp();
			return ret;
		});
		funk.set("setProperty", function(variable:String, value:Dynamic, allowMaps:Bool = true) {
			variable = online.backend.Wrapper.wrapperField(variable);

			var split:Array<String> = variable.split('.');
			if(split.length > 1) {
				LuaUtils.setVarInArray(LuaUtils.getPropertyLoop(split, true, true, allowMaps), split[split.length-1], value, allowMaps);
				return true;
			}
			LuaUtils.setVarInArray(LuaUtils.getTargetInstance(), variable, value, allowMaps);
			return true;
		});
		funk.set("getPropertyFromClass", function(classVar:String, variable:String, ?allowMaps:Bool = true):Dynamic {
			if (classVar == 'flixel.FlxG' && variable.startsWith('keys')) {
				var why = variable.split('.');
				switch (why[1]) {
					case 'pressed':
						return ExtraFunctions.luaPressed(why[2]);
					case 'justPressed':
						return ExtraFunctions.luaJustPressed(why[2]);
					case 'justReleased':
						return ExtraFunctions.luaJustReleased(why[2]);
				}
			}

			variable = online.backend.Wrapper.wrapperClassField(classVar, variable);
			classVar = online.backend.Wrapper.wrapperClass(classVar);
			
			var myClass:Dynamic = Deflection.resolveClass(classVar);
			if(myClass == null)
			{
				funk.luaTrace('getPropertyFromClass: Class $classVar not found', false, false, FlxColor.RED);
				return null;
			}

			var split:Array<String> = variable.split('.');
			if(split.length > 1) {
				var obj:Dynamic = LuaUtils.getVarInArray(myClass, split[0], allowMaps);
				for (i in 1...split.length-1)
					obj = LuaUtils.getVarInArray(obj, split[i], allowMaps);

				return LuaUtils.getVarInArray(obj, split[split.length-1], allowMaps);
			}
			return LuaUtils.getVarInArray(myClass, variable, allowMaps);
		});
		funk.set("setPropertyFromClass", function(classVar:String, variable:String, value:Dynamic, ?allowMaps:Bool = true) {
			variable = online.backend.Wrapper.wrapperClassField(classVar, variable);
			classVar = online.backend.Wrapper.wrapperClass(classVar);

			var myClass:Dynamic = Deflection.resolveClass(classVar);
			if(myClass == null)
			{
				funk.luaTrace('getPropertyFromClass: Class $classVar not found', false, false, FlxColor.RED);
				return null;
			}

			var split:Array<String> = variable.split('.');
			if(split.length > 1) {
				var obj:Dynamic = LuaUtils.getVarInArray(myClass, split[0], allowMaps);
				for (i in 1...split.length-1)
					obj = LuaUtils.getVarInArray(obj, split[i], allowMaps);

				LuaUtils.setVarInArray(obj, split[split.length-1], value, allowMaps);
				return value;
			}
			LuaUtils.setVarInArray(myClass, variable, value, allowMaps);
			return value;
		});
		funk.set("getPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic, ?allowMaps:Bool = true) {
			var split:Array<String> = obj.split('.');
			var realObject:Dynamic = null;
			if(split.length > 1)
				realObject = LuaUtils.getPropertyLoop(split, true, false, allowMaps);
			else
				realObject = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);

			if(Std.isOfType(realObject, FlxTypedGroup))
			{
				var result:Dynamic = LuaUtils.getGroupStuff(realObject.members[index], variable, allowMaps);
				return result;
			}

			var leArray:Dynamic = realObject[index];
			if(leArray != null) {
				var result:Dynamic = null;
				if(Type.typeof(variable) == ValueType.TInt)
					result = leArray[variable];
				else
					result = LuaUtils.getGroupStuff(leArray, variable, allowMaps);
				return result;
			}
			funk.luaTrace("getPropertyFromGroup: Object #" + index + " from group: " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return null;
		});
		funk.set("setPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic, value:Dynamic, ?allowMaps:Bool = true) {
			var split:Array<String> = obj.split('.');
			var realObject:Dynamic = null;
			if(split.length > 1)
				realObject = LuaUtils.getPropertyLoop(split, true, false, allowMaps);
			else
				realObject = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);

			if(Std.isOfType(realObject, FlxTypedGroup)) {
				LuaUtils.setGroupStuff(realObject.members[index], variable, value, allowMaps);
				return value;
			}

			if(realObject == null)
			{
				funk.luaTrace('setPropertyFromGroup: Object $obj is not valid!', false, false, FlxColor.RED);
				return null;
			}

			var leArray:Dynamic = realObject[index];
			if(leArray != null) {
				if(Type.typeof(variable) == ValueType.TInt) {
					leArray[variable] = value;
					return value;
				}
				LuaUtils.setGroupStuff(leArray, variable, value, allowMaps);
			}
			return value;
		});
		funk.set("addToGroup", function(group:String, tag:String, ?index:Int = -1) {
			var obj:FlxSprite = LuaUtils.getObjectDirectly(tag);
			if(obj == null || obj.destroy == null)
			{
				funk.luaTrace('addToGroup: Object $tag is not valid!', false, false, FlxColor.RED);
				return;
			}

			// uiGroup and such is not existent in psych online, so we can sorta imitate it by just adding it onto PlayState
			if(['comboGroup', 'uiGroup', 'noteGroup'].contains(group))
			{
				PlayState.instance.add(obj);
				return;
			}

			var groupOrArray:Dynamic = Reflect.getProperty(LuaUtils.getTargetInstance(), group);
			if(groupOrArray == null)
			{
				funk.luaTrace('addToGroup: Group/Array $group is not valid!', false, false, FlxColor.RED);
				return;
			}

			if(index < 0)
			{
				switch(Type.typeof(groupOrArray))
				{
					case TClass(Array): //Is Array
						groupOrArray.push(obj);

					default: //Is Group
						groupOrArray.add(obj);
				}
			}
			else groupOrArray.insert(index, obj);
		});
		funk.set("removeFromGroup", function(obj:String, index:Int, dontDestroy:Bool = false) {
			var groupOrArray:Dynamic = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
			if(Std.isOfType(groupOrArray, FlxTypedGroup)) {
				var sex = groupOrArray.members[index];
				if(!dontDestroy)
					sex.kill();
				groupOrArray.remove(sex, true);
				if(!dontDestroy)
					sex.destroy();
				return;
			}
			groupOrArray.remove(groupOrArray[index]);
		});
		
		funk.set("callMethod", function(funcToRun:String, ?args:Array<Dynamic> = null) {
			return callMethodFromObject(PlayState.instance, funcToRun, args);
			
		});
		funk.set("callMethodFromClass", function(className:String, funcToRun:String, ?args:Array<Dynamic> = null) {
			return callMethodFromObject(Deflection.resolveClass(className), funcToRun, args);
		});

		funk.set("createInstance", function(variableToSave:String, className:String, ?args:Array<Dynamic> = null) {
			variableToSave = variableToSave.trim().replace('.', '');
			if(!PlayState.instance.variables.exists(variableToSave))
			{
				if(args == null) args = [];
				var myType:Dynamic = Deflection.resolveClass(className);
		
				if(myType == null)
				{
					funk.luaTrace('createInstance: Variable $variableToSave is already being used and cannot be replaced!', false, false, FlxColor.RED);
					return false;
				}

				var obj:Dynamic = Type.createInstance(myType, args);
				if(obj != null)
					PlayState.instance.variables.set(variableToSave, obj);
				else
					funk.luaTrace('createInstance: Failed to create $variableToSave, arguments are possibly wrong.', false, false, FlxColor.RED);

				return (obj != null);
			}
			else funk.luaTrace('createInstance: Variable $variableToSave is already being used and cannot be replaced!', false, false, FlxColor.RED);
			return false;
		});
		funk.set("addInstance", function(objectName:String, ?inFront:Bool = false) {
			if(PlayState.instance.variables.exists(objectName))
			{
				var obj:Dynamic = PlayState.instance.variables.get(objectName);
				if (inFront)
					LuaUtils.getTargetInstance().add(obj);
				else
				{
					if(!PlayState.instance.isDead)
						PlayState.instance.insert(PlayState.instance.members.indexOf(LuaUtils.getLowestCharacterGroup()), obj);
					else
						GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), obj);
				}
			}
			else funk.luaTrace('addInstance: Can\'t add what doesn\'t exist~ ($objectName)', false, false, FlxColor.RED);
		});
	}

	static function callMethodFromObject(classObj:Dynamic, funcStr:String, args:Array<Dynamic> = null)
	{
		if(args == null) args = [];

		var split:Array<String> = funcStr.split('.');
		var funcToRun:Function = null;
		var obj:Dynamic = classObj;
		//trace('start: $obj');
		if(obj == null)
		{
			return null;
		}

		for (i in 0...split.length)
		{
			obj = LuaUtils.getVarInArray(obj, split[i].trim());
			//trace(obj, split[i]);
		}

		funcToRun = cast obj;
		//trace('end: $obj');
		return funcToRun != null ? Reflect.callMethod(obj, funcToRun, args) : null;
	}
}