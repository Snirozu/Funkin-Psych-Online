package hxcodec.flixel;

// @:keep (note: this doesn't work)
// typedef FlxVideo = online.backend.wrapper.FlxVideoWrapper;

class FlxVideo #if VIDEOS_ALLOWED extends online.backend.wrapper.FlxVideoWrapper #end {
    public function new() {
        #if VIDEOS_ALLOWED super(); #end
    }
}