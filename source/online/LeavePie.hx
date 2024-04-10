package online;

import flixel.addons.display.FlxPieDial;

class LeavePie extends FlxTypedSpriteGroup<FlxSprite> {
	public var pieDial:FlxPieDial;
	var exitTip:FlxText;
	var theFog:FlxSprite;
	var finished:Bool = false;
    
    public function new() {
        super();

		theFog = new FlxSprite();
		theFog.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		theFog.alpha = 0;
		add(theFog);

		pieDial = new FlxPieDial(10, 10, 25, FlxColor.WHITE, 36, FlxPieDialShape.CIRCLE, true, 12);
		pieDial.amount = 0.0;
		pieDial.replaceColor(FlxColor.BLACK, FlxColor.TRANSPARENT);
		pieDial.antialiasing = ClientPrefs.data.antialiasing;
		add(pieDial);

		exitTip = new FlxText(pieDial.x + 80, pieDial.y + 5, 0, "Hold BACK to leave!");
		exitTip.setFormat("VCR OSD Mono", 18, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		exitTip.alpha = 0;
		add(exitTip);
    }

    override function update(elapsed) {
        super.update(elapsed);

		if (getState().controls.pressed('back') && !ChatBox.instance.focused) {
			exitTip.alpha = 1;
			pieDial.amount += elapsed * 2;
			pieDial.visible = true;
			if (!finished && pieDial.amount >= 1.0) {
				finished = true;

				if (FlxG.state is PlayState)
					if (FlxG.keys.pressed.F1)
						GameClient.leaveRoom();
					else
						GameClient.send("requestEndSong");
				else
					GameClient.leaveRoom();
			}
		}
		else {
			pieDial.amount -= elapsed * 6;
			exitTip.alpha -= elapsed;
		}

		if (pieDial.amount <= 0.03) {
			pieDial.visible = false;
		}
		theFog.alpha = pieDial.amount;
    }

    function getState():MusicBeatState {
        return cast FlxG.state;
    }
}