package online.replay;

import online.replay.ReplayRecorder.ReplayData;
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
        if (state.controls.UI_LEFT) {
			if (state.playbackRate - elapsed * 0.25 > 0)
                state.playbackRate -= elapsed * 0.25;
			state.botplayTxt.text = data.player + "'s\nREPLAY\n" + '(${CoolUtil.floorDecimal(state.playbackRate, 2)}x)';
        }
        else if (state.controls.UI_RIGHT) {
			state.playbackRate += elapsed * 0.25;
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

			if (Conductor.judgeSongPosition - Conductor.songPosition <= -20) {
				Conductor.songPosition = events[0][0] + (ClientPrefs.data.noteOffset - data.note_offset);
                state.resyncVocals(false);
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

    //haxe json class doesn't do it automatically? cool
	public static function objToMap(obj:Dynamic):Map<String, Dynamic> {
		var map:Map<String, Dynamic> = new Map<String, Dynamic>();
		for (field in Reflect.fields(obj)) {
			map.set(field, Reflect.field(obj, field));
		}
		return map;
	}
}

enum ReplayPressStatus {
    JUST_PRESSED;
    PRESSED;
    JUST_RELEASED;
}