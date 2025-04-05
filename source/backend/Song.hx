package backend;

import tjson.TJSON as Json;
import lime.utils.Assets;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

import backend.Section;

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var events:Array<Dynamic>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
	var gfVersion:String;
	var stage:String;

	@:optional var gameOverChar:String;
	@:optional var gameOverSound:String;
	@:optional var gameOverLoop:String;
	@:optional var gameOverEnd:String;
	
	@:optional var disableNoteRGB:Bool;

	@:optional var arrowSkin:String;
	@:optional var splashSkin:String;

	//MOD SPECIFIC
	@:optional var mania:Int;

	//psych engine 1.0
	@:optional var format:String;
}

class Song
{
	public var song:String;
	public var notes:Array<SwagSection>;
	public var events:Array<Dynamic>;
	public var bpm:Float;
	public var needsVoices:Bool = true;
	public var arrowSkin:String;
	public var splashSkin:String;
	public var gameOverChar:String;
	public var gameOverSound:String;
	public var gameOverLoop:String;
	public var gameOverEnd:String;
	public var disableNoteRGB:Bool = false;
	public var speed:Float = 1;
	public var stage:String;
	public var player1:String = 'bf';
	public var player2:String = 'dad';
	public var gfVersion:String = 'gf';

	private static function onLoadJson(songJson:Dynamic) // Convert old charts to newest format, or convert new format to old format?
	{
		if(songJson.format == null)
			throw new haxe.Exception('No chart format found!');

		if (ClientPrefs.isDebug())
			trace('Loaded ${songJson.format} Song!');

		if(songJson.gfVersion == null)
		{
			songJson.gfVersion = songJson.player3;
			songJson.player3 = null;
		}

		if(StringTools.startsWith(songJson.format, 'psych_v1')) {
			songJson.format = 'psych_v1';

			var characters:Array<String> = [songJson.player1, songJson.player2, songJson.gfVersion];
			for (i in 0...characters.length)
			{
				switch(characters[i])
				{
					case 'pico-playable':
						characters[i] = 'pico-player';

					case 'tankman-playable':
						characters[i] = 'tankman-player';
				}
			}

			songJson.player1 = characters[0];
			songJson.player2 = characters[1];
			songJson.gfVersion = characters[2];
		}

		if(songJson.events == null && songJson.format == 'psych_legacy')
		{
			songJson.events = [];
			for (secNum in 0...songJson.notes.length)
			{
				var sec:SwagSection = songJson.notes[secNum];

				var i:Int = 0;
				var notes:Array<Dynamic> = sec.sectionNotes;
				var len:Int = notes.length;
				while(i < len) {
					var note:Array<Dynamic> = notes[i];
					// if notedata is -1 (event note)
					if(note[1] < 0) {
						songJson.events.push([note[0], [[note[2], note[3], note[4]]]]);
						notes.remove(note);
						len = notes.length;
						continue;
					}
					i++;
				}
			}
		}
	}

	public function new(song, notes, bpm)
	{
		this.song = song;
		this.notes = notes;
		this.bpm = bpm;
	}

	public static function loadRawSong(jsonInput:String, ?folder:String):String {
		var rawJson = null;

		var formattedFolder:String = Paths.formatToSongPath(folder);
		var formattedSong:String = Paths.formatToSongPath(jsonInput);
		#if MODS_ALLOWED
		var moddyFile:String = Paths.modsJson(formattedFolder + '/' + formattedSong);
		if (FileSystem.exists(moddyFile)) {
			rawJson = File.getContent(moddyFile).trim();
		}
		#end

		if (rawJson == null) {
			#if sys
			if (FileSystem.exists(Paths.json(formattedFolder + '/' + formattedSong)))
				rawJson = File.getContent(Paths.json(formattedFolder + '/' + formattedSong));
			#else
			rawJson = Assets.getText(Paths.json(formattedFolder + '/' + formattedSong));
			#end

			if (rawJson == null) {
				throw new haxe.Exception("Missing file: " + Paths.json(formattedFolder + '/' + formattedSong));
			}

			rawJson = rawJson.trim();
		}

		while (!rawJson.endsWith("}")) {
			rawJson = rawJson.substr(0, rawJson.length - 1);
			// LOL GOING THROUGH THE BULLSHIT TO CLEAN IDK WHATS STRANGE
		}

		return rawJson;
	}

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		// FIX THE CASTING ON WINDOWS/NATIVE
		// Windows???
		// trace(songData);

		// trace('LOADED FROM JSON: ' + songData.notes);
		/* 
			for (i in 0...songData.notes.length)
			{
				trace('LOADED FROM JSON: ' + songData.notes[i].sectionNotes);
				// songData.notes[i].sectionNotes = songData.notes[i].sectionNotes
			}

				daNotes = songData.notes;
				daSong = songData.song;
				daBpm = songData.bpm; */

		return parseRawJSON(jsonInput, loadRawSong(jsonInput, folder));
	}

	public static function parseRawJSON(jsonInput:String, rawSONG:String) {
		var songJson:Dynamic = parseJSONshit(rawSONG);
		if(!jsonInput.startsWith('events')) StageData.loadDirectory(songJson);
		onLoadJson(songJson);
		return songJson;
	}

	public static function parseJSONshit(rawJson:String):SwagSong
	{
		var parsed:Dynamic = Json.parse(rawJson);
		
		if (parsed.song != null) {
			if (Std.isOfType(parsed.song, String)) {
				parsed.format ??= 'psych_v1';
				return parsed;
			}
			
			parsed.song.format = 'psych_legacy';
			return parsed.song;
		}
		
		if (parsed.events != null) {
			return {
				events: cast parsed.events,
				song: "",
				notes: [],
				bpm: 0,
				needsVoices: true,
				speed: 1,
				player1: "",
				player2: "",
				gfVersion: "",
				stage: "",
				format: 'psych_v1'
			};
		}

		throw new haxe.Exception("No song data found, or is invalid.");
	}
}
