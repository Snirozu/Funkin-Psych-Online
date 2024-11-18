package online;

@:build(online.backend.Macros.getSetForwarder())
class FunkinPoints {
	@:forwardField(FlxG.save.data.funkinPointsv4, 0)
	public static var funkinPoints(get, set):Float;

    public static function calcFP(accuracy:Float, misses:Float, denseNotes:Float, notesHit:Float, maxCombo:Float):Float {
		if (accuracy <= 0 || notesHit <= 0)
            return 0;


		// depends on the amount of hitted notes (1fp per 10-300 notes)
		var fp:Float = notesHit / denseNotes;
		// depends on player's note streak (x2fp per 1000 combo)
		fp *= 1 + maxCombo / 1000;
		// depends on player's note accuracy (weighted by power of 3; 95% = x0.85, 90% = x0.72, 80% = x0.512)
		fp *= Math.pow(accuracy, 3) / (1 + misses * 0.25);
		return Math.ffloor(fp);
    }

	public static function save(accuracy:Float, misses:Float, denseNotes:Float, notesHit:Float, maxCombo:Float) {
		var gained:Float = online.FunkinPoints.calcFP(accuracy, misses, denseNotes, notesHit, maxCombo);
		funkinPoints += gained;
		FlxG.save.flush();
		GameClient.send("updateFP", funkinPoints);
		return gained;
    }
}

// @:build(online.backend.Macros.getSetForwarder())
// class FunkinPoints {
// 	@:forwardField(FlxG.save.data.funkinPointsv4, 0)
// 	public static var funkinPoints(get, set):Float;

// 	public static function calcFP(accuracy:Float, misses:Float, notesHit:Float, maxCombo:Float):Float {
// 		if (accuracy <= 0 || notesHit <= 0)
// 			return 0;

// 		// depends on player's hitted notes (1fp per 100 hitted notes)
// 		var fp:Float = notesHit / 100;
// 		// depends on player's note streak (x2fp per 500 combo)
// 		fp *= 1 + maxCombo / 500;
// 		// depends on player's note accuracy (weighted by power of 3; 95% = x0.85, 90% = x0.72, 80% = x0.512)
// 		fp *= Math.pow(accuracy, 3) / (1 + misses * 0.25);
// 		return Math.ffloor(fp);
// 	}

// 	public static function save(accuracy:Float, misses:Float, notesHit:Float, maxCombo:Float) {
// 		var gained:Float = online.FunkinPoints.calcFP(accuracy, misses, notesHit, maxCombo);
// 		funkinPoints += gained;
// 		FlxG.save.flush();
// 		GameClient.send("updateFP", funkinPoints);
// 		return gained;
// 	}
// }