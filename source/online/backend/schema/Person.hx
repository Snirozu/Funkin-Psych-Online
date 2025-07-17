// 
// THIS FILE HAS BEEN GENERATED AUTOMATICALLY
// DO NOT CHANGE IT MANUALLY UNLESS YOU KNOW WHAT YOU'RE DOING
// 
// GENERATED USING @colyseus/schema 2.0.35
// 

package online.backend.schema;

import io.colyseus.serializer.schema.Schema;
import io.colyseus.serializer.schema.types.*;

class Person extends Schema {
	@:type("string")
	public var name: String = "";

	@:type("number")
	public var ping: Dynamic = 0;

	@:type("boolean")
	public var hasSong: Bool = false;

	@:type("boolean")
	public var hasLoaded: Bool = false;

	@:type("boolean")
	public var verified: Bool = false;

	@:type("string")
	public var status: String = "";

}
