package online;

import flixel.FlxBasic;

//thread safe function handler
class Waiter extends FlxBasic {
    public static var queue:Array<Void->Void> = [];
    var _queueItem:Void->Void;

	public static function put(func:Void->Void) {
        queue.push(func);
    }

    override function update(elapsed) {
        super.update(elapsed);

		while (queue.length > 0) {
			_queueItem = queue.shift();
            
			if (_queueItem != null) {
				_queueItem();
            }
        }
    }
}