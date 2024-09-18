package online.states;

import states.FreeplayState;
import states.editors.CharacterEditorState;
import backend.WeekData;
import haxe.io.Path;
import sys.FileSystem;
import flixel.group.FlxGroup;
import objects.Character;

// this is the most painful class to be made 
class SkinsState extends MusicBeatState {
    // kill me
    //var characterList:Map<String, Character> = new Map<String, Character>();
	var charactersName:Map<Int, String> = new Map<Int, String>();
	var charactersLength:Int = 0;
    var character:FlxTypedGroup<Character>;
    static var curCharacter:Int = -1;
    var charactersMod:Map<String, String> = new Map<String, String>();
	var characterCamera:FlxCamera;

	var hud:FlxCamera;
	var charSelect:FlxText;

	var bg:FlxSprite;
	var title:Alphabet;
	var arrowLeft:Alphabet;
	var arrowRight:Alphabet;

	static var flipped:Bool = false;

	static var backClass:Class<Dynamic>;

	var reloadedState:Bool = false;
	public function new() {
		super();

		if (FlxG.state is SkinsState) {
			reloadedState = true;
			return;
		}

		backClass = Type.getClass(FlxG.state);
	}

	var blackRectangle:FlxSprite;

	public static var music:FlxSound;
	public static var musicIntro:FlxSound;
	
	static var prevConBPM:Float;
	static var prevConBPMChanges:Array<backend.BPMChangeEvent>;
	static var prevConTime:Float;

	var staticMan:FlxSprite;
	var selectTimer:FlxTimer;

    override function create() {
		Paths.clearUnusedMemory();
		Paths.clearStoredMemory();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Selects their Skin", null, null, false);
		#end

		Mods.loadTopMod();
		WeekData.setDirectoryFromWeek();
		
		if (!reloadedState) {
			for (v in [FlxG.sound.music, FreeplayState.vocals, FreeplayState.opponentVocals]) {
				if (v == null)
					continue;

				v.pause();
			}

			prevConBPM = Conductor.bpm;
			prevConBPMChanges = Conductor.bpmChangeMap;
			prevConTime = Conductor.songPosition;

			musicIntro = FlxG.sound.play(Paths.music('stayFunky-intro'), 1, false);
			music = FlxG.sound.play(Paths.music('stayFunky'), 1, true);
			music.pause();
			musicIntro.onComplete = () -> {
				music.play();
			}

			musicIntro.persist = true;
			music.persist = true;
			FlxG.sound.list.add(musicIntro);
			FlxG.sound.list.add(music);

			Conductor.bpm = 90;
			Conductor.bpmChangeMap = [];
			Conductor.songPosition = 0;
		}

		FlxG.cameras.add(characterCamera = new FlxCamera(), false);
		FlxG.cameras.add(hud = new FlxCamera(), false);
		CustomFadeTransition.nextCamera = hud;
		characterCamera.bgColor.alpha = 0;
		hud.bgColor.alpha = 0;
		characterCamera.zoom = 0.8;

		blackRectangle = new FlxSprite();
		blackRectangle.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		blackRectangle.cameras = [hud];

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
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

							//characterList.set(character, new Character(0, 0, character, flipped));
							charactersMod.set(character, name);
							charactersName.set(i, character);

							//characterList.get(character).updateHitbox();

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

		staticMan = new FlxSprite();
		staticMan.antialiasing = ClientPrefs.data.antialiasing;
		staticMan.frames = Paths.getSparrowAtlas('randomChill');
		staticMan.animation.addByPrefix('idle', "LOCKED MAN instance 1", 24);
		staticMan.animation.play('idle');
		staticMan.flipX = !flipped;
		staticMan.updateHitbox();
		staticMan.screenCenter(XY);
		staticMan.y += 50;
		add(staticMan);

		var barUp = new FlxSprite();
		barUp.makeGraphic(FlxG.width, 100, FlxColor.BLACK);
		barUp.cameras = [hud];
		add(barUp);

		var barDown = new FlxSprite();
		barDown.makeGraphic(FlxG.width, 100, FlxColor.BLACK);
		barDown.y = FlxG.height - barDown.height;
		barDown.cameras = [hud];
		add(barDown);

		var swagText = new FlxText(10, 10);
		swagText.text = 'Press F1 for Help!';
		swagText.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		swagText.alpha = 0.4;
		swagText.cameras = [hud];
		swagText.x = FlxG.width - swagText.width - 10;
		add(swagText);

		title = new Alphabet(0, 0, "BOYFRIEND", true);
		title.cameras = [hud];
		title.y = barUp.height / 2 - title.height / 2;
		title.x = FlxG.width / 2 - title.width / 2;
		add(title);

		arrowLeft = new Alphabet(0, 0, "<", true);
		arrowLeft.cameras = [hud];
		arrowLeft.y = FlxG.height / 2 - arrowLeft.height / 2;
		arrowLeft.x = 100;
		add(arrowLeft);

		arrowRight = new Alphabet(0, 0, ">", true);
		arrowRight.cameras = [hud];
		arrowRight.y = FlxG.height / 2 - arrowRight.height / 2;
		arrowRight.x = FlxG.width - arrowRight.width - 100;
		add(arrowRight);

		charSelect = new FlxText(0, 0, FlxG.width);
		charSelect.text = 'Press ACCEPT to select!';
		charSelect.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		charSelect.y = barDown.y + barDown.height / 2 - charSelect.height / 2;
		charSelect.alpha = 0.8;
		charSelect.cameras = [hud];
		add(charSelect);

		var swagText = new FlxText(0, charSelect.y + charSelect.height + 5, FlxG.width);
		swagText.text = 'Use Note keybinds while pressing SHIFT to move!';
		swagText.setFormat("VCR OSD Mono", 18, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		swagText.alpha = 0.8;
		swagText.cameras = [hud];
		add(swagText);

		var tip1 = new FlxText(20, 0, FlxG.width, '8 - Edit skin');
		tip1.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		tip1.y = charSelect.y;
		tip1.alpha = 0.6;
		tip1.cameras = [hud];
		add(tip1);

		var tip2 = new FlxText(-20, 0, FlxG.width, 'TAB - Flip skin');
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
	var stopUpdates:Bool = false;
	var leftHoldTime:Float = 0;
	var rightHoldTime:Float = 0;

    override function update(elapsed) {
        super.update(elapsed);

		if (controls.UI_LEFT)
			leftHoldTime += elapsed;
		else
			leftHoldTime = 0;

		if (controls.UI_RIGHT)
			rightHoldTime += elapsed;
		else
			rightHoldTime = 0;

		if (stopUpdates) {
			return;
		}

		if (music != null && music.playing) {
			Conductor.songPosition = music.time;
		}

        if (FlxG.keys.pressed.SHIFT) {
			if (character.members[0] != null) {
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
        }
        else {
			if (controls.UI_LEFT_P) {
				setCharacter(-1);
			}
			else if (controls.UI_RIGHT_P) {
				setCharacter(1);
			}
        }

        if (controls.BACK) {
			stopUpdates = true;

			FlxG.sound.play(Paths.sound('cancelMenu'));
			if (GameClient.isConnected()) {
				if (ClientPrefs.data.modSkin != null && ClientPrefs.data.modSkin.length >= 2) {
					GameClient.send("setSkin", [ClientPrefs.data.modSkin[0], ClientPrefs.data.modSkin[1], OnlineMods.getModURL(ClientPrefs.data.modSkin[0])]);
				}
				else {
					GameClient.send("setSkin", null);
				}
			}

			FlxTween.tween(blackRectangle, {alpha: 1}, 0.5, {ease: FlxEase.quadInOut});
			blackRectangle.alpha = 0;
			add(blackRectangle);

			var funkySound = music.playing ? music : musicIntro;
			funkySound.fadeOut(0.5, 0, t -> {
				funkySound.stop();

				for (v in [FlxG.sound.music, FreeplayState.vocals, FreeplayState.opponentVocals]) {
					if (v == null)
						continue;

					v.play();
					v.fadeIn(0.5, 0, 1);
				}

				Conductor.bpm = prevConBPM;
				Conductor.bpmChangeMap = prevConBPMChanges;
				Conductor.songPosition = prevConTime;

				FlxG.switchState(() -> Type.createInstance(backClass, []));
			});
        }

        if (controls.ACCEPT) {
			var charName = charactersName.get(curCharacter);
			if (charName.endsWith("-player"))
				charName = charName.substring(0, charName.length - "-player".length);
			
			if (charName.endsWith("-pixel"))
				charName = charName.substring(0, charName.length - "-pixel".length);

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
				acceptSound = FlxG.sound.play(Paths.sound('CS_confirm'));

			if (character.members[0] != null)
				character.members[0].playAnim("hey");
        }

		if (FlxG.keys.justPressed.EIGHT) {
			Mods.currentModDirectory = charactersMod.get(charactersName.get(curCharacter));
			FlxG.switchState(() -> new CharacterEditorState(charactersName.get(curCharacter), false, true));
		}

		if (FlxG.keys.justPressed.TAB) {
			flipped = !flipped;
			LoadingState.loadAndSwitchState(new SkinsState());
		}

		if (FlxG.keys.justPressed.F1) {
			RequestState.requestURL("https://github.com/Snirozu/Funkin-Psych-Online/wiki#skins", true);
		}
    }

    function setCharacter(difference:Int, ?beatHold:Bool = false) {
		var prevCharacter = curCharacter;

		curCharacter += difference;

		if (curCharacter >= charactersLength) {
			curCharacter = beatHold ? 0 : charactersLength - 1;
		}
		else if (curCharacter < 0) {
			curCharacter = beatHold ? charactersLength - 1 : 0;
		}

		if (difference != 0 && curCharacter == prevCharacter) {
			return;
		}

		if (difference != 0) {
			FlxG.sound.play(Paths.sound('CS_select'));
		}

		arrowLeft.visible = curCharacter > 0;
		arrowRight.visible = curCharacter < charactersLength - 1;

		if (character.members[0] != null) {
			character.members[0].destroy();
		}
		character.clear();

		staticMan.visible = true;

		if (charactersName.exists(curCharacter)) {
			var curCharName = charactersName.get(curCharacter);

			if (selectTimer != null)
				selectTimer.cancel();

			selectTimer = new FlxTimer().start(1, t -> {
				var curCharName = charactersName.get(curCharacter); // re-define it lol

				if (character.members[0] != null) {
					character.members[0].destroy();
				}
				character.clear();

				staticMan.visible = false;

				// character.add(characterList.get(curCharName));

				Mods.currentModDirectory = charactersMod.get(curCharName);
				character.add(new Character(0, 0, curCharName, flipped));

				character.members[0].x = 420 + character.members[0].positionArray[0];
				character.members[0].y = -100 + character.members[0].positionArray[1];

				var hca = character.members[0].healthColorArray;
				tweenColor(FlxColor.fromRGB(hca[0], hca[1], hca[2]));
			});

			curCharName = !flipped ? curCharName : curCharName.substring(0, curCharName.length - "-player".length);

			title.text = curCharName == "default" ? "BOYFRIEND" : curCharName;
			title.x = FlxG.width / 2 - title.width / 2;

			if (isEquiped(Mods.currentModDirectory, curCharName)) {
				charSelect.text = 'Selected!';
				charSelect.alpha = 1;
			}
            else {
				charSelect.text = 'Press ACCEPT to select!';
				charSelect.alpha = 0.8;
            }

			tweenColor(FlxColor.fromRGB(150, 150, 150));
        }
    }

	var colorTween:FlxTween;
	function tweenColor(color:FlxColor) {
		if (colorTween != null) {
			colorTween.cancel();
		}
		colorTween = FlxTween.color(bg, 1, bg.color, color, {
			onComplete: function(twn:FlxTween) {
				colorTween = null;
			}
		});
	}

    function isEquiped(mod:String, skin:String) {
		if (skin.endsWith("-player"))
			skin = skin.substring(0, skin.length - "-player".length);

		if (skin.endsWith("-pixel"))
			skin = skin.substring(0, skin.length - "-pixel".length);

		if (skin == "default" && ClientPrefs.data.modSkin == null) {
            return true;
        }

		return ClientPrefs.data.modSkin != null && ClientPrefs.data.modSkin.length >= 2
			&& mod == ClientPrefs.data.modSkin[0] && skin == ClientPrefs.data.modSkin[1];
    }

	override function beatHit() {
		super.beatHit();

		if (character.members[0] != null && character.members[0].animation.curAnim.finished)
			character.members[0].dance();

		if (staticMan.visible)
			staticMan.animation.play('idle');
	}

	override function stepHit() {
		super.stepHit();

		// thats how you do it ninjamuffin duh
		if (!FlxG.keys.pressed.SHIFT)
			if (leftHoldTime > 0.5) {
				setCharacter(-1, true);
			}
			else if (rightHoldTime > 0.5) {
				setCharacter(1, true);
			}
	}
}