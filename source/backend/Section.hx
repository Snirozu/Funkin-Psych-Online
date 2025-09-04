package backend;

typedef SwagSection = {
    var sectionNotes:Array<Dynamic>;
    @:optional var sectionBeats:Float;
    @:optional var typeOfSection:Int;
    var mustHitSection:Bool;
    @:optional var gfSection:Bool;
    @:optional var bpm:Float;
    @:optional var changeBPM:Bool;
    @:optional var altAnim:Bool;
}

class Section {
    public var sectionNotes:Array<Dynamic>;
    public var sectionBeats:Float = 4;
    public var gfSection:Bool = false;
    public var typeOfSection:Int = 0;
    public var mustHitSection:Bool = true;

    public static var enableTracing:Bool = false;

    public static inline var COPYCAT:Int = 0;

    public function new(sectionBeats:Float = 4, ?initialNotes:Array<Dynamic>) {
        this.sectionBeats = sectionBeats;
        this.sectionNotes = initialNotes != null ? initialNotes : [];

        #if debug
        if (enableTracing) {
            trace('Section created (beats=${sectionBeats}, notes=${this.sectionNotes.length})');
        }
        #end
    }
}
