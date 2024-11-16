package online;

@:build(online.backend.Macros.getSetForwarder())
class FunkinPoints {
	@:forwardField(FlxG.save.data.funkinPointsv3, 0)
	public static var funkinPoints(get, set):Float;

    public static function calcFP(accuracy:Float, misses:Float, denseNotes:Float, notesHit:Float, maxCombo:Float):Float {
		if (accuracy <= 0 || notesHit <= 0)
            return 0;

		// depends on player's hitted notes and the density of all notes
		var fp:Float = Math.max(1, 1 + denseNotes) * (notesHit / 200);
		// depends on player's note streak (1000 combo doubles base fp)
		fp *= 1 + maxCombo / 1000;
		// depends on player's note accuracy (weighted by power of 4; 95% = x0.81, 90% = x0.65, 80% = x0.40)
		fp *= Math.pow(accuracy, 5) / (1 + misses * 0.25);
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