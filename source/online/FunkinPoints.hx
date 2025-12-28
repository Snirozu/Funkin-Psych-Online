package online;

@:build(online.backend.Macros.getSetForwarder())
class FunkinPoints {
	@:forwardField(FlxG.save.data.funkinPointsv4, 0)
	public static var funkinPoints(get, set):Float;

	public static function calcFP(accuracy:Float, misses:Float, songDensity:Float, notesHit:Float, maxCombo:Float):Float {
		// we floor the fp instead of rounding it, so you get less fp :)
		return Math.ffloor(FunkinPoints.fcalcFP(accuracy, misses, songDensity, notesHit, maxCombo));
	}

    public static function fcalcFP(accuracy:Float, misses:Float, songDensity:Float, notesHit:Float, maxCombo:Float):Float {
		if (accuracy <= 0 || notesHit <= 0)
            return 0;

		// depends on the amount of hitted notes and the density of the song
		// (density changes depending on the playbackRate of the song)
		// density values for songs: 2.9p (unbeatable), 3.6 (ballistic), 4.2 (spookeez erect), 4.6 (sporting) 
		// so for a song with 4.0 density (ex. spookeez erect), for every 50 hitted notes a player will gain 1 fp (without combo bonus)
		var fp:Float = (1 + songDensity) * (notesHit / 200);
		// depends on player's note streak (x2fp per 2000 combo)
		fp *= 1 + maxCombo / 2000;
		// depends on player's note accuracy (weighted by power of 3; 95% = x0.85, 90% = x0.72, 80% = x0.512)
		fp *= Math.pow(accuracy, 3) / (1 + misses * 0.25);
		return fp;
    }

	public static function devFP(accuracy:Float, misses:Float, songDensity:Float, notesHit:Float, maxCombo:Float) {

		// the current system works good for the most part, but there are three main issues with it
		// - missing a note does a big damage to FP
		// - bloat of FP on spammy songs leads to massive FP (1000+)
		// - casuals aren't able to gain so much fp

		// var fp:Float = Math.pow(1 + songDensity, 2.5) * Math.pow(accuracy, 2);
		// // fp *= Math.min(1000, Math.max(0, notesHit - 50)) / 1000;
		// fp *= (Math.max(0, notesHit) - Math.pow(notesHit, 1.05)) / 1000;
		// return fp;

		// todo: maybe make notesHit be divided by a value based on songDensity?
		var fp:Float = (1 + Math.pow(songDensity, 2)) * (notesHit / 200);
		// depends on player's note streak (x2fp per 4000 combo)
		fp *= 1 + maxCombo / 4000;
		// depends on player's note accuracy (weighted by power of 3; 95% = x0.85, 90% = x0.72, 80% = x0.512)
		fp *= Math.pow(accuracy, 2) / (1 + misses * 0.1);
		return fp;
	}

	public static function save(accuracy:Float, misses:Float, songDensity:Float, notesHit:Float, maxCombo:Float) {
		var gained:Float = online.FunkinPoints.calcFP(accuracy, misses, songDensity, notesHit, maxCombo);
		funkinPoints += gained;
		FlxG.save.flush();
		GameClient.send("updateFP", funkinPoints);
		return gained;
    }
}

/*
 -- -- SCRAPPED -- --

import js.html.Console;

class Test {
	static function main() {
		traceSong('supersaiyaninc', 8.1, 1053);
		traceSong('quadrupel', 6.2, 3448);
		traceSong('sporting', 6.8, 1131);
		traceSong('unbeatable', 5.3, 2487);
		traceSong('ballistic', 5.4, 869);
		traceSong('spookeezerect', 4.7, 913);
		traceSong('fresherect', 3.3, 285);
	}

	static function calcFP(accuracy:Float, misses:Float, songDensity:Float, notesHit:Float, maxCombo:Float):Float {
		if (accuracy <= 0 || notesHit <= 0)
            return 0;

		// example values for songs with playbackRate of 1.0x: 
		// * density=5.3 notes=2487 (unbeatable) 6 39FP
		// * density=5.4 notes=869 (ballistic)
		// * density=4.7 notes=913 (spookeez nightmare) 4.8 3FP
		// * density=6.8 notes=1131 (sporting)
		// * density=8.1 notes=1053 (super saiyan (mystery inc mix)) 8.9 100FP
		// * notes=3448 (quar) 6.6 117FP
		// (density changes depending on the playbackRate of the song)
		
		// initial calculation
		var fp:Float = (Math.pow(songDensity, 5) / 500) * (notesHit / 1000);
		// adds a multiplying bonus depending on player's max combo (x2fp per 2000)
		fp *= 1 + maxCombo / 2000;
		// depends on player's note accuracy (weighted by power of 3; 98% = x0.96, 95% = x0.9, 90% = x0.81, 80% = x0.64)
		fp *= Math.pow(accuracy, 2) / (1 + misses * 0.1);
		// we then floor the fp instead of rounding it, so you get less fp :)
		return Math.ffloor(fp);
	}

	static function traceSong(name:String, density:Float, notes:Float) {
		Console.log(name + ": ................ " + calcFP(1, 0, density, notes, notes) + "FP");
	}
}
*/