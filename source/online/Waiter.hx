package online;

import flixel.FlxBasic;

//thread safe function handler
class Waiter extends FlxBasic {
    public static var queue:Array<Void->Void> = [];

	public static function put(func:Void->Void) {
        queue.push(func);
    }

    override function update(elapsed) {
        super.update(elapsed);

        for (_ in queue) {
			if (queue.shift() != null) {
				_();
            };
        }
    }
}