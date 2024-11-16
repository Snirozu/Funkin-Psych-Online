package online;

@:build(online.backend.Macros.getSetForwarder())
class FunkinPoints {
	@:forwardField(FlxG.save.data.funkinPointsv4, 0)
	public static var funkinPoints(get, set):Float;

    public static function calcFP(accuracy:Float, misses:Float, denseNotes:Float, notesHit:Float, maxCombo:Float):Float {
		if (accuracy <= 0 || notesHit <= 0)
            return 0;

		// depends on player's hitted notes and the density of all notes
		// hard songs will average somewhere between 3.0 (spookeez erect) and 13.0 (ballistic)
		// so for a song with 3.0 density (ex. spookeez erect), for every ~65 hitted notes a player will gain 1 fp (without combo bonus)
		var fp:Float = Math.max(1, 1 + denseNotes) * (notesHit / 200);
		// depends on player's note streak (2000 combo will double base fp)
		fp *= 1 + maxCombo / 2000;
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