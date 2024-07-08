package online.replay;

import online.net.Leaderboard;
import haxe.crypto.Md5;
import backend.Song;
import backend.Highscore;
import sys.FileSystem;
import haxe.Json;
import sys.io.File;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;
import openfl.events.KeyboardEvent;
import flixel.FlxBasic;

class ReplayRecorder extends FlxBasic {
	public static final REGISTER_BINDS = [
		"note_up", "note_down", "note_left", "note_right", "taunt",
	];

	public var data:ReplayData = {
		player: "",
		song: "",
		difficulty: "",
		//mod_url: "",
		opponent_mode: false,
		beat_time: 0,
		chart_hash: "",
		accuracy: 0,
		sicks: 0,
		goods: 0,
		bads: 0,
		shits: 0,
		misses: 0,
		points: 0,
		score: 0,
        inputs: []
    };

    var state:PlayState;

	var keyboardIds:Map<FlxKey, Array<String>> = [];
	var controllerIds:Map<FlxGamepadInputID, Array<String>> = [];

	public function new(state:PlayState) {
        super();

		trace("Recording a replay...");

        this.state = state;

		data.player = ClientPrefs.getNickname();
		data.song = PlayState.SONG.song;
		data.difficulty = Difficulty.getString(PlayState.storyDifficulty);
		//data.mod_url = OnlineMods.getModURL(Mods.currentModDirectory); 
		data.opponent_mode = !PlayState.playsAsBF();
		
		data.chart_hash = Md5.encode(Song.loadRawSong(Highscore.formatSong(PlayState.SONG.song, PlayState.storyDifficulty), PlayState.SONG.song));

		for (id => binds in state.controls.keyboardBinds) {
            for (bind in binds) {
				if (REGISTER_BINDS.contains(id)) {
					if (keyboardIds.exists(bind))
						keyboardIds.get(bind).push(id);
					else
						keyboardIds.set(bind, [id]);
				}
            }
		}

		for (id => binds in state.controls.gamepadBinds) {
			for (bind in binds) {
				if (REGISTER_BINDS.contains(id)) {
					if (controllerIds.exists(bind))
						controllerIds.get(bind).push(id);
					else
						controllerIds.set(bind, [id]);
				}
			}
		}

		state.add(this);
        
		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
    }

	override function destroy() {
		super.destroy();

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUp);
	}

	function onKeyDown(e:KeyboardEvent) {
		recordKey(Conductor.songPosition, keyboardIds.get(e.keyCode) ?? (state.controls.controllerMode ? controllerIds.get(e.keyCode) : null), 0);
    }

	function onKeyUp(e:KeyboardEvent) {
		recordKey(Conductor.songPosition, keyboardIds.get(e.keyCode) ?? (state.controls.controllerMode ? controllerIds.get(e.keyCode) : null), 1);
	}

	function recordKey(time:Float, ids:Array<String>, move:Int) {
		if (ids == null)
			return;

		for (id in ids) {
			if (id == null || state.paused || !REGISTER_BINDS.contains(id))
				continue;
			data.inputs.push([time, id, move]);
		}
	}

    public function save() {
		if (!FileSystem.exists("replays/"))
			FileSystem.createDirectory("replays/");

		data.score = state.songScore;
		data.misses = state.songMisses;
		data.accuracy = CoolUtil.floorDecimal(state.ratingPercent * 100, 2);
		data.sicks = state.songSicks;
		data.goods = state.songGoods;
		data.bads = state.songBads;
		data.shits = state.songShits;
		data.points = FunkinPoints.calcFP(state.ratingPercent, state.songMisses, state.noteDensity, state.totalNotesHit, state.combo, state.playbackRate);
		data.beat_time = Date.now().getTime();

		trace("Saving replay...");
		var replayData = Json.stringify(data);
		if (!ClientPrefs.data.disableSubmiting)
			Leaderboard.submitScore(replayData);
		File.saveContent("replays/MyReplay-" + PlayState.SONG.song + "-" + Difficulty.getString().toUpperCase() + "-" + DateTools.format(Date.now(), "%Y-%m-%d_%H'%M'%S") + ".funkinreplay", replayData);
		trace("Saved a replay!");
    }
}

typedef ReplayData = {
	var player:String;

	var song:String;
	var difficulty:String;
	var accuracy:Float;
	var sicks:Float;
	var goods:Float;
	var bads:Float;
	var shits:Float;
	var misses:Float;
	var score:Float;
	var points:Float;

	//var mod_url:String;
	var opponent_mode:Bool;
	var beat_time:Float;
	var chart_hash:String;
	/**
	 * [ SONG_POSITION, BIND_ID, DOWN_OR_UP_INT ]
	 */
	var inputs:Array<Array<Dynamic>>;
}