package backend;

import online.gui.Alert;
import flixel.FlxBasic;
import grig.midi.MidiIn;
import grig.midi.MidiMessage;
import sys.thread.Mutex;

// the most autistic class i've made so far in my life

class MidiControls extends FlxBasic {
	static var midiInput:MidiIn;

    function new() {
        super();

        init();
    }

    public static function init(?announce:Bool = false) {
        try {
            if (midiInput != null) {
                midiInput.closePort();
                isActive = false;
            }

			midiInput ??= new MidiIn(grig.midi.Api.Unspecified);

			var future = midiInput.getPorts();
			future.handle(function(outcome) {
				switch (outcome) {
					case Success(ports):
						for (i => port in ports) {
							midiInput.openPort(i, port);
							midiInput.setCallback(onMidiInput);
                            isActive = true;

                            if (announce) Alert.alert('Connected to MIDI: ' + port);
						}
						if (ports.length == 0 && announce) {
							Alert.alert('No MIDI devices');
						}
					case Failure(error):
                        if (announce) Alert.alert("Failed! " + error.message);
				}
			});
		}
		catch (exc) {
            if (exc != null && announce) Alert.alert(exc.toString());
		}
    }

    static function onMidiInput(message:MidiMessage, _:Float) {
		var type = message.messageType;
		var note:Int = message.byte2 ?? 0;

        _mutex.acquire();
        switch (type) {
            case NoteOn:
                _inputQueue.push([1, note]);
            case NoteOff:
                _inputQueue.push([0, note]);
            default:
        }
        _mutex.release();
	}

    static var _mutex:Mutex = new Mutex();

    // [0] - 0 (release), 1 (push) 
    // [1] - note int
    static var _inputQueue:Array<Array<Dynamic>> = [];

    public static var isActive:Bool = false;

    public static var pressed:Array<Int> = [];
    public static var justPressed:Array<Int> = [];
    public static var justReleased:Array<Int> = [];

    public static function anyPressed(keys:Array<Int>):Bool {
        if (keys == null)
            return false;

        for (key in keys)
            if (pressed.contains(key))
                return true;

        return false;
    }

    public static function anyJustPressed(keys:Array<Int>):Bool {
        if (keys == null)
            return false;

        for (key in keys)
            if (justPressed.contains(key))
                return true;

        return false;
    }

    public static function anyJustReleased(keys:Array<Int>):Bool {
        if (keys == null)
            return false;

        for (key in keys)
            if (justReleased.contains(key))
                return true;

        return false;
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        justPressed = [];
        justReleased = [];

        _mutex.acquire();
        for (input in _inputQueue) {
            var isPress = input[0] == 1;
            var note = input[1];

            if (isPress) {
                pressed.push(note);
                justPressed.push(note);
                callMethodOnStates('handleMidiPress', [note]);
                continue;
            }

            if (pressed.contains(note))
                pressed.remove(note);
            justReleased.push(note);
            callMethodOnStates('handleMidiRelease', [note]);
        }
        _inputQueue = [];
        _mutex.release();

        // Log.println('${justPressed} ${justReleased} ${pressed}');
    }

    function callMethodOnStates(field:String, args:Array<Dynamic>) {
        callMethodOn(FlxG.state, field, args);
        if (FlxG.state.subState != null)
            callMethodOn(FlxG.state.subState, field, args);
    }

    function callMethodOn(obj:Dynamic, field:String, args:Array<Dynamic>) {
        var func = Reflect.getProperty(obj, field);
        if (func != null)
            Reflect.callMethod(obj, func, args);
    }
}

class MidiUtil {
    public static function playNote(pitch:Int) {
        var soundOctave = Math.round(Math.max(1, Math.min(9, pitch / 12)));
        var soundPath:String = 'piano_c' + soundOctave;
        var soundPitch:Int = 12 * soundOctave;
        var sound:FlxSound = FlxG.sound.load(Paths.sound(soundPath));
        sound.pitch = Math.pow(2, (pitch - soundPitch) / 12);
        sound.play();
    }

    static final SCALE_LETTERS = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];
    public static function pitchToString(pitch:Int):String {
        if (pitch < 0) return Std.string(pitch);
        return SCALE_LETTERS[pitch % 12] + Std.int(pitch / 12);
    }
}