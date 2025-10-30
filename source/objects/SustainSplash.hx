package objects;

class SustainSplash extends FlxSprite {
	public static var startCrochet:Float;
	public static var frameRate:Int;

	public var strumNote:StrumNote;

	var timer:FlxTimer;

	public static var defaultNoteHoldSplash(default, never):String = 'noteSplashes/holdSplashes/holdSplash';

	public function new():Void {
		super();

		x = -50000;

		var skin:String = defaultNoteHoldSplash + getSplashSkinPostfix();
		frames = Paths.getSparrowAtlas(skin);
		if (frames == null) {
			skin = defaultNoteHoldSplash;
			frames = Paths.getSparrowAtlas(skin);
		}

		if (frames != null) {
			animation.addByPrefix('hold', 'hold', 24, true);
			animation.addByPrefix('end', 'end', 24, false);
		}
	}

	override function update(elapsed) {
		super.update(elapsed);

		if (strumNote != null && animation != null && strumNote.animation != null) {
			if (online.backend.SyncScript.dispatch('testSusSplashUpdate', [this]) == null) {
				setPosition(
					(strumNote.x - (Note.swagWidth - Note.swagScaledWidth)) - Note.swagScaledWidth * 0.95, 
					(strumNote.y - (Note.swagWidth - Note.swagScaledWidth)) - Note.swagScaledWidth
				);
			}
			visible = strumNote.visible;
			alpha = ClientPrefs.data.holdSplashAlpha - (1 - strumNote.alpha);

			if (animation.curAnim != null && strumNote.animation.curAnim != null && animation.curAnim.name == "hold" && strumNote.animation.curAnim.name == "static") {
				x = -50000;
				kill();
			}
		}
	}

	public function setupSusSplash(strum:StrumNote, daNote:Note, ?playbackRate:Float = 1):Void {
		final lengthToGet:Int = !daNote.isSustainNote ? daNote.tail.length : daNote.parent.tail.length;
		final timeToGet:Float = !daNote.isSustainNote ? daNote.strumTime : daNote.parent.strumTime;
		final timeThingy:Float = (startCrochet * lengthToGet + (timeToGet - Conductor.songPosition + ClientPrefs.data.ratingOffset)) / playbackRate * .001;

		var tailEnd:Note = !daNote.isSustainNote ? daNote.tail[daNote.tail.length - 1] : daNote.parent.tail[daNote.parent.tail.length - 1];

		if (animation == null)
			return;

		if (online.backend.SyncScript.dispatch('testSusSplash', [this]) == null) {
			setGraphicSize(Std.int(width * Note.noteScale));
		}

		animation.play('hold', true, false, 0);
		if (animation.curAnim != null) {
			animation.curAnim.frameRate = frameRate;
			animation.curAnim.looped = true;
		}

		clipRect = new flixel.math.FlxRect(0, !PlayState.isPixelStage ? 0 : -210, frameWidth, frameHeight);

		if (daNote.shader != null) {
			// idk what this does, and it causes issues so i'm putting it into try-catch
			try {
				shader = new objects.NoteSplash.PixelSplashShaderRef().shader;
				shader.data.r.value = daNote.shader.data.r.value;
				shader.data.g.value = daNote.shader.data.g.value;
				shader.data.b.value = daNote.shader.data.b.value;
				shader.data.mult.value = daNote.shader.data.mult.value;
			}
			catch (e) {
				trace(e);
			}
		}

		strumNote = strum;
		alpha = ClientPrefs.data.holdSplashAlpha - (1 - strumNote.alpha);
		offset.set(PlayState.isPixelStage ? 10 : 0, -15);
		offset.x *= Note.noteScale;
		offset.y *= Note.noteScale;

		if (timer != null)
			timer.cancel();

		if (PlayState.isPlayerNote(tailEnd) && ClientPrefs.data.holdSplashAlpha != 0)
			timer = new FlxTimer().start(timeThingy, (idk:FlxTimer) -> {
				if (!(daNote.isSustainNote ? daNote.parent.noteSplashData.disabled : daNote.noteSplashData.disabled)) {
					alpha = ClientPrefs.data.holdSplashAlpha - (1 - strumNote.alpha);
					animation.play('end', true, false, 0);
					if (animation.curAnim != null) {
						animation.curAnim.looped = false;
						animation.curAnim.frameRate = 24;
					}
					clipRect = null;
					animation.finishCallback = (idkEither:Dynamic) -> {
						kill();
					}
					return;
				}
				kill();
			});
	}

	public static function getSplashSkinPostfix() {
		var skin:String = '';
		if (ClientPrefs.data.splashSkin != ClientPrefs.defaultData.splashSkin)
			skin = '-' + ClientPrefs.data.splashSkin.trim().toLowerCase().replace(' ', '_');
		return skin;
	}
}
