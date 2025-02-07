package backend;

/**
 * This class ensures backwards compatibility with hxCodec.
 */
class VideoHandler extends hxvlc.flixel.FlxVideo
{
	override public function play(location:String, shouldLoop:Bool = false):Bool
	{
		this.load(location, shouldLoop ? ["input-repeat=65535"] : []);
		return super.play();
	}
}