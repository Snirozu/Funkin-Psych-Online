package online.states;

import lime.system.Clipboard;
import openfl.events.KeyboardEvent;

class SetupMods extends MusicBeatState {
	var items:FlxTypedSpriteGroup<FlxText>;

    public function new(mods:Array<String>) {
        super();

        swagMods = mods;
    }

	var swagMods:Array<String> = [];

	var curSelected = 0;
	var inInput = false;
    var modsInput:Array<String> = [];

    override function create() {
        super.create();

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xff5a1f46;
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.scrollFactor.set(0, 0);
		add(bg);

		var lines:FlxSprite = new FlxSprite().loadGraphic(Paths.image('coolLines'));
		lines.updateHitbox();
		lines.screenCenter();
		lines.antialiasing = ClientPrefs.data.antialiasing;
		lines.scrollFactor.set(0, 0);
		add(lines);

		items = new FlxTypedSpriteGroup<FlxText>();
		var prevText:FlxText = null;
		var i = 0;
		for (itm in swagMods) {
			var text = new FlxText(0, 0, 0, itm);
			if (prevText != null) {
				text.y += prevText.height * i;
			}
			text.ID = i;
			text.setFormat("VCR OSD Mono", 30, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			items.add(prevText = text);
			modsInput.push(OnlineMods.getModURL(itm));
			i++;
		}
		items.screenCenter(Y);
		add(items);

		var title = new FlxText(0, 0, FlxG.width, 
        "Before you play, you need to set links for your mods!\nGamebanana mod links need to look similiar to this: https://gamebanana.com/mods/479714\nSelect them with ACCEPT, paste links with CTRL + V\nWhen you finish or if you want to skip press BACK"
        );
		title.setFormat("VCR OSD Mono", 22, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		title.y = 50;
		title.scrollFactor.set(0, 0);

		var titleBg = new FlxSprite();
		titleBg.makeGraphic(1, 1, 0x8C000000);
		titleBg.updateHitbox();
		titleBg.y = title.y;
		titleBg.x = title.x;
		titleBg.scale.set(title.width, title.height);
		titleBg.updateHitbox();
		titleBg.scrollFactor.set(0, 0);
		add(titleBg);
		add(title);

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);

		changeSelection(0);
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if (disableInput) return;

		if (!inInput) {
			if (controls.ACCEPT) {
				inInput = true;
				changeSelection(0);
			}
            
			if (controls.UI_UP_P)
				changeSelection(-1);
			else if (controls.UI_DOWN_P)
				changeSelection(1);

			if (controls.BACK) {
                var i = 0;
                for (mod in swagMods) {
					OnlineMods.saveModURL(mod, modsInput[i]);
                    i++;
                }

				FlxG.switchState(new Lobby());
				FlxG.sound.play(Paths.sound('cancelMenu'));
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
			}
        }
    }

    function changeSelection(difference:Int) {
		curSelected += difference;

		if (curSelected >= swagMods.length) {
			curSelected = 0;
		}
		else if (curSelected < 0) {
			curSelected = swagMods.length - 1;
		}

		for (item in items) {
			item.text = getItemName(item.ID);
			item.alpha = inInput ? 0.5 : 0.7;
			if (item.ID == curSelected) {
				FlxG.camera.follow(item);
				item.text = "> " + item.text + " <";
				item.alpha = 1;
			}
			item.screenCenter(X);
		}
    }

	function getItemName(item:Int) {
		if (item == curSelected && inInput)
			return swagMods[item] + ": " + modsInput[item];
		return swagMods[item];
	}

	function onKeyDown(e:KeyboardEvent) {
		if (!inInput)
			return;

		var key = e.keyCode;

		if (e.charCode == 0) { // non-printable characters crash String.fromCharCode
			return;
		}

		if (key == 46) { // delete
			return;
		}

		if (key == 8) { // bckspc
			modsInput[curSelected] = modsInput[curSelected].substring(0, modsInput[curSelected].length - 1);
			changeSelection(0);
			return;
		}
		else if (key == 13 || key == 27) { // enter or esc
			tempDisableInput();
			inInput = false;
			changeSelection(0);
			return;
		}

		var newText:String = String.fromCharCode(e.charCode);
		if ((curSelected == 0 && !e.shiftKey) || (curSelected != 0 && e.shiftKey)) {
			newText = newText.toUpperCase();
		}
		else {
			newText = newText.toLowerCase();
		}

		if (key == 86 && e.ctrlKey) {
			newText = Clipboard.text;
		}

		if (newText.length > 0) {
			modsInput[curSelected] += newText;
		}

		changeSelection(0);
	}

	var disableInput = false;
	function tempDisableInput() {
		disableInput = true;
		new FlxTimer().start(0.1, (t) -> disableInput = false);
	}
}