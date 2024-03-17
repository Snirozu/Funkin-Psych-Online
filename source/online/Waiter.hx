package online;

import flixel.FlxBasic;

//thread safe function handler
class Waiter extends FlxBasic {
    public static var queue:Array<Void->Void> = [];
    var _queueItem:Void->Void;

	public static function put(func:Void->Void) {
        queue.push(func);
    }

    public static var pingServer:String;
    static var _elapsedPing:Float = 0;

    override function update(elapsed) {
        super.update(elapsed);

		while (queue.length > 0) {
			_queueItem = queue.shift();
            
			if (_queueItem != null) {
				_queueItem();
            }
        }

		if (pingServer != null) {
			_elapsedPing += elapsed;

            if (_elapsedPing >= 20) {
				_elapsedPing = 0;
				GameClient.getServerPlayerCount(pingServer);
            }
        }
    }
}