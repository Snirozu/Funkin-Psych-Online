package online;

import states.editors.ChartingState;
import objects.Note;
import backend.Song.SwagSong;

typedef FunkinDiffInfo = {
    nps:Float, strain:Float
}

class ChartAnalyzer {
    public static function calc(songData:SwagSong, mustPress:Bool):FunkinDiffInfo {
		// for 4k this will have 0000 bits
		// each 0 is another row for the key
		// if a bit is 1 then that means a note was registered there
		var unsortedChords:Map<String, Int> = [];
        var dummyNote:Note = new Note(0, 0);
		for (sectIndex => section in songData.notes) {
			for (note in section.sectionNotes) {
                var daStrumTime:Float = note[0];
                var daNoteData:Int = Std.int(note[1] % Note.maniaKeys);
                if (note[1] < 0 || note[1] > Note.maniaKeys * 2 - 1)
                    continue;
                var gottaHitNote:Bool = PlayState.getMustPressFromRaw(section, note);
                if (gottaHitNote != mustPress) continue;

                dummyNote.noteType = note[3];
			    if(!Std.isOfType(note[3], String)) dummyNote.noteType = ChartingState.noteTypeList[note[3]]; //Backward compatibility + compatibility with Week 7 charts

                //TODO maybe later add bad notes
                if (dummyNote.hitCausesMiss) {
                    continue;
                }

                // up to 32 rows sorry everyone, no 33k+
                var laneBit = 1 << daNoteData;

                // will merge notes within 2ms
                final timeKey:String = '${Math.round(daStrumTime / 2)}';

                if (unsortedChords.exists(timeKey))
                    unsortedChords.set(timeKey, unsortedChords.get(timeKey) | laneBit);
                else
                    unsortedChords.set(timeKey, laneBit);
            }
		}

		// now just take the unsorted possible chords map 
		// the time is also converted back to regular miliseconds and it is also floatified
		var chords:Array<{
			time:Float,
			bits:Int,
		}> = [];
        for (time => bits in unsortedChords)
            chords.push({ time: Std.parseInt(time) * 2 / 1000.0, bits: bits });
        chords.sort(function(a, b) return Reflect.compare(a.time, b.time));

		if (chords.length < 2) return {
			nps: 0.0,
			strain: 0.0
		};

		var chord = chords[0];

		// NPS
		var TIMEFRAME_WINDOW:Float = 0.5;
		var totalNPSSum:Float = 0.0;
        var totalNPSWindows:Int = 0;
        var notesInCurrentWindow:Int = 0;
        var windowStartTime:Float = chord.time;
		function nextNPS() {
			notesInCurrentWindow += countBitChord(chord.bits);

            if (chord.time - windowStartTime >= TIMEFRAME_WINDOW) {
                final delta = chord.time - windowStartTime;
                final localNPS = notesInCurrentWindow / delta;

                if (localNPS > 0) {
                    totalNPSSum += localNPS;
                    totalNPSWindows++;
                }

                notesInCurrentWindow = 0;
                windowStartTime = chord.time;
            }
		}

		// STRAIN
        var currentStrain:Float = 0.0;
        var totalStrainSum:Float = 0.0;
        var prevTime:Float = chords[0].time;
        var DECAY_BASE:Float = 0.5; 
        var STRAIN_SCALING:Float = 1.5;
		function nextStrain() {
            var deltaTime = chord.time - prevTime;
            prevTime = chord.time;

            if (deltaTime <= 0.0) return;

            var noteCount = countBitChord(chord.bits);
			var additionValue = Math.exp(-12.0 * deltaTime) * noteCount;
			var decay = Math.pow(DECAY_BASE, deltaTime);

			currentStrain = (currentStrain * decay) + additionValue;
			totalStrainSum += currentStrain;
		}

        for (nextChord in chords) {
			chord = nextChord;

            nextNPS();
			nextStrain();
        }

        return {
			nps: totalNPSWindows > 0 ? (totalNPSSum / totalNPSWindows) : 0.0,
			strain: (totalStrainSum / chords.length) * STRAIN_SCALING
		};
	}

	static inline function countBitChord(bits:Int) {
		var count = 0;
		var temp = bits;
		while (temp > 0) {
			if ((temp & 1) == 1) count++;
			temp = temp >> 1;
		}
		return count;
	}
}