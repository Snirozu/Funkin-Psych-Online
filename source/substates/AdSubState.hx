package substates;

import states.FreeplayState;
import hxvlc.flixel.FlxVideoSprite;
import hxvlc.util.Handle;

class AdSubState extends MusicBeatSubstate {
    var video:FlxVideoSprite;
    var skip:FlxSprite;
    var callback:Void->Void;

	public function new(callback:Void->Void) {
		super();

        for (v in [FlxG.sound.music, FreeplayState.vocals, FreeplayState.opponentVocals].concat(FlxG.sound.list.members)) {
            if (v == null)
                continue;
            v.pause();
        }

        this.callback = callback;

        Handle.initAsync(function(success:Bool):Void {
			if (!success)
				return;

            video = new FlxVideoSprite(0, 0);
            video.active = false;
            video.antialiasing = true;
            video.bitmap.onEncounteredError.add(function(message:String):Void
            {
                trace('VLC Error: $message');
            });
            video.bitmap.onEndReached.add(end);
            video.bitmap.onFormatSetup.add(function():Void
            {
                if (video.bitmap != null && video.bitmap.bitmapData != null)
                {
                    final scale:Float = Math.min(FlxG.width / video.bitmap.bitmapData.width, FlxG.height / video.bitmap.bitmapData.height);

                    video.setGraphicSize(video.bitmap.bitmapData.width * scale, video.bitmap.bitmapData.height * scale);
                    video.updateHitbox();
                    video.screenCenter();
                }
            });
            video.load(Paths.video('ads/ad' + FlxG.random.int(1, 12)));
            add(video);
            video.play();
        });

        skip = new FlxSprite(0, 0, Paths.image('skip'));
        skip.setGraphicSize(skip.frameWidth * 2);
        skip.updateHitbox();
        skip.setPosition(FlxG.width - skip.width, FlxG.height - 150);

        prevMouse = FlxG.mouse.visible;

        FlxG.state.persistentUpdate = false;
        // FlxG.state.active = false;
    }

    var videoElapsed = 0.0;
    var canSkip = true;
    var prevMouse = false;
    var skipAdded = false;
    override function update(elapsed:Float) {
        super.update(elapsed);

        videoElapsed += elapsed;

        if (videoElapsed > 10) {
            if (!skipAdded)
                add(skip);
            FlxG.mouse.visible = true;

            if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(skip, camera)) {
                end();
            }
        }
    }

    public function end() {
        FlxG.mouse.visible = prevMouse;
        if (video != null)
        {
            remove(video);
            video.destroy();
            video = null;
        }
        FlxG.state.persistentUpdate = true;
        FlxG.state.active = true;
        for (v in [FlxG.sound.music, FreeplayState.vocals, FreeplayState.opponentVocals].concat(FlxG.sound.list.members)) {
            if (v == null)
                continue;
            v.resume();
        }
        close();
        callback();
    }
}