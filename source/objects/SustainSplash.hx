package objects;

class SustainSplash extends FlxSprite {

  public static var startCrochet:Float;
  public static var frameRate:Int;
	public var strumNote:StrumNote;

	var timer:FlxTimer;

	public static var defaultNoteHoldSplash(default, never):String = 'noteSplashes/holdSplashes/holdSplash';

  public function new():Void {
    super();

		var skin:String = defaultNoteHoldSplash + getSplashSkinPostfix();
		frames = Paths.getSparrowAtlas(skin);
		if (frames == null) {
			skin = defaultNoteHoldSplash;
			frames = Paths.getSparrowAtlas(skin);
		}

    animation.addByPrefix('hold', 'hold', 24, true);
    animation.addByPrefix('end', 'end', 24, false);
  }

  override function update(elapsed) {
    super.update(elapsed);

		if (strumNote != null) {
      alpha = ClientPrefs.data.holdSplashAlpha - (1 - strumNote.alpha);

			if (animation.curAnim.name == "hold" && strumNote.animation.curAnim.name == "static") {
				kill();
      }
    }
  }

  public function setupSusSplash(strum:StrumNote, daNote:Note, ?playbackRate:Float = 1):Void {

    final lengthToGet:Int = !daNote.isSustainNote ? daNote.tail.length : daNote.parent.tail.length;
    final timeToGet:Float = !daNote.isSustainNote ? daNote.strumTime : daNote.parent.strumTime;
    final timeThingy:Float = (startCrochet * lengthToGet + (timeToGet - Conductor.songPosition + ClientPrefs.data.ratingOffset)) / playbackRate * .001;

    var tailEnd:Note = !daNote.isSustainNote ? daNote.tail[daNote.tail.length - 1] : daNote.parent.tail[daNote.parent.tail.length - 1];

		animation.play('hold', true, false, 0);
		animation.curAnim.frameRate = frameRate;
		animation.curAnim.looped = true;

    clipRect = new flixel.math.FlxRect(0, !PlayState.isPixelStage ? 0 : -210, frameWidth, frameHeight);

    if (daNote.shader != null) {
      shader = new objects.NoteSplash.PixelSplashShaderRef().shader;
      shader.data.r.value = daNote.shader.data.r.value;
      shader.data.g.value = daNote.shader.data.g.value;
      shader.data.b.value = daNote.shader.data.b.value;
      shader.data.mult.value = daNote.shader.data.mult.value;
    }

		strumNote = strum;
		alpha = ClientPrefs.data.holdSplashAlpha - (1 - strumNote.alpha);
    setPosition(strum.x, strum.y);
    offset.set(PlayState.isPixelStage ? 112.5 : 106.25, 100);

		if (timer != null)
			timer.cancel();

		if (PlayState.isPlayerNote(tailEnd) && ClientPrefs.data.holdSplashAlpha != 0)
      timer = new FlxTimer().start(timeThingy, (idk:FlxTimer) -> {
        if (!(daNote.isSustainNote ? daNote.parent.noteSplashData.disabled : daNote.noteSplashData.disabled)) {
					alpha = ClientPrefs.data.holdSplashAlpha - (1 - strumNote.alpha);
          animation.play('end', true, false, 0);
          animation.curAnim.looped = false;
          animation.curAnim.frameRate = 24;
          clipRect = null;
          animation.finishCallback = (idkEither:Dynamic) -> {
            kill();
          }
          return;
        }
        kill();
      });

  }

  public static function getSplashSkinPostfix()
	{
		var skin:String = '';
		if(ClientPrefs.data.splashSkin != ClientPrefs.defaultData.splashSkin)
			skin = '-' + ClientPrefs.data.splashSkin.trim().toLowerCase().replace(' ', '_');
		return skin;
	}

}