package online.backend;

import flixel.FlxBasic;
import sys.thread.Mutex;

//thread safe function handler
class Waiter extends FlxBasic {
    // separated into two queues because sometimes a task is targeted to be run for a specific flxstate
    // this clears after the flxstate switches
	public static var stateQueue:Array<Dynamic> = [];
	private static var persistQueue(default, never):Array<Dynamic> = [];

    var _queueRAW:Dynamic;
    var _queueCall:Void->Void;
    var _queueCallPos:haxe.PosInfos;

	static var queueMutex:Mutex = new Mutex();

	public static function put(func:Void->Void, ?pos:haxe.PosInfos) {
		queueMutex.acquire();
		stateQueue.push([func, pos]);
		queueMutex.release();
    }

	public static function putPersist(func:Void->Void, ?pos:haxe.PosInfos) {
		queueMutex.acquire();
		persistQueue.push([func, pos]);
		queueMutex.release();
    }

	/**
		prepares a task for this state, but when the state switches this task will be removed
	**/
	// public static function prepare():WaiterReservation {
	// 	final reserve = new WaiterReservation();
	// 	return reserve;
	// }
 
    public static var pingServer:String;
    static var _elapsedPing:Float = 0;

	public static var waiterReports:String = '';
	function _tryQueueCall() {
		if (_queueRAW == null)
			return;

		_queueCall = cast _queueRAW[0];
		_queueCallPos = cast _queueRAW[1];

		try {
			if (_queueCall != null)
				_queueCall();
		}
		catch (exc) {
			waiterReports += 'Called for ${_queueCallPos.className}.${_queueCallPos.methodName} (${_queueCallPos.fileName} line ${_queueCallPos.lineNumber})\n';
			throw exc;
		}
	}

    override function update(elapsed) {
        super.update(elapsed);

		while (stateQueue.length > 0) {
		    queueMutex.acquire();
			_queueRAW = stateQueue.shift();
		    queueMutex.release();
			_tryQueueCall();
        }

		while (persistQueue.length > 0) {
		    queueMutex.acquire();
			_queueRAW = persistQueue.shift();
		    queueMutex.release();
			_tryQueueCall();
		}

		if (waiterReports.length > 0) {
			waiterReports = '';
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