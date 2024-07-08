package online.vslice;

import hxjsonast.Json;
import hxjsonast.Tools;

class Poo {
	public static function dynamicParseValue(json:Json, name:String):Dynamic {
		return Tools.getValue(json);
	}

	public static function dynamicWriteValue(value:Dynamic):String {
		return haxe.Json.stringify(value);
	}
}