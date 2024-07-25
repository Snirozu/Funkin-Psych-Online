package online;

@:build(online.Macros.getSetForwarder())
class FunkinPoints {
	@:forwardField(FlxG.save.data.funkinPointsv2, 0)
	public static var funkinPoints(get, set):Float;

    public static function calcFP(accuracy:Float, misses:Float, noteDensity:Float, notesHit:Float, combo:Float, playbackRate:Float, songSpeed:Float):Float {
        if (accuracy <= 0)
            return 0;
		if (notesHit <= 0)
            return 0;

		var fp:Float = notesHit / (noteDensity / 2);
		fp *= 1 + combo / 1000;
		fp *= accuracy / (misses * 0.2 + 1) * (1 - noteDensity / 500);
		fp *= playbackRate;
		var songSpeedAdd = songSpeed - 3.0;
		if (songSpeedAdd > 0)
			fp *= 1 + songSpeedAdd;
		return Math.ffloor(fp);
    }

	public static function save(accuracy:Float, misses:Float, noteDensity:Float, notesHit:Float, combo:Float, playbackRate:Float, songSpeed:Float) {
		var gained:Float = online.FunkinPoints.calcFP(accuracy, misses, noteDensity, notesHit, combo, playbackRate, songSpeed);
		funkinPoints += gained;
		FlxG.save.flush();
		GameClient.send("updateFP", funkinPoints);
		return gained;
    }
}