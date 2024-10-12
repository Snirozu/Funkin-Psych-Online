package online.substates;

import online.network.FunkinNetwork;

class PostCommentSubstate extends MusicBeatSubstate {
    public function new() {
        super();
    }

	var input:InputText;

    override function create() {
        super.create();

		input = new InputText(0, 0, FlxG.width, text -> {
			FunkinNetwork.postSongComment(PlayState.instance.songId, text, Conductor.songPosition);
			close();
		});
		input.setFormat("VCR OSD Mono", 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		input.y = FlxG.height / 2 - input.height / 2;
		input.scrollFactor.set();
		add(input);
    }

    var confirmBack = false;
    override function update(elapsed) {
        super.update(elapsed);

		input.hasFocus = true;

        if (input.text.length <= 0 && controls.BACK) {
            if (!confirmBack) {
				confirmBack = true;
                return;
            }
            close();
        }
		else if (input.text.length > 0) {
			confirmBack = false;
        }
    }
}