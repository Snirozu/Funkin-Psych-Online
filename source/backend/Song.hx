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

	@:optional var mania:Int;
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

	static final CHAR_NAME_FIX:Map<String, String> = [
		"pico-playable" => "pico-player",
		"tankman-playable" => "tankman-player"
	];

	private static function onLoadJson(songJson:Dynamic)
	{
		if (songJson.format == null)
			throw new haxe.Exception('No chart format found!');

		if (ClientPrefs.isDebug())
			trace('Loaded ${songJson.format} Song!');

		if (songJson.gfVersion == null)
		{
			songJson.gfVersion = songJson.player3;
			songJson.player3 = null;
		}

		if (StringTools.startsWith(songJson.format, 'psych_v1'))
		{
			songJson.format = 'psych_v1';
			var characters = [songJson.player1, songJson.player2, songJson.gfVersion];
			for (i in 0...characters.length)
			{
				if (CHAR_NAME_FIX.exists(characters[i]))
					characters[i] = CHAR_NAME_FIX[characters[i]];
			}
			songJson.player1 = characters[0];
			songJson.player2 = characters[1];
			songJson.gfVersion = characters[2];
		}

		// Optimizado: Usar filter() en lugar de remove() dentro de bucles
		if (songJson.events == null && songJson.format == 'psych_legacy')
		{
			songJson.events = [];
			var sections:Array<Dynamic> = cast songJson.notes; // Cast explícito
			for (sec in sections)
			{
				var secNotes:Array<Dynamic> = cast sec.sectionNotes;
				sec.sectionNotes = secNotes.filter(function(note:Array<Dynamic>)
				{
					if (note[1] < 0) {
						songJson.events.push([note[0], [[note[2], note[3], note[4]]]]);
						return false;
					}
					return true;
				});
			}
		}
	}

	public function new(song:String, notes:Array<SwagSection>, bpm:Float)
	{
		this.song = song;
		this.notes = notes;
		this.bpm = bpm;
	}

	public static function loadRawSong(jsonInput:String, ?folder:String):String
	{
		var formattedFolder = Paths.formatToSongPath(folder);
		var formattedSong = Paths.formatToSongPath(jsonInput);
		var path = formattedFolder + '/' + formattedSong;
		var rawJson:String = null;

		#if MODS_ALLOWED
		var modFile = Paths.modsJson(path);
		if (FileSystem.exists(modFile))
			rawJson = File.getContent(modFile);
		#end

		if (rawJson == null)
		{
			#if sys
			var basePath = Paths.json(path);
			if (FileSystem.exists(basePath))
				rawJson = File.getContent(basePath);
			#else
			rawJson = Assets.getText(Paths.json(path));
			#end
		}

		if (rawJson == null)
			throw new haxe.Exception("Missing file: " + Paths.json(path));

		// Limpieza optimizada en una sola operación
		rawJson = ~/}[^}]*$/.replace(rawJson.trim(), "}");
		return rawJson;
	}

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		return parseRawJSON(jsonInput, loadRawSong(jsonInput, folder));
	}

	public static function parseRawJSON(jsonInput:String, rawSONG:String):SwagSong
	{
		var songJson:Dynamic = parseJSONshit(rawSONG);
		if (!jsonInput.startsWith('events'))
			StageData.loadDirectory(songJson);
		onLoadJson(songJson);
		return songJson;
	}

	public static function parseJSONshit(rawJson:String):SwagSong
	{
		var parsed:Dynamic;
		try {
			parsed = Json.parse(rawJson);
		} catch (e:Dynamic) {
			throw new haxe.Exception("Error parsing JSON: " + e);
		}

		if (parsed.song != null)
		{
			if (Std.isOfType(parsed.song, String))
			{
				parsed.format ??= 'psych_v1';
				return parsed;
			}
			parsed.song.format = 'psych_legacy';
			return parsed.song;
		}

		if (parsed.events != null)
		{
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