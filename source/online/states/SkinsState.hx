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
	var characterCamera:FlxCamera;

	var hud:FlxCamera;
	var charText:FlxText;
	var charSelect:FlxText;

	static var flipped:Bool = false;

    override function create() {
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In a Skin Selector.", null, null, false);
		#end

		Mods.loadTopMod();
		WeekData.setDirectoryFromWeek();

		FlxG.cameras.add(characterCamera = new FlxCamera(), false);
		FlxG.cameras.add(hud = new FlxCamera(), false);
		CustomFadeTransition.nextCamera = hud;
		characterCamera.bgColor.alpha = 0;
		hud.bgColor.alpha = 0;
		characterCamera.zoom = 0.8;

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xff303030;
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

        var i = 0;

		var oldModDir = Mods.currentModDirectory;

		// var defaultName = !flipped ? "default" : "default-player";
		// characterList.set(defaultName, new Character(0, 0, defaultName, flipped));
		// charactersMod.set(defaultName, null);
		// charactersName.set(i, defaultName);
        // i++;

		var hardList = [];

		for (name in [null].concat(Mods.parseList().enabled)) {
			var characters:String;
			if (name == null) {
				Mods.loadTopMod();
				characters = 'assets/characters/';
			}
			else {
				Mods.currentModDirectory = name;
				characters = Paths.mods(name + '/characters/');
			}
			if (FileSystem.exists(characters)) {
				for (file in FileSystem.readDirectory(characters)) {
					var path = Path.join([characters, file]);
					if (!sys.FileSystem.isDirectory(path) && file.endsWith('.json')) {
						var character:String = file.substr(0, file.length - 5);
						if (!flipped ? character.endsWith("-player") : !character.endsWith("-player")) {
                            continue;
                        }

						if (!hardList.contains(character) && FileSystem.exists(Path.join([characters, (!flipped ? character + "-player" : character.substring(0, character.length - "-player".length)) + ".json"]))) {
							if (name == null)
								hardList.push(character);

							characterList.set(character, new Character(0, 0, character, flipped));
							charactersMod.set(character, name);
							charactersName.set(i, character);

							characterList.get(character).updateHitbox();

							if (curCharacter == -1 && isEquiped(name, !flipped ? character + "-player" : character.substring(0, character.length - "-player".length))) {
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
		character.cameras = [characterCamera];
        add(character);

		var swagText = new FlxText(0, 20, FlxG.width);
		swagText.text = 'Choose your skin!';
		swagText.setFormat("VCR OSD Mono", 25, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		swagText.cameras = [hud];
		add(swagText);

		var swagText = new FlxText(0, swagText.y + swagText.height + 5, FlxG.width);
		swagText.text = 'Press F1 if you want to know how to create your own skin!';
		swagText.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		swagText.alpha = 0.8;
		swagText.cameras = [hud];
		add(swagText);

		charText = new FlxText(0, 0, FlxG.width);
		charText.text = '< Characters >';
		charText.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		charText.y = FlxG.height - charText.height - 70;
		charText.cameras = [hud];
		add(charText);

		charSelect = new FlxText(0, 0, FlxG.width);
		charSelect.text = 'Press ACCEPT to select!';
		charSelect.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		charSelect.y = charText.y + charText.height + 5;
		charSelect.alpha = 0.8;
		charSelect.cameras = [hud];
		add(charSelect);

		var swagText = new FlxText(0, charSelect.y + charSelect.height + 5, FlxG.width);
		swagText.text = 'Use Note keybinds while pressing SHIFT to move!';
		swagText.setFormat("VCR OSD Mono", 18, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		swagText.alpha = 0.8;
		swagText.cameras = [hud];
		add(swagText);

		var tip1 = new FlxText(20, 0, FlxG.width, 'UI LEFT - Switch to previous\n8 - Edit skin');
		tip1.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		tip1.y = charSelect.y;
		tip1.alpha = 0.6;
		tip1.cameras = [hud];
		add(tip1);

		var tip2 = new FlxText(-20, 0, FlxG.width, 'UI RIGHT - Switch to next\n9 - Flip skin');
		tip2.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		tip2.y = tip1.y;
		tip2.alpha = tip1.alpha;
		tip2.cameras = [hud];
		add(tip2);

		setCharacter(0);

		super.create();
		
		CustomFadeTransition.nextCamera = hud; // wat

		GameClient.send("status", "Selects their skin");
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
				if (ClientPrefs.data.modSkin != null && ClientPrefs.data.modSkin.length >= 2) {
					GameClient.send("setSkin", [ClientPrefs.data.modSkin[0], ClientPrefs.data.modSkin[1], OnlineMods.getModURL(ClientPrefs.data.modSkin[0])]);
				}
				else {
					GameClient.send("setSkin", null);
				}
			}
			FlxG.switchState(() -> GameClient.isConnected() ? new Room() : new OptionsState());
        }

        if (controls.ACCEPT) {
			var charName = charactersName.get(curCharacter);
			charName = !flipped ? charName : charName.substring(0, charName.length - "-player".length);

			if (charName == "default")
				ClientPrefs.data.modSkin = null;
            else
				ClientPrefs.data.modSkin = [charactersMod.get(charactersName.get(curCharacter)), charName];
            ClientPrefs.saveSettings();
            
			if (isEquiped(charactersMod.get(charactersName.get(curCharacter)), charName)) {
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
			FlxG.switchState(() -> new CharacterEditorState(charactersName.get(curCharacter), false, true));
		}

		if (FlxG.keys.justPressed.NINE) {
			flipped = !flipped;
			LoadingState.loadAndSwitchState(new SkinsState());
		}

		if (FlxG.keys.justPressed.F1) {
			RequestState.requestURL("https://github.com/Snirozu/Funkin-Psych-Online/wiki#skins", true);
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

			character.members[0].x = 420 + character.members[0].positionArray[0];
			character.members[0].y = -100 + character.members[0].positionArray[1];

			charText.text = '< Character: $curCharName - ${charactersMod.get(charactersName.get(curCharacter)) ?? "Vanilla"} >';

			curCharName = !flipped ? curCharName : curCharName.substring(0, curCharName.length - "-player".length);
			if (isEquiped(charactersMod.get(charactersName.get(curCharacter)), curCharName)) {
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
		if (skin.endsWith("-player"))
			skin = !flipped ? skin : skin.substring(0, skin.length - "-player".length);

		if (skin == "default" && ClientPrefs.data.modSkin == null) {
            return true;
        }

		return ClientPrefs.data.modSkin != null && ClientPrefs.data.modSkin.length >= 2
			&& mod == ClientPrefs.data.modSkin[0] && skin == ClientPrefs.data.modSkin[1];
    }
}