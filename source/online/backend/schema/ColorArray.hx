// 
// THIS FILE HAS BEEN GENERATED AUTOMATICALLY
// DO NOT CHANGE IT MANUALLY UNLESS YOU KNOW WHAT YOU'RE DOING
// 
// GENERATED USING @colyseus/schema 2.0.35
// 

package online.backend.schema;

import io.colyseus.serializer.schema.Schema;
import io.colyseus.serializer.schema.types.*;

class ColorArray extends Schema {
	@:type("array", "number")
	public var value: ArraySchema<Dynamic> = new ArraySchema<Dynamic>();

}
