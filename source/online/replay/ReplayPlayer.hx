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

        state.botplayVisibility = true;
        state.botplayTxt.text = data.player + "'s\nREPLAY";

		if (data.note_offset == null)
			data.note_offset = 0;
    }

    override function destroy() {
        state.controls.moodyBlues = null;
        
        super.destroy();
    }

    override function update(elapsed:Float) {
        if (state.controls.UI_LEFT) {
			if (state.playbackRate - elapsed * 0.25 > 0)
                state.playbackRate -= elapsed * 0.25;
			state.botplayTxt.text = data.player + "'s\nREPLAY\n" + '(${CoolUtil.floorDecimal(state.playbackRate, 2)}x)';
        }
        
        if (state.controls.UI_RIGHT) {
			state.playbackRate += elapsed * 0.25;
			state.botplayTxt.text = data.player + "'s\nREPLAY\n" + '(${CoolUtil.floorDecimal(state.playbackRate, 2)}x)';
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
            if (ReplayRecorder.REGISTER_BINDS.contains(events[0][1])) {
                if (events[0][2] == 0) {
                    @:privateAccess
                    state.keyPressed(PlayState.getKeyFromEvent(state.keysArray, state.controls.keyboardBinds.get(events[0][1])[0]));
                    pressedKeys.set(events[0][1], JUST_PRESSED);
                }
                else {
                    @:privateAccess
                    state.keyReleased(PlayState.getKeyFromEvent(state.keysArray, state.controls.keyboardBinds.get(events[0][1])[0]));
                    pressedKeys.set(events[0][1], JUST_RELEASED);
                }
            }

            events.shift();
        }

        super.update(elapsed);
    }
}

enum ReplayPressStatus {
    JUST_PRESSED;
    PRESSED;
    JUST_RELEASED;
}