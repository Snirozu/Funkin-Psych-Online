package online;

@:build(online.backend.Macros.getSetForwarder())
class FunkinPoints {
	@:forwardField(FlxG.save.data.funkinPointsv3, 0)
	public static var funkinPoints(get, set):Float;

    public static function calcFP(accuracy:Float, misses:Float, denseNotes:Float, notesHit:Float, maxCombo:Float, playbackRate:Float):Float {
		if (accuracy <= 0 || notesHit <= 0)
            return 0;

		// depends on player's hitted notes, and their weight
		var fp:Float = Math.max(1, 1 + denseNotes) * (notesHit / 100);
		fp *= 1 + maxCombo / 1000; // depends on player's note streak
		fp *= accuracy / (1 + misses * 0.25); // depends on player's note accuracy
		if (playbackRate < 1)
			fp *= playbackRate;
		return Math.ffloor(fp);
    }

	public static function save(accuracy:Float, misses:Float, denseNotes:Float, notesHit:Float, maxCombo:Float, playbackRate:Float) {
		var gained:Float = online.FunkinPoints.calcFP(accuracy, misses, denseNotes, notesHit, maxCombo, playbackRate);
		funkinPoints += gained;
		FlxG.save.flush();
		GameClient.send("updateFP", funkinPoints);
		return gained;
    }
}