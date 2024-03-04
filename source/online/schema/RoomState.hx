// 
// THIS FILE HAS BEEN GENERATED AUTOMATICALLY
// DO NOT CHANGE IT MANUALLY UNLESS YOU KNOW WHAT YOU'RE DOING
// 
// GENERATED USING @colyseus/schema 2.0.26
// 

package online.schema;

import io.colyseus.serializer.schema.Schema;
import io.colyseus.serializer.schema.types.*;

class RoomState extends Schema {
	@:type("string")
	public var song: String = "";

	@:type("string")
	public var folder: String = "";

	@:type("number")
	public var diff: Dynamic = 0;

	@:type("string")
	public var modDir: String = "";

	@:type("string")
	public var modURL: String = "";

	@:type("ref", Player)
	public var player1: Player = new Player();

	@:type("ref", Player)
	public var player2: Player = new Player();

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
}
