package online.states;

import flixel.FlxObject;
import lime.system.Clipboard;
import flixel.group.FlxGroup;
import openfl.events.KeyboardEvent;

class OptionsState extends MusicBeatState {
	var items:FlxTypedGroup<InputOption> = new FlxTypedGroup<InputOption>();
    static var curSelected:Int = 0;

	var camFollow:FlxObject;

    override function create() {
        super.create();

		camera.follow(camFollow = new FlxObject(), 0.1);

		DiscordClient.changePresence("In Online Settings.", null, null, false);

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xff2e2b1a;
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = Wrapper.prefAntialiasing;
		bg.scrollFactor.set(0, 0);
		add(bg);

		var nicknameOption:InputOption;
		items.add(nicknameOption = new InputOption("Nickname", "Set your nickname here!", "Boyfriend"));
		nicknameOption.input.text = Wrapper.prefNickname;
		nicknameOption.y = 50;
		nicknameOption.screenCenter(X);

        var serverOption:InputOption;
		items.add(serverOption = new InputOption("Server Address", "Set to empty if you want to use the default server\nor to 'ws://localhost:2567' if you're playing in LAN", GameClient.defaultAddress));
		serverOption.input.text = GameClient.serverAddress;
		serverOption.y = nicknameOption.y + nicknameOption.height + 50;
		serverOption.screenCenter(X);

		var skinsOption:InputOption;
		items.add(skinsOption = new InputOption("Skin", "Choose your skin here!", null, false));
		skinsOption.y = serverOption.y + serverOption.height + 50;
		skinsOption.screenCenter(X);

		var modsOption:InputOption;
		items.add(modsOption = new InputOption("Setup Mods", "Set the URL's of your mods here!", null, false));
		modsOption.y = skinsOption.y + skinsOption.height + 50;
		modsOption.screenCenter(X);

		var trustedOption:InputOption;
		items.add(trustedOption = new InputOption("Clear Trusted Domains", "Clear the list of all trusted domains!", null, false));
		trustedOption.y = modsOption.y + modsOption.height + 50;
		trustedOption.screenCenter(X);

		if (Wrapper.prefGapiRefreshToken != null) {
			var googleOption:InputOption;
			items.add(googleOption = new InputOption("Unlink Google", "Unlink from Google here!\nThis can also help with Google Drive errors\n(if they happen to throw them)", null, false));
			googleOption.y = trustedOption.y + trustedOption.height + 50;
			googleOption.screenCenter(X);
		}

		add(items);

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);

        changeSelection(0);
    }

	override function destroy() {
		super.destroy();

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
	}

    override function update(elapsed) {
        super.update(elapsed);

		if (curOption != null) {
			camFollow.setPosition(curOption.getMidpoint().x, curOption.getMidpoint().y);
		}

		if (!inputWait && !disableInput) {
			if (controls.UI_UP_P || FlxG.mouse.wheel == 1)
				changeSelection(-1);
			else if (controls.UI_DOWN_P || FlxG.mouse.wheel == -1)
				changeSelection(1);

			if (FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0 || FlxG.mouse.justPressed) {
                curSelected = -1;
                var i = 0;
                 for (item in items) {
                    if (FlxG.mouse.overlaps(item, camera)) {
                        curSelected = i;
                        break;
                    }
                    i++;
                }
                updateOptions();
            }

			if ((controls.ACCEPT || FlxG.mouse.justPressed) && curOption != null) {
				if (curOption.isInput)
                	inputWait = true;
				else
					switch (curOption.id) {
						case "skin":
							LoadingState.loadAndSwitchState(new SkinsState());
						case "setup mods":
							MusicBeatState.switchState(new SetupMods(Mods.getModDirectories()));
						case "unlink google":
							GoogleAPI.revokeAccess(() -> {
								Alert.alert("Unlinked from Google!", "");
							});
							MusicBeatState.switchState(new OptionsState());
						case "clear trusted domains":
							Wrapper.prefTrustedSources = ["https://gamebanana.com/"];
							ClientPrefs.saveSettings();
							Alert.alert("Cleared the trusted domains list!", "");
					}
			}
            
            if (controls.BACK) {
				FlxG.sound.music.volume = 1;
				MusicBeatState.switchState(new OnlineState());
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}
        }
    }

    var curOption:InputOption;
    function changeSelection(diffe:Int) {
		curSelected += diffe;

		if (curSelected >= items.length) {
			curSelected = 0;
		}
		else if (curSelected < 0) {
			curSelected = items.length - 1;
		}

        updateOptions();
    }

    function updateOptions() {
        if (curSelected < 0 || curSelected >= items.length)
            curOption = null;
        else
            curOption = items.members[curSelected];

        for (item in items) {
			item.alpha = inputWait ? 0.5 : 0.6;
			if (item.isInput)
				item.input.alpha = 0.5;
        }
        if (curOption != null) {
			curOption.alpha = 1;
			if (curOption.isInput)
				curOption.input.alpha = inputWait ? 1 : 0.7;
		}
    }

    var inputWait(default, set):Bool = false;
	function set_inputWait(value:Bool) {
		inputWait = value;
		if (!inputWait) {
			tempDisableInput();
		}
		else {
			inputWait = curOption?.input != null;
		}
		updateOptions();
		return inputWait;
	}
	
	function onKeyDown(e:KeyboardEvent) {
		if (!inputWait || disableInput) {
			return;
		}

		var key = e.keyCode;

		if (e.charCode == 0) { // non-printable characters crash String.fromCharCode
			return;
		}

		if (key == 46) { // delete
			return;
		}

		if (key == 8) { // bckspc
			curOption.input.text = curOption.input.text.substring(0, curOption.input.text.length - 1);
			return;
		}
		else if (key == 13) { // enter
			inputWait = false;
			switch (curOption.id) {
				case "nickname":
					if (curOption.input.text == "")
						Wrapper.prefNickname = "Boyfriend";
					Wrapper.prefNickname = curOption.input.text;
				case "server address":
					GameClient.serverAddress = curOption.input.text;
			}
			ClientPrefs.saveSettings();
			return;
		}
		else if (key == 27) { // esc
			inputWait = false;
			return;
		}

		var newText:String = String.fromCharCode(e.charCode);
		if (e.shiftKey) {
			newText = newText.toUpperCase();
		}
		else {
			newText = newText.toLowerCase();
		}

		if (key == 86 && e.ctrlKey) {
			newText = Clipboard.text;
		}

		if (newText.length > 0) {
			curOption.input.text += newText;
		}
	}

	var disableInput = false;
	function tempDisableInput() {
		disableInput = true;
		new FlxTimer().start(0.1, (t) -> disableInput = false);
	}
}

class InputOption extends FlxSpriteGroup {
	var box:FlxSprite;
	var text:FlxText;
	var descText:FlxText;
	var inputBg:FlxSprite;
	var inputPlaceholder:FlxText;
	public var input:FlxText;

	public var id:String;
	public var isInput:Bool;

    public function new(title:String, description:String, ?placeholder:String = "...", ?isInput:Bool = true) {
        super();

		id = title.toLowerCase();
		this.isInput = isInput;

		box = new FlxSprite();
		box.setPosition(-5, -10);
		add(box);

		text = new FlxText(0, 0, 0, title);
		text.setFormat("VCR OSD Mono", 22, FlxColor.WHITE);
		text.x = 10;
		add(text);

		descText = new FlxText(0, 0, box.width - 30, description);
		descText.setFormat("VCR OSD Mono", 18, FlxColor.WHITE);
		descText.x = text.x;
		descText.y = text.height + 5;
		add(descText);

		if (isInput) {
			inputBg = new FlxSprite();
			inputBg.makeGraphic(700, 50, FlxColor.BLACK);
			inputBg.x = text.x;
			inputBg.y = descText.y + descText.textField.textHeight + 10;
			inputBg.alpha = 0.6;
			add(inputBg);

			inputPlaceholder = new FlxText();
			inputPlaceholder.text = placeholder;
			inputPlaceholder.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			inputPlaceholder.alpha = 0.5;
			inputPlaceholder.x = inputBg.x + 20;
			inputPlaceholder.y = inputBg.y + inputBg.height / 2 - inputPlaceholder.height / 2;
			add(inputPlaceholder);

			input = new FlxText();
			input.text = "";
			input.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			input.setPosition(inputPlaceholder.x, inputPlaceholder.y);
			add(input);
		}

		var width = Std.int(width) + 10;
		if (width < 700) {
			width = 700;
		}

		box.makeGraphic(Std.int(width) + 10, Std.int(height) + 20, 0x81000000);
		box.visible = true;
    }

	var targetScale:Float = 1;
	override function update(elapsed) {
		super.update(elapsed);

		if (isInput)
			inputPlaceholder.visible = input.text == "";

		targetScale = alpha == 1 ? 1.02 : 1;
		scale.set(FlxMath.lerp(scale.x, targetScale, elapsed * 10), FlxMath.lerp(scale.y, targetScale, elapsed * 10));
	}
}