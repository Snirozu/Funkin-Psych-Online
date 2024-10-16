package online;

@:build(online.backend.Macros.getSetForwarder())
class FunkinPoints {
	@:forwardField(FlxG.save.data.funkinPointsv2, 0)
	public static var funkinPoints(get, set):Float;

    public static function calcFP(accuracy:Float, misses:Float, noteDensity:Float, notesHit:Float, combo:Float, playbackRate:Float, songSpeed:Float):Float {
        if (accuracy <= 0)
            return 0;
		if (notesHit <= 0)
            return 0;
		//combo scaling is not a great idea due to making misses worth different amounts at different parts. it also just decimates FP if you miss at the end because its based off curent combo and not highest combo.
		//also like the amount of fp you actually get is like really low?? i feel like it should def be rewarding a bit more especially in FC and High Accuracy situations.
		//if you really want to keep combo scaling id suggest making it similar to beat saber. dont ask me how to do that though
		var fp:Float = notesHit / (noteDensity / 2);
		fp *= accuracy / (misses * 0.2 + 1) * (1 - noteDensity / 500);
		
		//Modifiers for song speed and scroll speed
		fp *= playbackRate;
		var scrollbonus:Float = 0.09526 * (Math.pow((0.8 * songSpeed - 1.6), 4)); // Scales FP in a parabala manner awarding playing on really low and really high speeds. ~1.2x at 0.5 and 3.5, 1.5x at 0(who would do this to themselves) and 4
		scrollbonus = Math.ffloor(1.5); // clamps previous bonus so people at scroll speed 5 dont start earning 4x FP
		fp *= scrollbonus;
		fp *= 5; // Im still undecided about this number but i do think FP should be a bit more plentiful
		if (misses > 0)
			fp *= 0.9; // locks 10% of FP behind a FC. Im not sure this works retroactivley like i want it to but it works enough.
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
// thanks to mmm salmon for helping me with the math on this 