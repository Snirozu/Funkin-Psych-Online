// 
// THIS FILE HAS BEEN GENERATED AUTOMATICALLY
// DO NOT CHANGE IT MANUALLY UNLESS YOU KNOW WHAT YOU'RE DOING
// 
// GENERATED USING @colyseus/schema 2.0.35
// 

package online.backend.schema;

import io.colyseus.serializer.schema.Schema;
import io.colyseus.serializer.schema.types.*;

class Player extends Person {
	@:type("number")
	public var ox: Dynamic = 0;

	@:type("number")
	public var score: Dynamic = 0;

	@:type("number")
	public var misses: Dynamic = 0;

	@:type("number")
	public var sicks: Dynamic = 0;

	@:type("number")
	public var goods: Dynamic = 0;

	@:type("number")
	public var bads: Dynamic = 0;

	@:type("number")
	public var shits: Dynamic = 0;

	@:type("number")
	public var songPoints: Dynamic = 0;

	@:type("number")
	public var maxCombo: Dynamic = 0;

	@:type("boolean")
	public var bfSide: Bool = false;

	@:type("boolean")
	public var hasEnded: Bool = false;

	@:type("boolean")
	public var isReady: Bool = false;

	@:type("string")
	public var skinMod: String = "";

	@:type("string")
	public var skinName: String = "";

	@:type("string")
	public var skinURL: String = "";

	@:type("number")
	public var points: Dynamic = 0;

	@:type("boolean")
	public var botplay: Bool = false;

	@:type("boolean")
	public var noteHold: Bool = false;

	@:type("string")
	public var noteSkin: String = "";

	@:type("string")
	public var noteSkinMod: String = "";

	@:type("string")
	public var noteSkinURL: String = "";

	@:type("map", "string")
	public var gameplaySettings:MapSchema<String> = new MapSchema<String>();

	@:type("map", ColorArray)
	public var arrowColors: MapSchema<ColorArray> = new MapSchema<ColorArray>();

	@:type("map", ColorArray)
	public var arrowColorsPixel: MapSchema<ColorArray> = new MapSchema<ColorArray>();

}
