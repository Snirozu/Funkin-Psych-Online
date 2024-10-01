package online.replay;

import states.FreeplayState;
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
        inputs: [],
		note_offset: 0,
		gameplay_modifiers: [],
		ghost_tapping: true,
		rating_offset: null,
		safe_frames: null,
		version: 1,
		mod_url: ''
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
		data.note_offset = ClientPrefs.data.noteOffset;
		data.gameplay_modifiers = ClientPrefs.data.gameplaySettings;
		data.ghost_tapping = ClientPrefs.data.ghostTapping;
		data.rating_offset = ClientPrefs.data.ratingOffset;
		data.safe_frames = ClientPrefs.data.safeFrames;
		data.mod_url = OnlineMods.getModURL(Mods.currentModDirectory);
		
		data.chart_hash = Md5.encode(Song.loadRawSong(Highscore.formatSong(PlayState.SONG.song, PlayState.storyDifficulty), PlayState.SONG.song));

		for (id => binds in state.controls.keyboardBinds) {
			if (binds != null)
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
		recordKey(Conductor.songPosition, keyboardIds.get(e.keyCode) ?? (state.controls.controllerMode ? controllerIds.get(e.keyCode) : null), e.keyCode, 0);
    }

	function onKeyUp(e:KeyboardEvent) {
		recordKey(Conductor.songPosition, keyboardIds.get(e.keyCode) ?? (state.controls.controllerMode ? controllerIds.get(e.keyCode) : null), e.keyCode, 1);
	}

	function recordKey(time:Float, ids:Array<String>, keyCode:Int, move:Int) {
		switch (keyCode) {
			case 16: // shift
				data.inputs.push([time, 'KEY:SHIFT', move]);
			case 17: // ctrl
				data.inputs.push([time, 'KEY:CONTROL', move]);
			case 18: // alt
				data.inputs.push([time, 'KEY:ALT', move]);
			case 32: // spaceeee
				data.inputs.push([time, 'KEY:SPACE', move]);
		}
		
		if (ids == null)
			return;

		for (id in ids) {
			if (id == null || state.paused || !REGISTER_BINDS.contains(id))
				continue;
			data.inputs.push([time, id, move]);
		}
	}

    public function save():Float {
		if (!FileSystem.exists("replays/"))
			FileSystem.createDirectory("replays/");

		data.score = state.songScore;
		data.misses = state.songMisses;
		data.accuracy = CoolUtil.floorDecimal(state.ratingPercent * 100, 2);
		data.sicks = state.songSicks;
		data.goods = state.songGoods;
		data.bads = state.songBads;
		data.shits = state.songShits;
		data.points = FunkinPoints.calcFP(state.ratingPercent, state.songMisses, state.noteDensity, state.totalNotesHit, state.combo, state.playbackRate, state.songSpeed);
		data.beat_time = Date.now().getTime();
		data.note_offset = ClientPrefs.data.noteOffset;

		if (data.accuracy < 30) {
			Alert.alert("GIT GUD", 'your performance was so shit that\nim not even going to save the replay for it');
			return 0;
		}

		trace("Saving replay...");
		var replayData = Json.stringify(data);
		File.saveContent("replays/MyReplay-" + PlayState.SONG.song + "-" + Difficulty.getString().toUpperCase() + "-" + DateTools.format(Date.now(), "%Y-%m-%d_%H'%M'%S") + ".funkinreplay", replayData);
		trace("Saved a replay!");
		
		if (!ClientPrefs.data.disableSubmiting) {
			var res = Json.parse(Leaderboard.submitScore(replayData)?.body ?? "{}");
			if (res.gained_points != null) {
				return res.gained_points;
			}
		}
		return 0;
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

	var note_offset:Float;
	var gameplay_modifiers:Map<String, Dynamic>;
	var ghost_tapping:Null<Bool>;
	var rating_offset:Null<Int>;
	var safe_frames:Null<Float>;

	/**
	 * [ SONG_POSITION, BIND_ID, DOWN_OR_UP_INT ]
	 */
	var inputs:Array<Array<Dynamic>>;

	var version:Int;
	var mod_url:String;
}