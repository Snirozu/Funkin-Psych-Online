package online.states;

import states.editors.CharacterEditorState;
import backend.WeekData;
import haxe.io.Path;
import sys.FileSystem;
import flixel.group.FlxGroup;
import objects.Character;

// this is the most painful class to be made 
class SkinsState extends MusicBeatState {
    // kill me
    var characterList:Map<String, Character> = new Map<String, Character>();
	var charactersName:Map<Int, String> = new Map<Int, String>();
	var charactersLength:Int = 0;
    var character:FlxTypedGroup<Character>;
    static var curCharacter:Int = -1;
    var charactersMod:Map<String, String> = new Map<String, String>();

	var charText:FlxText;
	var charSelect:FlxText;

    override function create() {
        super.create();

		DiscordClient.changePresence("In a Skin Selector.", null, null, false);

		Mods.loadTopMod();
		WeekData.setDirectoryFromWeek();

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xff303030;
		bg.screenCenter();
		bg.antialiasing = Wrapper.prefAntialiasing;
		add(bg);

        var i = 0;

		var oldModDir = Mods.currentModDirectory;

		characterList.set("default", new Character(0, 0, "default"));
		charactersMod.set("default", null);
		charactersName.set(i, "default");
        i++;

		for (mod in Mods.parseList().enabled) {
			Mods.currentModDirectory = mod;
			var characters = Paths.mods(mod + '/characters/');
			if (FileSystem.exists(characters)) {
				for (file in FileSystem.readDirectory(characters)) {
					var path = Path.join([characters, file]);
					if (!sys.FileSystem.isDirectory(path) && file.endsWith('.json')) {
						var character:String = file.substr(0, file.length - 5);
                        if (character.endsWith("-player")) {
                            continue;
                        }

						if (FileSystem.exists(Path.join([characters, character + "-player.json"]))) {
							characterList.set(character, new Character(0, 0, character));
							charactersMod.set(character, mod);
							charactersName.set(i, character);

							characterList.get(character).updateHitbox();

							if (curCharacter == -1 && isEquiped(mod, character)) {
								curCharacter = i;
							}

							i++;
                        }
                    }
                }
            }
        }
		charactersLength = i;

		Mods.currentModDirectory = oldModDir;

        character = new FlxTypedGroup<Character>();
        add(character);

		var swagText = new FlxText(0, 50, FlxG.width);
		swagText.text = 'Choose your skin!';
		swagText.setFormat("VCR OSD Mono", 25, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(swagText);

		var swagText = new FlxText(0, swagText.y + swagText.height + 5, FlxG.width);
		swagText.text = 'Use Note keybinds while pressing SHIFT to move!';
		swagText.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		swagText.alpha = 0.8;
		add(swagText);

		charText = new FlxText(0, 0, FlxG.width);
		charText.text = '< Characters >';
		charText.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		charText.y = FlxG.height - charText.height - 50;
		add(charText);

		charSelect = new FlxText(0, 0, FlxG.width);
		charSelect.text = 'Press ACCEPT to select!';
		charSelect.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		charSelect.y = charText.y + charText.height + 5;
		charSelect.alpha = 0.8;
		add(charSelect);

		var tip1 = new FlxText(20, 0, FlxG.width, 'UI LEFT - Switch to previous\n8 - Edit skin');
		tip1.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		tip1.y = charText.y;
		tip1.alpha = 0.6;
		add(tip1);

		var tip2 = new FlxText(-20, 0, FlxG.width, 'UI RIGHT - Switch to next');
		tip2.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		tip2.y = charText.y;
		tip2.alpha = tip1.alpha;
		add(tip2);

		setCharacter(0);
    }

    var acceptSound:FlxSound;

    override function update(elapsed) {
        super.update(elapsed);

        if (FlxG.keys.pressed.SHIFT) {
			if (controls.NOTE_UP) {
				character.members[0].playAnim("singUP");
			}
			if (controls.NOTE_DOWN) {
				character.members[0].playAnim("singDOWN");
			}
			if (controls.NOTE_LEFT) {
				character.members[0].playAnim("singLEFT");
			}
			if (controls.NOTE_RIGHT) {
				character.members[0].playAnim("singRIGHT");
			}
        }
        else {
			if (controls.UI_LEFT_P) {
				setCharacter(1);
			}
			if (controls.UI_RIGHT_P) {
				setCharacter(-1);
			}
        }

        if (controls.BACK) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			if (GameClient.isConnected()) {
				if (Wrapper.prefModSkin != null && Wrapper.prefModSkin.length >= 2) {
					GameClient.send("setSkin", [Wrapper.prefModSkin[0], Wrapper.prefModSkin[1], OnlineMods.getModURL(Wrapper.prefModSkin[0])]);
				}
				else {
					GameClient.send("setSkin", null);
				}
			}
			MusicBeatState.switchState(GameClient.isConnected() ? new Room() : new OnlineState());
        }

        if (controls.ACCEPT) {
			if (charactersName.get(curCharacter) == "default")
				Wrapper.prefModSkin = null;
            else
				Wrapper.prefModSkin = [charactersMod.get(charactersName.get(curCharacter)), charactersName.get(curCharacter)];
            ClientPrefs.saveSettings();
            
			if (isEquiped(charactersMod.get(charactersName.get(curCharacter)), charactersName.get(curCharacter))) {
				charSelect.text = 'Selected!';
				charSelect.alpha = 1;
			}
			else {
				charSelect.text = 'Press ACCEPT to select!';
				charSelect.alpha = 0.8;
			}
			if (acceptSound == null || !acceptSound.playing)
			    acceptSound = FlxG.sound.play(Paths.sound('confirmMenu'));
			character.members[0].playAnim("hey");
        }

		if (FlxG.keys.justPressed.EIGHT) {
			Mods.currentModDirectory = charactersMod.get(charactersName.get(curCharacter));
			MusicBeatState.switchState(new CharacterEditorState(charactersName.get(curCharacter), false, true));
		}
    }

    function setCharacter(difference:Int) {
		curCharacter += difference;

		if (curCharacter >= charactersLength) {
			curCharacter = 0;
		}
		else if (curCharacter < 0) {
			curCharacter = charactersLength - 1;
		}

        character.clear();
		if (charactersName.exists(curCharacter)) {
			var curCharName = charactersName.get(curCharacter);
			character.add(characterList.get(curCharName));
			character.members[0].dance();
			character.members[0].animation.finishCallback = function(name) character.members[0].dance();
			character.members[0].screenCenter(X);
			character.members[0].y = 600 - character.members[0].height;
			charText.text = '< Character: $curCharName >';

			if (isEquiped(charactersMod.get(curCharName), curCharName)) {
				charSelect.text = 'Selected!';
				charSelect.alpha = 1;
			}
            else {
				charSelect.text = 'Press ACCEPT to select!';
				charSelect.alpha = 0.8;
            }
        }
    }

    function isEquiped(mod:String, skin:String) {
		if (skin == "default" && Wrapper.prefModSkin == null) {
            return true;
        }

		return Wrapper.prefModSkin != null && Wrapper.prefModSkin.length >= 2
			&& mod == Wrapper.prefModSkin[0] && skin == Wrapper.prefModSkin[1];
    }
}