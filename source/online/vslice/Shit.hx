package online.vslice;

typedef SongMetaData = {
	public var version:String;
	public var songName:String;
	public var artist:String;
	public var divisions:Float;
	public var looped:Bool;
	public var offsets:Null<SongOffsets>;
	public var playData:SongPlayData;
	public var generatedBy:String;
	public var timeFormat:String;
	public var timeChanges:Array<SongTimeChange>;
}

typedef SongOffsets = {
	public var instrumental:Float;
	public var altInstrumentals:Map<String, Float>;
	public var vocals:Map<String, Float>;
}

typedef SongPlayData = {
	public var songVariations:Array<String>;
	public var difficulties:Array<String>;
	public var characters:SongCharacterData;
	public var stage:String;
	public var noteStyle:String;
	public var ratings:Map<String, Float>;
	public var album:Null<String>;
	public var previewStart:Float;
	public var previewEnd:Float;
}

typedef SongTimeChange = {
	public var t:Float;
	public var b:Float;
	public var bpm:Float;
	public var n:Float;
	public var d:Float;
	public var bt:Array<Float>;
}

typedef SongCharacterData = {
	public var player:String;
	public var girlfriend:String;
	public var opponent:String;
	public var instrumental:String;
	public var altInstrumentals:Array<String>;
}

typedef SongChartData = {
	public var version:String;
	public var scrollSpeed:Map<String, Float>;
	public var events:Array<SongEventData>;
	public var notes:Map<String, Array<SongNoteData>>;
	public var generatedBy:String;
}

typedef SongNoteData = {
	public var t:Float;
	public var d:Float;
	public var l:Float;
}

typedef SongEventData = {
	public var t:Float;
	public var e:String;
	@:jcustomparse(online.vslice.Poo.dynamicParseValue)
	@:jcustomwrite(online.vslice.Poo.dynamicWriteValue)
	public var v:Dynamic;
}