package online.substates;

class SoFunkinSubstate extends MusicBeatSubstate {
	public var options:Array<String> = [];
	public var callback:Int->Bool;
	public var iconCallback:(Int, FlxSprite)->FlxSprite;

	private var grpTexts:FlxTypedGroup<FlxSprite>;
	private var grpIcons:FlxTypedGroup<FlxSprite>;

	private var curSelected:Int = 0;

	public function new(options:Array<String>, ?selected:Int = 0, callback:Int->Bool, ?iconCallback:(Int, FlxSprite)->FlxSprite) {
        super();
        
		curSelected = selected;
		this.options = options;
		this.callback = callback;
		this.iconCallback = iconCallback;
    }

	override function create() {
		var bg:FlxSprite = new FlxSprite();
		bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.scrollFactor.set();
		bg.alpha = 0.7;
		add(bg);

		grpTexts = new FlxTypedGroup<FlxSprite>();
		add(grpTexts);

		grpIcons = new FlxTypedGroup<FlxSprite>();
		add(grpIcons);

		for (i in 0...options.length) {
			var leText:Scrollable;
			if (!ClientPrefs.data.disableFreeplayAlphabet)
				leText = new Alphabet(90, 320, options[i], true);
			else
				leText = new online.objects.AlphaLikeText(90, 320, options[i]);
			leText.isMenuItem = true;
			leText.targetY = i - curSelected;
			grpTexts.add(cast leText);
			leText.snapToPosition();

			if (iconCallback != null) {
				var icon = iconCallback(i, cast(leText));
				if (icon != null)
					grpIcons.add(icon);
			}
		}
		changeSelection();

		super.create();
	}

	override function update(elapsed:Float) {
		var shiftMult = FlxG.keys.pressed.SHIFT ? 2 : 1;
		if (controls.UI_UP_P) {
			changeSelection(-1 * shiftMult);
		}
		if (controls.UI_DOWN_P) {
			changeSelection(1 * shiftMult);
		}
		if (FlxG.mouse.wheel != 0) {
			changeSelection(-shiftMult * FlxG.mouse.wheel);
		}

		if (controls.BACK) {
			close();
		}

		if (controls.ACCEPT) {
			if (callback(curSelected))
				close();
		}

		var bullShit:Int = 0;
		var item:Scrollable;
		for (_item in grpTexts.members) {
			item = cast _item;
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0) {
				item.alpha = 1;
			}
		}
		super.update(elapsed);
	}

	function changeSelection(change:Int = 0) {
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = options.length - 1;
		if (curSelected >= options.length)
			curSelected = 0;
	}
}