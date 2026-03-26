package substates;

class PromptSubState extends MusicBeatSubstate
{
	var bg:FlxSprite;
	var alphabetArray:Array<Alphabet> = [];
	var onYes:Bool = false;
	var yesText:Alphabet;
	var noText:Alphabet;
    var callback:Bool->Void;

	// Week -1 = Freeplay
	public function new(title:String, posttext:String, callback:Bool->Void)
	{
		super();

        this.callback = callback;

		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		var tooLong:Float = 0.7; //Fucking Winter Horrorland

		var text:Alphabet = new Alphabet(0, 180, title, true);
		text.scaleX = tooLong;
		text.scaleY = tooLong;
		text.screenCenter(X);
		alphabetArray.push(text);
		text.alpha = 0;
		text.scrollFactor.set();
		add(text);

		var text:Alphabet = new Alphabet(0, text.y + 90, posttext, true);
		text.scaleX = tooLong;
		text.scaleY = tooLong;
		text.screenCenter(X);
		alphabetArray.push(text);
		text.alpha = 0;
		text.scrollFactor.set();
		add(text);

		yesText = new Alphabet(0, text.y + 150, 'Yes', true);
		yesText.screenCenter(X);
		yesText.x -= 200;
		yesText.scrollFactor.set();
		add(yesText);

		noText = new Alphabet(0, text.y + 150, 'No', true);
		noText.screenCenter(X);
		noText.x += 200;
		noText.scrollFactor.set();
		add(noText);

		updateOptions();
	}

    var inputDelay:Float = 0.1;
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		bg.alpha += elapsed * 1.5;
		if(bg.alpha > 0.6) bg.alpha = 0.6;

		for (i in 0...alphabetArray.length) {
			var spr = alphabetArray[i];
			spr.alpha += elapsed * 2.5;
		}

        if (inputDelay > 0)
            inputDelay -= elapsed;
        else
            inputCheck();
	}

    function inputCheck() {
		if(controls.UI_LEFT_P || controls.UI_RIGHT_P) {
			FlxG.sound.play(Paths.sound('scrollMenu'), 1);
			onYes = !onYes;
			updateOptions();
		}
		if(controls.BACK) {
			FlxG.sound.play(Paths.sound('cancelMenu'), 1);
			close();
            callback(false);
		} else if(controls.ACCEPT) {
			FlxG.sound.play(Paths.sound('cancelMenu'), 1);
			close();
            callback(onYes);
		}
    }

	function updateOptions() {
		var scales:Array<Float> = [0.75, 1];
		var alphas:Array<Float> = [0.6, 1.25];
		var confirmInt:Int = onYes ? 1 : 0;

		yesText.alpha = alphas[confirmInt];
		yesText.scale.set(scales[confirmInt], scales[confirmInt]);
		noText.alpha = alphas[1 - confirmInt];
		noText.scale.set(scales[1 - confirmInt], scales[1 - confirmInt]);
	}
}