package online.states;

import flixel.FlxObject;

class OpenURL extends MusicBeatSubstate {
    final url:String;
	var yes:FlxText;
	var yesBg:FlxSprite;
	var no:FlxText;
	var noBg:FlxSprite;

    var selected:Int = -1;

	var swagPrompt:String = "Do you want to open URL:";

	public static function open(url:String, ?swagPrompt:String) { 
        if (FlxG.state.subState != null)
			FlxG.state.subState.close();
		FlxG.state.openSubState(new OpenURL(url, swagPrompt));
    }
	function new(url:String, ?swagPrompt:String) {
        super();

		this.url = url.trim();
		if (swagPrompt != null)
		    this.swagPrompt = swagPrompt;
    }

    override function create() {
        super.create();

		var bg = new FlxSprite();
		bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.8;
		add(bg);

		var prompt = new FlxText(0, 0, FlxG.width, swagPrompt + "\n\n" + url);
		prompt.setFormat("VCR OSD Mono", 25, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		prompt.y = 200;
		prompt.scrollFactor.set(0, 0);
		prompt.screenCenter(X);
		add(prompt);

		yes = new FlxText(0, 0, 0, "Open");
		yes.setFormat("VCR OSD Mono", 30, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		yes.x = FlxG.width / 2 - yes.width - 100;
		yes.y = 400;
		yes.scrollFactor.set(0, 0);
		yesBg = new FlxSprite();
		yesBg.makeGraphic(1, 1, 0x5D000000);
		yesBg.updateHitbox();
		yesBg.y = yes.y;
		yesBg.x = yes.x;
		yesBg.scale.set(yes.width, yes.height);
		yesBg.updateHitbox();
		add(yesBg);
        add(yes);

		no = new FlxText(0, 0, 0, "Close");
		no.setFormat("VCR OSD Mono", 30, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		no.x = FlxG.width / 2 - no.width + 100;
		no.y = yes.y;
		no.scrollFactor.set(0, 0);
		noBg = new FlxSprite();
		noBg.makeGraphic(1, 1, 0x5D000000);
		noBg.updateHitbox();
		noBg.y = no.y;
		noBg.x = no.x;
		noBg.scale.set(no.width, no.height);
		noBg.updateHitbox();
		add(noBg);
		add(no);
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if (FlxG.mouse.justMoved) {
			if (mouseInsideOf(yesBg)) {
				selected = 0;
            }
			else if (mouseInsideOf(noBg)) {
				selected = 1;
			}
            else {
				selected = -1;
            }
        }

		if (controls.UI_LEFT_P || controls.UI_RIGHT_P) {
			selected++;

			if (selected > 1) {
				selected = 0;
			}
			else if (selected < 0) {
				selected = 1;
			}
        }

		if (selected == 0) {
            if (controls.ACCEPT || FlxG.mouse.justPressed) {
				FlxG.openURL(url);
				close();
            }
			yes.alpha = 1;
			no.alpha = 0.7;
		}
		else if (selected == 1) {
			if (controls.ACCEPT || FlxG.mouse.justPressed) {
                close();
            }
			yes.alpha = 0.7;
			no.alpha = 1;
        }
        else {
			yes.alpha = 0.7;
			no.alpha = 0.7;
        }
        
		if (controls.BACK) {
			close();
		}
    }

	function mouseInsideOf(object:FlxObject) {
		return FlxG.mouse.x >= object.x
			&& FlxG.mouse.x <= object.x + object.width
			&& FlxG.mouse.y >= object.y
			&& FlxG.mouse.y <= object.y + object.height;
	}
}