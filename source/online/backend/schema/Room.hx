// 
// THIS FILE HAS BEEN GENERATED AUTOMATICALLY
// DO NOT CHANGE IT MANUALLY UNLESS YOU KNOW WHAT YOU'RE DOING
// 
// GENERATED USING @colyseus/schema 2.0.26
// 

package online.backend.schema;

import io.colyseus.serializer.schema.Schema;
import io.colyseus.serializer.schema.types.*;

class Room extends Schema {
	@:type("string")
	public var song: String = "";

	@:type("string")
	public var folder: String = "";

	@:type("number")
	public var diff: Dynamic = 0;

	@:type("array", "string")
	public var diffList:ArraySchema<String> = new ArraySchema<String>();

	@:type("string")
	public var stageName: String = "";

	@:type("string")
	public var stageMod:String = "";

	@:type("string")
	public var stageURL:String = "";

	@:type("string")
	public var modDir: String = "";

	@:type("string")
	public var modURL: String = "";

	@:type("array", Player)
	public var players: ArraySchema<Player> = new ArraySchema<Player>();

	@:type("boolean")
	public var isPrivate: Bool = false;

	@:type("boolean")
	public var isStarted: Bool = false;

	@:type("boolean")
	public var swagSides: Bool = false;

	@:type("boolean")
	public var anarchyMode: Bool = false;

	@:type("number")
	public var health: Dynamic = 0;

	@:type("map", "string")
	public var gameplaySettings: MapSchema<String> = new MapSchema<String>();

	@:type("boolean")
	public var permitModifiers:Bool = false;
	
	@:type("boolean")
	public var hideGF:Bool = false;

	@:type("number")
	public var winCondition: Dynamic = 0;

	@:type("boolean")
	public var disableSkins:Bool = false;
}
