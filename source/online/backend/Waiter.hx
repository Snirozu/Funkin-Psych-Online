package online.backend;

import flixel.FlxBasic;

//thread safe function handler
class Waiter extends FlxBasic {
    // separated into two queues because sometimes a task destined to be run for a specific state
    // runs after the state switches
	public static var stateQueue:Array<Void->Void> = [];
	private static var persistQueue(default, never):Array<Void->Void> = [];

    var _queueItem:Void->Void;

	public static function put(func:Void->Void) {
		stateQueue.push(func);
    }

	public static function putPersist(func:Void->Void) {
		persistQueue.push(func);
    }

    public static var pingServer:String;
    static var _elapsedPing:Float = 0;

    override function update(elapsed) {
        super.update(elapsed);

		while (stateQueue.length > 0) {
			_queueItem = stateQueue.shift();
            
			if (_queueItem != null) {
				_queueItem();
            }
        }

		while (persistQueue.length > 0) {
			_queueItem = persistQueue.shift();

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