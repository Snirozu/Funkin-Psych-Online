package backend;

import flixel.FlxG;
import flixel.util.FlxTimer;

class Highscore
{
    public static var weekScores:haxe.ds.StringMap<Int> = new haxe.ds.StringMap();
    public static var songScores:haxe.ds.StringMap<Int> = new haxe.ds.StringMap();
    public static var songRating:haxe.ds.StringMap<Float> = new haxe.ds.StringMap();

    private static var needsFlush:Bool = false;

    private static var autoSaveTimer:FlxTimer = null;

    public static function resetSong(song:String, diff:Int = 0):Void
    {
        var daSong:String = formatSong(song, diff);
        setScore(daSong, 0);
        setRating(daSong, 0);
    }

    public static function resetWeek(week:String, diff:Int = 0):Void
    {
        var daWeek:String = formatSong(week, diff);
        setWeekScore(daWeek, 0);
    }

    public static function saveScore(song:String, score:Int = 0, ?diff:Int = 0, ?rating:Float = -1):Void
    {
        var daSong:String = formatSong(song, diff);

        var prev:Int = songScores.get(daSong);
        if (prev == null || prev < score) {
            setScore(daSong, score);
            if (rating >= 0) setRating(daSong, rating);
        }
    }

    public static function saveWeekScore(week:String, score:Int = 0, ?diff:Int = 0):Void
    {
        var daWeek:String = formatSong(week, diff);

        var prev:Int = weekScores.get(daWeek);
        if (prev == null || prev < score) {
            setWeekScore(daWeek, score);
        }
    }

    /**
     * YOU SHOULD FORMAT SONG WITH formatSong() BEFORE TOSSING IN SONG VARIABLE
     */
    static function setScore(song:String, score:Int):Void
    {
        songScores.set(song, score);
        markDirty();
    }
    static function setWeekScore(week:String, score:Int):Void
    {
        weekScores.set(week, score);
        markDirty();
    }

    static function setRating(song:String, rating:Float):Void
    {
        songRating.set(song, rating);
        markDirty();
    }

    private static function markDirty():Void
    {
        needsFlush = true;
    }

    private static function mapToObject<T>(m:haxe.ds.StringMap<T>):Dynamic
    {
        var o = {};
        for (k in m.keys())
        {
            o[k] = m.get(k);
        }
        return o;
    }

    private static function objectToMap_Int(obj:Dynamic):haxe.ds.StringMap<Int>
    {
        var m = new haxe.ds.StringMap<Int>();
        if (obj == null) return m;
        for (k in Reflect.fields(obj))
        {
            var v = Reflect.field(obj, k);
            m.set(k, (v == null ? 0 : (Std.is(v, Int) ? v : Std.parseInt(v))));
        }
        return m;
    }

    private static function objectToMap_Float(obj:Dynamic):haxe.ds.StringMap<Float>
    {
        var m = new haxe.ds.StringMap<Float>();
        if (obj == null) return m;
        for (k in Reflect.fields(obj))
        {
            var v = Reflect.field(obj, k);
            m.set(k, (v == null ? 0.0 : (Std.is(v, Float) ? v : Std.parseFloat(v))));
        }
        return m;
    }

    public static function formatSong(song:String, diff:Int):String
    {
        return Paths.formatToSongPath(song) + Difficulty.getFilePath(diff);
    }

    public static function getScore(song:String, diff:Int):Int
    {
        var daSong:String = formatSong(song, diff);
        var v = songScores.get(daSong);
        if (v == null) {
            setScore(daSong, 0);
            return 0;
        }
        return v;
    }

    public static function getRating(song:String, diff:Int):Float
    {
        var daSong:String = formatSong(song, diff);
        var v = songRating.get(daSong);
        if (v == null) {
            setRating(daSong, 0);
            return 0;
        }
        return v;
    }

    public static function getWeekScore(week:String, diff:Int):Int
    {
        var daWeek:String = formatSong(week, diff);
        var v = weekScores.get(daWeek);
        if (v == null) {
            setWeekScore(daWeek, 0);
            return 0;
        }
        return v;
    }

    public static function load():Void
    {
        var d = FlxG.save.data;
        if (d == null) return;

        if (d.weekScores != null)
        {
            weekScores = objectToMap_Int(d.weekScores);
        }
        if (d.songScores != null)
        {
            songScores = objectToMap_Int(d.songScores);
        }
        if (d.songRating != null)
        {
            songRating = objectToMap_Float(d.songRating);
        }

        needsFlush = false;
    }

    public static function flush():Void
    {
        if (!needsFlush) return;

        FlxG.save.data.weekScores = mapToObject(weekScores);
        FlxG.save.data.songScores = mapToObject(songScores);
        FlxG.save.data.songRating = mapToObject(songRating);
        FlxG.save.flush();
        needsFlush = false;
    }

    public static function startAutoSave(interval:Float = 5):Void
    {
        if (autoSaveTimer != null) {
            autoSaveTimer.stop();
            autoSaveTimer = null;
        }
        autoSaveTimer = new FlxTimer();
        autoSaveTimer.start(interval, 0, function(t:FlxTimer) {
            if (needsFlush) flush();
        });
    }

    public static function stopAutoSave():Void
    {
        if (autoSaveTimer != null) {
            autoSaveTimer.stop();
            autoSaveTimer = null;
        }
    }
}
