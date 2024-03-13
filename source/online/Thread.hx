package online;

class Thread {
    public static function run(func:Void->Void) {
        sys.thread.Thread.create(() -> {
            try {
                func();
            }
            catch (exc) {
                Waiter.put(() -> { // waiter more errors please!
                    throw exc;
                });
            }
        });
    }
}