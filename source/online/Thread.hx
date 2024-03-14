package online;

import haxe.Exception;

class Thread {
    public static function run(func:Void->Void, ?onException:Exception->Void) {
        sys.thread.Thread.create(() -> {
            try {
                func();
            }
            catch (exc) {
                Waiter.put(() -> { // waiter more errors please!
					if (onException != null)
                        onException(exc);
                    else
                        throw exc;
                });
            }
        });
    }
}