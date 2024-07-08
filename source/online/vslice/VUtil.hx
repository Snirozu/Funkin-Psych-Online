package online.vslice;

import haxe.io.Path;
import json2object.JsonParser;
import backend.Song.SwagSong;
import lime.ui.FileDialog;
import sys.io.File;
import haxe.Json;
import online.vslice.Shit;

class VUtil {
    public static function convertVSlice(path:String) {
		path = path.replace("-metadata", "-chart");

		trace(path);

		var semen = path.replace("\\", "/").split("/");
		var songID = semen[semen.length - 1].split("-chart")[0];

		var song:SongChartData = new JsonParser<SongChartData>().fromJson(File.getContent(path));
		var meta:SongMetaData = new JsonParser<SongMetaData>().fromJson(File.getContent(path.replace("-chart", "-metadata")));

		var fileDialog = new FileDialog();
		fileDialog.onSelect.add(exportPath -> {
			var events:Array<Dynamic> = [];
			for (event in song.events) {
				switch (event.e) {
					case "FocusCamera":
						var char = event.v.char == 2 ? "gf" : event.v.char == 1 ? "dad" : "bf";
						events.push(
						[
							event.t,
							[[
								"Must Hit Camera",
								char,
								event.v.duration + "," + event.v.ease + "," + event.v.x + "," + event.v.y
							]]
						]
						);
					case "ZoomCamera":
						events.push(
						[
							event.t,
							[[
								"Tween Camera Zoom",
								event.v.zoom + "," + event.v.duration,
								event.v.ease + "," + event.v.mode
							]]
						]
						);
					case "SetCameraBop":
						events.push(
						[
							event.t,
							[[
								"Change Camera Bop",
								event.v.rate,
								event.v.intensity
							]]
						]
						);
					case "PlayAnimation":
						events.push(
						[
							event.t,
							[[
								"Play Animation",
								event.v.anim,
								event.v.target
							]]
						]
						);
					default:
						Sys.println("ignoring " + event.e);
				}
			}
			File.saveContent(Path.join([exportPath, 'events${path.contains("-erect") ? "-erect" : ""}.json']), Json.stringify({song: {events: events}}));

			for (diff in song.notes.keys()) {
				var data = convertDifficulty(song, meta, diff);
				if (data == null) continue;
				File.saveContent(Path.join([exportPath, '${songID}-${diff}.json']), data);
			}
		});
		fileDialog.browse(OPEN_DIRECTORY, null, Sys.getCwd());
    }

	static function convertDifficulty(song:SongChartData, meta:SongMetaData, diff:String) {
		var swagSong:SwagSong = {
			song: meta.songName.replace(" Erect", ""),
			bpm: meta.timeChanges[0].bpm,
			needsVoices: true,
			player1: meta.playData.characters.player,
			player2: meta.playData.characters.opponent,
			speed: song.scrollSpeed.get(diff),
			stage: null,
			gfVersion: meta.playData.characters.girlfriend,
			notes: [],
			events: []
		};

		var sectionTime = Conductor.calculateCrochet(swagSong.bpm) * 4;

		var sectionNotes:Array<Array<Dynamic>> = [];
		var curSection:Float = 0;
		for (note in song.notes.get(diff)) {
			var calcSection = Math.ffloor(note.t / sectionTime);

			if (curSection < calcSection) {
				swagSong.notes.push({
					mustHitSection: true, //changed to a event note
					sectionNotes: sectionNotes,
				});
				sectionNotes = [];
				curSection = calcSection;
			}

			sectionNotes.push([note.t, note.d, note.l]);
		}
		if (sectionNotes.length > 0) {
			// add the last section 
			swagSong.notes.push({
				mustHitSection: true, // changed to a event note
				sectionNotes: sectionNotes,
			});
			sectionNotes = [];
			curSection++;
		}

		if (swagSong.notes.length <= 0)
			return null;

		return Json.stringify({song: swagSong});
    }
}