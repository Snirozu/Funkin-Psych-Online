package online.substates;

class PostTextSubstate extends MusicBeatSubstate {
	var title:String;
	var onEnter:String->Void;

	public function new(title:String, onEnter:String->Void) {
        super();

		this.title = title;
		this.onEnter = onEnter;
    }

	var input:InputText;
	var coolCam:FlxCamera;

    override function create() {
        super.create();

		coolCam = new FlxCamera();
		coolCam.bgColor.alpha = 0;
		FlxG.cameras.add(coolCam, false);

		cameras = [coolCam];

		var bg = new FlxSprite();
		bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.7;
		bg.scrollFactor.set(0, 0);
		add(bg);

		var title = new FlxText(0, 0, FlxG.width, this.title + "\n\n(Press ENTER to submit)");
		title.setFormat("VCR OSD Mono", 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		title.y = FlxG.height / 2 - title.height / 2 - 150;
		title.scrollFactor.set();
		add(title);

		input = new InputText(0, 0, FlxG.width, text -> {
            if (text.trim().length <= 0)
                return;

			onEnter(text);
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

	override function destroy() {
		super.destroy();

		FlxG.cameras.remove(coolCam);
	}
}