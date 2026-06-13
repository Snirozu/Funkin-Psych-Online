package vlc;

// @:keep (note: this doesn't work)
// typedef MP4Handler = online.backend.wrapper.FlxVideoWrapper;
class MP4Handler #if VIDEOS_ALLOWED extends online.backend.wrapper.FlxVideoWrapper #end {
	public function new() {
		#if VIDEOS_ALLOWED super(); #end
	}
}