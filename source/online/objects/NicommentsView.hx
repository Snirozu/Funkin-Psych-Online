package online.objects;

import online.network.FunkinNetwork;

class NicommentsView extends FlxTypedGroup<Nicomment> {
	var songComments:Array<SongComment>;

	public var alpha:Float = 1.0;
	public var offsetY:Float = 0;

    public function new(songId:String) {
		super();

        songComments = FunkinNetwork.fetchSongComments(songId) ?? [];
    }

    override function update(elapsed) {
        super.update(elapsed);

		while (songComments.length > 0 && songComments[0].at <= Conductor.songPosition) {
			var comment = songComments.shift();

			var text = recycle(Nicomment);
			text.init(comment.content, this);
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
		scrollFactor.set(0, 0);
	}

	var speed:Float = 1;

	public function init(content:String, nico:NicommentsView) {
		setPosition(camera.viewRight + camera.viewMarginRight, nico.offsetY + FlxG.random.float(20, 250));
		text = content;
		speed = FlxG.random.float(1, 2);
		alpha = nico.alpha;
	}

	override function update(elapsed) {
		super.update(elapsed);

		x -= elapsed * 200 * speed;
		if (!isOnScreen(camera) && x < camera.viewX) {
			kill();
		}
	}
}

typedef SongComment = {
	var player:String;
	var content:String;
	var at:Float;
}