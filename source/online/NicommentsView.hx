package online;

import online.net.FunkinNetwork;

class NicommentsView extends FlxTypedGroup<Nicomment> {
	var songComments:Array<SongComment>;

    public function new(songId:String) {
		super();

        songComments = FunkinNetwork.fetchSongComments(songId) ?? [];
    }

    override function update(elapsed) {
        super.update(elapsed);

		while (songComments.length > 0 && songComments[0].at <= Conductor.songPosition) {
			var comment = songComments.shift();

			var text = recycle(Nicomment);
			text.init(comment.content);
			add(text);
		}
    }

	public function timeJump(time:Float) {
		while (songComments.length > 0 && songComments[0].at < time - 3000) {
			songComments.shift();
		}
	}
}

class Nicomment extends FlxText {
	public function new() {
		super(0, 0);
		setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
	}

	var speed:Float = 1;

	public function init(content:String) {
		setPosition(FlxG.width, FlxG.random.float(20, 250));
		text = content;
		speed = FlxG.random.float(1, 2);
	}

	override function update(elapsed) {
		super.update(elapsed);

		x -= elapsed * 200 * speed;
		if (x + width < 0) {
			kill();
		}
	}
}

typedef SongComment = {
	var player:String;
	var content:String;
	var at:Float;
}