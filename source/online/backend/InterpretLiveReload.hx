package online.backend;

import haxe.Timer;
import interpret.Env;
import interpret.DynamicModule;
import interpret.LiveReload;

/** A sample that instanciate a native class and automatically watch the source file.
	When the source file changes, the interpretable method (marked with @interpret) is updated on the fly
	without restarting the app. */
class InterpretLiveReload {
	public static function init() {
		// Assign a callback that will expose the modules we want to
		// interpretable code
		Env.configureInterpretableEnv = function(env) {
			// We expose this class because it need to be accessible
			// from its interpretable methods when they are reloaded as script
			env.addModule('online.states.RoomState', DynamicModule.fromStatic(online.states.RoomState));
			// StringTools can be used with `using` in dynamic classes because we exposed it
			env.addModule('StringTools', DynamicModule.fromStatic(StringTools));
			env.addModule('Math', DynamicModule.fromStatic(Math));
		};

		// Start live reload
		LiveReload.start();

		// Regularly call LiveReload.tick as it is necessary
		// to make it check files regularly
		var interval = 0.5; // Time in seconds between each tick
		var timer = new Timer(Math.round(interval * 1000));
		timer.run = function() LiveReload.tick(interval); // We call LiveReload.tick() with the elapsed time delta as

		// Log some info
		Sys.println('interpret is watching changes...');
	} // main
} // LiveReloadSample