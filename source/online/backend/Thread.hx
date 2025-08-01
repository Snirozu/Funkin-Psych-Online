package online.backend;

import haxe.Exception;

class Thread {
    public static function run(func:Void->Void, ?onException:Exception->Void) {
        sys.thread.Thread.create(() -> {
            try {
                func();
            }
            catch (exc) {
				Waiter.putPersist(() -> { // waiter more errors please!
					if (onException != null)
                        onException(exc);
                    else
                        throw exc;
                });
            }
        });
    }

	public static function repeat(func:Void->Void, everySeconds:Float, ?onException:Exception->Void) {
		sys.thread.Thread.create(() -> {
            var running = true;
			try {
				while (running) {
					func();
					Sys.sleep(everySeconds);
                }
			}
			catch (exc) {
				running = false;
				Waiter.putPersist(() -> { // waiter more errors please!
					if (onException != null)
						onException(exc);
					else
						throw exc;
				});
			}
		});
    }

	public static function safeCatch(task:Void->Void, ?onException:Exception->Void) {
		try {
			task();
		}
		catch (exc:Dynamic) {
			Waiter.putPersist(() -> {
				if (onException != null)
					onException(exc);
				else
					throw exc;
			});
		}
	}
}