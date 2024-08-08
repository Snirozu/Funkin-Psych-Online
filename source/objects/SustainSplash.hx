package objects;

class SustainSplash extends FlxSprite {

  public static var startCrochet:Float;
  public static var frameRate:Int;
	public var strumNote:StrumNote;

  public function new():Void {
    super();
    frames = Paths.getSparrowAtlas('noteSplashes/holdSplashes/holdSplash');
    animation.addByPrefix('hold', 'hold', 24, true);
    animation.addByPrefix('end', 'end', 24, false);
    animation.play('hold', true, false, 0);
    animation.curAnim.frameRate = frameRate;
    animation.curAnim.looped = true;
  }

  override function update(elapsed) {
    super.update(elapsed);

		if (strumNote != null) {
			alpha = ClientPrefs.data.splashAlpha - (1 - strumNote.alpha);

			if (animation.curAnim.name == "hold" && strumNote.animation.curAnim.name == "static") {
        visible = false;
      }
    }
  }

  public function setupSusSplash(strum:StrumNote, daNote:Note, ?playbackRate:Float = 1):Void {

    final lengthToGet:Int = !daNote.isSustainNote ? daNote.tail.length : daNote.parent.tail.length;
    final timeToGet:Float = !daNote.isSustainNote ? daNote.strumTime : daNote.parent.strumTime;
    final timeThingy:Float = (startCrochet * lengthToGet + (timeToGet - Conductor.songPosition + ClientPrefs.data.ratingOffset)) / playbackRate * .001;

    var tailEnd:Note = !daNote.isSustainNote ? daNote.tail[daNote.tail.length - 1] : daNote.parent.tail[daNote.parent.tail.length - 1];

    clipRect = new flixel.math.FlxRect(0, !PlayState.isPixelStage ? 0 : -210, frameWidth, frameHeight);

    if (daNote.shader != null) {
      shader = new objects.NoteSplash.PixelSplashShaderRef().shader;
      shader.data.r.value = daNote.shader.data.r.value;
      shader.data.g.value = daNote.shader.data.g.value;
      shader.data.b.value = daNote.shader.data.b.value;
      shader.data.mult.value = daNote.shader.data.mult.value;
    }

		strumNote = strum;
		alpha = ClientPrefs.data.splashAlpha - (1 - strumNote.alpha);
    setPosition(strum.x, strum.y);
    offset.set(PlayState.isPixelStage ? 112.5 : 106.25, 100);

    new FlxTimer().start(timeThingy, (idk:FlxTimer) -> {
      if (tailEnd.mustPress && !(daNote.isSustainNote ? daNote.parent.noteSplashData.disabled : daNote.noteSplashData.disabled) && ClientPrefs.data.splashAlpha != 0) {
				alpha = ClientPrefs.data.splashAlpha - (1 - strumNote.alpha);
        animation.play('end', true, false, 0);
        animation.curAnim.looped = false;
        animation.curAnim.frameRate = 24;
        clipRect = null;
        animation.finishCallback = (idkEither:Dynamic) -> {
          visible = false;
        }
        return;
      }
      visible = false;
    });

  }

}