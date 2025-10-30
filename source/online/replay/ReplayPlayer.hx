package online.replay;

import backend.Song;
import backend.WeekData;
import backend.Highscore;
import online.replay.ReplayRecorder.ReplayData;
import haxe.crypto.Md5;
import flixel.FlxBasic;

class ReplayPlayer extends FlxBasic {
	public var data:ReplayData;
    var events:Array<Dynamic>;
	var state:PlayState;
    
	public var pressedKeys:Map<String, ReplayPressStatus> = []; 
    
	public function new(state:PlayState, data:ReplayData) {
		super();

		trace("Playing a replay!");

		this.state = state;
        this.data = data;

        if (PlayState.opponentMode != data.opponent_mode) {
			state.boyfriend.isPlayer = !state.boyfriend.isPlayer;
			state.dad.isPlayer = !state.dad.isPlayer;
        }
        PlayState.opponentMode = data.opponent_mode;

        state.controls.moodyBlues = this;
		events = data.inputs.copy();
		Conductor.judgePlaybackRate = data.gameplay_modifiers.get('songspeed');

        state.botplayVisibility = true;
        state.botplayTxt.text = data.player + "'s\nREPLAY";
    }

    override function destroy() {
        state.controls.moodyBlues = null;
        
        super.destroy();
    }

    var _key:String = null;
    override function update(elapsed:Float) {
        var shiftMult = FlxG.keys.pressed.SHIFT ? 3 : 1;
        if (state.controls.UI_LEFT) {
			if (state.playbackRate - elapsed * 0.25 * shiftMult > 0)
				state.playbackRate -= elapsed * 0.25 * shiftMult;
			if (state.playbackRate < 0.01) {
				state.playbackRate = 0.01;
			}
			state.botplayTxt.text = data.player + "'s\nREPLAY\n" + '(${CoolUtil.floorDecimal(state.playbackRate, 2)}x)';
        }
        else if (state.controls.UI_RIGHT) {
			state.playbackRate += elapsed * 0.25 * shiftMult;
            if (state.playbackRate > 6) {
				state.playbackRate = 6;
            }
			state.botplayTxt.text = data.player + "'s\nREPLAY\n" + '(${CoolUtil.floorDecimal(state.playbackRate, 2)}x)';
        }
        else if (state.controls.RESET) {
			state.playbackRate = ClientPrefs.getGameplaySetting('songspeed');
			state.botplayTxt.text = data.player + "'s\nREPLAY\n";
        }

		for (key => status in pressedKeys) {
            if (status == JUST_PRESSED) {
				pressedKeys.set(key, PRESSED);
            }
			else if (status == JUST_RELEASED) {
				pressedKeys.remove(key);
			}
        }

		while (events.length > 0 && events[0][0] <= Conductor.songPosition - (ClientPrefs.data.noteOffset - data.note_offset)) {
			_key = events[0][1];

			Conductor.judgeSongPosition = events[0][0] + (ClientPrefs.data.noteOffset - data.note_offset);

			if (Conductor.judgeSongPosition - Conductor.songPosition <= -50) {
				Conductor.songPosition = events[0][0] + (ClientPrefs.data.noteOffset - data.note_offset);
                state.resyncVocals();
            }

			if (ReplayRecorder.REGISTER_BINDS.contains(_key)) {
                if (events[0][2] == 0) {
                    @:privateAccess
					state.keyPressed(PlayState.getKeyFromEvent(state.keysArray, state.controls.keyboardBinds.get(_key)[0]));
					pressedKeys.set(_key, JUST_PRESSED);
                }
                else {
                    @:privateAccess
					state.keyReleased(PlayState.getKeyFromEvent(state.keysArray, state.controls.keyboardBinds.get(_key)[0]));
					pressedKeys.set(_key, JUST_RELEASED);
                }
            }
			else if (_key == 'KEY:SHIFT' || _key == 'KEY:CONTROL' || _key == 'KEY:ALT' || _key == 'KEY:SPACE') {
                if (events[0][2] == 0) {
					pressedKeys.set(_key, JUST_PRESSED);
                }
                else {
					pressedKeys.set(_key, JUST_RELEASED);
                }
            }

            events.shift();
        }

        super.update(elapsed);
    }

    public function timeJump(time:Float) {
		while (events.length > 0 && events[0][0] < time - (ClientPrefs.data.noteOffset - data.note_offset)) {
			_key = events[0][1];

			if (ReplayRecorder.REGISTER_BINDS.contains(_key)) {
				if (events[0][2] == 0) {
					pressedKeys.set(_key, JUST_PRESSED);
				}
				else {
					pressedKeys.set(_key, JUST_RELEASED);
				}
			}
			else if (_key == 'KEY:SHIFT' || _key == 'KEY:CONTROL' || _key == 'KEY:ALT' || _key == 'KEY:SPACE') {
				if (events[0][2] == 0) {
					pressedKeys.set(_key, JUST_PRESSED);
				}
				else {
					pressedKeys.set(_key, JUST_RELEASED);
				}
			}

			events.shift();
        }
    }

	/**
	 * Helper for loading replays into `PlayState`.
	 * @param replayData The data for the Replay.
	 * @param replayID The ID for the replay.
	 * @param autoDetermine If the mod and week should be automatically determined.
	 */
	public static function loadReplay(replayData:Dynamic, ?replayID:Null<String>, ?autoDetermine:Bool = false):Void
	{
		if(replayData is String)
			replayData = haxe.Json.parse(replayData);

		if(!Reflect.isObject(replayData))
			throw new haxe.Exception("Replay Data is invalid!");

		var songLowercase:String = Paths.formatToSongPath(replayData.song);

		if(autoDetermine)
		{
			var modFolder:Null<String> = null;

			for(mod in Mods.parseList().enabled)
			{
				var modURL:Null<String> = online.mods.OnlineMods.getModURL(mod);

				if(replayData.mod_url == modURL)
				{
					modFolder = mod;
					break;
				}
			}

			if(modFolder == null && replayData.mod_url != null)
				throw new haxe.Exception("Could not find the mod by URL, does it need to be installed?");

			Mods.currentModDirectory = modFolder;

			WeekData.reloadWeekFiles(false);

			for(i => weekName in WeekData.weeksList)
			{
				var week:WeekData = WeekData.weeksLoaded.get(weekName);

				if(modFolder != null && week.folder != null && week.folder.length > 0 && week.folder != modFolder)
					continue;

				for(song in week.songs)
				{
					var id:String = Paths.formatToSongPath(song[0]);
					var hasErect:Bool = song[3];
					var hasNightmare:Bool = song[4];

					if(id == songLowercase)
					{
						PlayState.storyWeek = i;
						var extraDiffs:Array<String> = [];
						if(hasErect) extraDiffs.push('Erect');
						if(hasNightmare) extraDiffs.push('Nightmare');
						Difficulty.loadFromWeek(null, extraDiffs);
						break;
					}
				}
			}
		}

		PlayState.replayData = cast replayData;
		if(Reflect.isObject(replayData.gameplay_modifiers)) PlayState.replayData.gameplay_modifiers = cast ShitUtil.objToMap(replayData.gameplay_modifiers);
		PlayState.replayID = replayID;

		var poop:String = Highscore.formatSong(songLowercase, Difficulty.list.indexOf(PlayState.replayData.difficulty));

		if(PlayState.replayData.chart_hash != Md5.encode(Song.loadRawSong(poop, songLowercase)))
		{
			PlayState.replayData = null;
			throw new haxe.Exception("OUTDATED REPLAY OR INVALID FOR THIS SONG");
		}

		try {
			PlayState.loadSong(poop, songLowercase);
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = Difficulty.list.indexOf(PlayState.replayData.difficulty);

			trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
		}
		catch(e:haxe.Exception) {
			PlayState.replayData = null;

			var exceptionMessage:String = e.message;

			if(e.message.startsWith('[file_contents,assets/data/'))
				exceptionMessage = 'Missing file: ' + exceptionMessage.substring(27, exceptionMessage.length - 1);

			throw new haxe.Exception(exceptionMessage, e);
		}
	}
}

enum ReplayPressStatus {
    JUST_PRESSED;
    PRESSED;
    JUST_RELEASED;
}
