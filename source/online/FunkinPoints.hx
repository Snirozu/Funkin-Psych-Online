package online;

@:build(online.backend.Macros.getSetForwarder())
class FunkinPoints {
	@:forwardField(FlxG.save.data.funkinPointsv4, 0)
	public static var funkinPoints(get, set):Float;

    public static function calcFP(accuracy:Float, misses:Float, songDensity:Float, notesHit:Float, maxCombo:Float):Float {
		if (accuracy <= 0 || notesHit <= 0)
            return 0;


		// depends on the amount of hitted notes and the density of the song
		// density values for songs: 2.9p (unbeatable), 3.6 (ballistic), 4.2 (spookeez erect), 4.6 (sporting) 
		// so for a song with 4.0 density (ex. spookeez erect), for every 50 hitted notes a player will gain 1 fp (without combo bonus)
		var fp:Float = (1 + songDensity) * (notesHit / 200);
		// depends on player's note streak (x2fp per 2000 combo)
		fp *= 1 + maxCombo / 2000;
		// depends on player's note accuracy (weighted by power of 3; 95% = x0.85, 90% = x0.72, 80% = x0.512)
		fp *= Math.pow(accuracy, 3) / (1 + misses * 0.25);
		return Math.ffloor(fp);
    }

	public static function save(accuracy:Float, misses:Float, songDensity:Float, notesHit:Float, maxCombo:Float) {
		var gained:Float = online.FunkinPoints.calcFP(accuracy, misses, songDensity, notesHit, maxCombo);
		funkinPoints += gained;
		FlxG.save.flush();
		GameClient.send("updateFP", funkinPoints);
		return gained;
    }
}