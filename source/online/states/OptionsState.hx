package online.states;

import online.net.Auth;
import lime.ui.FileDialog;
import flixel.util.FlxSpriteUtil;
import online.net.FunkinNetwork;
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

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Menus", "Online Options");
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xff2b2b2b;
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.scrollFactor.set(0, 0);
		add(bg);

		var i = 0;

		var nicknameOption:InputOption;
		items.add(nicknameOption = new InputOption("Nickname", "Set your nickname here!", ["Boyfriend"], (text, _) -> {
			curOption.inputs[0].text = curOption.inputs[0].text.trim().substr(0, 14);
			ClientPrefs.setNickname(curOption.inputs[0].text);
			ClientPrefs.saveSettings();
		}));
		nicknameOption.inputs[0].text = ClientPrefs.getNickname();
		nicknameOption.y = 50;
		nicknameOption.screenCenter(X);
		nicknameOption.ID = i++;

        var serverOption:InputOption;
		var appendText = "";
		if (GameClient.serverAddresses.length > 0) {
			appendText += "\nOfficial Servers:";
			for (address in GameClient.serverAddresses) {
				if (address != "ws://localhost:2567")
					appendText += "\n" + address;
			}
		}
		items.add(serverOption = new InputOption("Server Address", "Set to empty if you want to use the default server\nLocal Address: 'localhost'" + appendText, [GameClient.serverAddresses[0]], (text, _) -> {
			curOption.inputs[0].text = curOption.inputs[0].text.trim();

			if (curOption.inputs[0].text.length > 0 && !(curOption.inputs[0].text.startsWith('wss://') || curOption.inputs[0].text.startsWith('ws://')))
				curOption.inputs[0].text = 'ws://' + curOption.inputs[0].text;

			if (curOption.inputs[0].text == "ws://localhost") {
				curOption.inputs[0].text += ":2567";
			}

			if (curOption.inputs[0].text == "ws://funkin.sniro.boo") {
				curOption.inputs[0].text = "wss://funkin.sniro.boo";
			}

			if (curOption.inputs[0].text == "ws://gettinfreaky.onrender.com") {
				curOption.inputs[0].text = "wss://gettinfreaky.onrender.com";
			}

			GameClient.serverAddress = curOption.inputs[0].text;
			try {
				online.net.FunkinNetwork.ping();
			}
			catch (exc) {
				trace(exc);
			}
		}));
		serverOption.inputs[0].text = GameClient.serverAddress;
		serverOption.y = nicknameOption.y + nicknameOption.height + 50;
		serverOption.screenCenter(X);
		serverOption.ID = i++;

		// var titleOption:InputOption;
		// items.add(titleOption = new InputOption("Title", "This will be shown below your name! (Max 20 characters)", ClientPrefs.data.playerTitle, text -> {
		// 	curOption.input.text = curOption.input.text.trim().substr(0, 20);
		// 	ClientPrefs.data.playerTitle = curOption.input.text;
		// 	ClientPrefs.saveSettings();
		// }));
		// titleOption.input.text = ClientPrefs.data.playerTitle;
		// titleOption.y = serverOption.y + serverOption.height + 50;
		// titleOption.screenCenter(X);
		// titleOption.ID = i++;

		var skinsOption:InputOption;
		items.add(skinsOption = new InputOption("Skin", "Choose your skin here!"));
		skinsOption.y = serverOption.y + serverOption.height + 50;
		skinsOption.screenCenter(X);
		skinsOption.ID = i++;

		var modsOption:InputOption;
		items.add(modsOption = new InputOption("Setup Mods", "Set the URL's of your mods here!"));
		modsOption.y = skinsOption.y + skinsOption.height + 50;
		modsOption.screenCenter(X);
		modsOption.ID = i++;

		var trustedOption:InputOption;
		items.add(trustedOption = new InputOption("Clear Trusted Domains", "Clear the list of all trusted domains!"));
		trustedOption.y = modsOption.y + modsOption.height + 50;
		trustedOption.screenCenter(X);
		trustedOption.ID = i++;

		var sezOption:InputOption;
		items.add(sezOption = new InputOption("Leave a Global Message",
			"Leave a message for others to see in the Online Menu!", ["Message"], (message, _) -> {
				if (FunkinNetwork.postFrontMessage(message))
					FlxG.switchState(() -> new OnlineState());
		}));
		sezOption.y = trustedOption.y + trustedOption.height + 50;
		sezOption.screenCenter(X);
		sezOption.ID = i++;

		if (Auth.authID == null && Auth.authToken == null) {
			// var registerOption:InputOption;
			// items.add(registerOption = new InputOption("Join the Network",
			// "Join the Psych Online Network\nSubmit your song replays to the leaderboard system!", null, false));
			// registerOption.y = trustedOption.y + trustedOption.height + 50;
			// registerOption.screenCenter(X);
			// registerOption.ID = i++;

			var registerOption:InputOption;
			items.add(registerOption = new InputOption("Register to the Network",
				"Join the Psych Online Network and submit your song replays\nto the leaderboards!", ["Username", "Email"], (text, input) -> {
					if (input == 0) {
						registerOption.inputs[0].hasFocus = false;
						registerOption.inputs[1].hasFocus = true;
						inputWait = true;
						return;
					}

					registerOption.inputs[0].text = registerOption.inputs[0].text.trim();
					registerOption.inputs[1].text = registerOption.inputs[1].text.trim();

					if (registerOption.inputs[0].text.length <= 0) {
						Alert.alert('No username set!');
						return;
					}

					if (registerOption.inputs[1].text.length <= 0) {
						registerOption.inputs[0].hasFocus = false;
						registerOption.inputs[1].hasFocus = true;
						inputWait = true;
						return;
					}

					if (FunkinNetwork.requestRegister(registerOption.inputs[0].text, registerOption.inputs[1].text)) {
						openSubState(new VerifyCode(code -> {
							if (FunkinNetwork.requestRegister(registerOption.inputs[0].text, registerOption.inputs[1].text, code)) {
								Alert.alert("Successfully registered!");
								FlxG.resetState();
							}
						}));
					}
				}));
			registerOption.y = sezOption.y + sezOption.height + 50;
			registerOption.screenCenter(X);
			registerOption.ID = i++;

			var loginOption:InputOption;
			items.add(loginOption = new InputOption("Login to the Network",
				"Input your email address here and wait for your One-Time Login Code!", ["me@example.org"], (mail, _) -> {
					if (FunkinNetwork.requestLogin(mail)) {
						openSubState(new VerifyCode(code -> {
							if (FunkinNetwork.requestLogin(mail, code)) {
								Alert.alert("Successfully logged in!");
								FlxG.resetState();
							}
						}));
					}
				}));
			loginOption.y = registerOption.y + registerOption.height + 50;
			loginOption.screenCenter(X);
			loginOption.ID = i++;
		}
		else {
			var loginBrowserOption:InputOption;
			items.add(loginBrowserOption = new InputOption("Login to Browser", "Authenticates you to the network your default web browser"));
			loginBrowserOption.y = sezOption.y + sezOption.height + 50;
			loginBrowserOption.screenCenter(X);
			loginBrowserOption.ID = i++;

			var emailOption:InputOption;
			items.add(emailOption = new InputOption("Set Email Address",
				"Use the following format:\n<new_mail> from <old_mail>", ["me@example.org"], (mail, _) -> {
					if (FunkinNetwork.setEmail(mail)) {
						openSubState(new VerifyCode(code -> {
							if (FunkinNetwork.setEmail(mail, code)) {
								Alert.alert("Email Successfully Added!");
							}
						}));
					}
				}));
			emailOption.y = loginBrowserOption.y + loginBrowserOption.height + 50;
			emailOption.screenCenter(X);
			emailOption.ID = i++;
			
			var deleteOption:InputOption;
			items.add(deleteOption = new InputOption("Delete Network Account", "Bye!"));
			deleteOption.y = emailOption.y + emailOption.height + 50;
			deleteOption.screenCenter(X);
			deleteOption.ID = i++;

			var logoutOption:InputOption;
			items.add(logoutOption = new InputOption("Logout of the Network", "Logout of the Psych Online Network"));
			logoutOption.y = deleteOption.y + deleteOption.height + 50;
			logoutOption.screenCenter(X);
			logoutOption.ID = i++;
		}

		add(items);

        changeSelection(0);
    }

    override function update(elapsed) {
		if (curOption != null) {
			camFollow.setPosition(curOption.getMidpoint().x, curOption.getMidpoint().y);
		}

		if (!inputWait) {
			if (controls.BACK) {
				FlxG.sound.music.volume = 1;
				FlxG.switchState(() -> new OnlineState());
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}

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
        }

		super.update(elapsed);

		if (!inputWait) {
			if ((controls.ACCEPT || FlxG.mouse.justPressed) && curOption != null) {
				if (curOption.isInput) {
					if (FlxG.mouse.justPressed)
						for (i => input in curOption.inputs)
							input.hasFocus = FlxG.mouse.overlaps(curOption.inputBgs[i], camera);
					else
						for (i => input in curOption.inputs)
							input.hasFocus = i == 0;
				}
				else
					switch (curOption.id) {
						case "skin":
							LoadingState.loadAndSwitchState(new SkinsState());
						case "setup mods":
							FlxG.switchState(() -> new SetupMods(Mods.getModDirectories(), true));
						case "clear trusted domains":
							ClientPrefs.data.trustedSources = ["https://gamebanana.com/"];
							ClientPrefs.saveSettings();
							Alert.alert("Cleared the trusted domains list!", "");
						case "delete network account":
							if (FunkinNetwork.deleteAccount()) {
								openSubState(new VerifyCode(code -> {
									if (FunkinNetwork.deleteAccount()) {
										Alert.alert("Account Deleted");
									}
								}));
							}
						case "logout of the network":
							RequestState.request('Are you sure you want to logout?', '', _ -> {
								FunkinNetwork.logout();
								FlxG.resetState();
							}, null, true);
						case "login to browser":
							FlxG.openURL(FunkinNetwork.client.getURL("/api/network/account/cookie?id=" + Auth.authID + "&token=" + Auth.authToken));
					}
			}
		}

		inputWait = false;
		for (item in items) {
			if (item?.inputs == null)
				continue;

			for (input in item.inputs) {
				if (input.hasFocus) {
					curSelected = item.ID;
					inputWait = true;
					return;
				}
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
			item.borderline.visible = item == curOption;
			item.alpha = inputWait ? 0.5 : 0.6;
			if (item.isInput)
				for (input in item.inputs)
					input.alpha = 0.5;
        }
        if (curOption != null) {
			curOption.alpha = 1;
			if (curOption.isInput)
				for (input in curOption.inputs)
					input.alpha = inputWait ? 1 : 0.7;
		}
    }

    var inputWait(default, set):Bool = false;
	function set_inputWait(value:Bool) {
		if (inputWait == value) return inputWait;
		inputWait = value;
		updateOptions();
		return inputWait;
	}
}

class InputOption extends FlxSpriteGroup {
	var box:FlxSprite;
	public var borderline:FlxSprite;
	public var text:FlxText;
	public var descText:FlxText;

	public var inputBgs:Array<FlxSprite> = [];
	var inputPhs:Array<FlxText> = [];
	public var inputs:Array<InputText> = [];

	public var id:String;
	public var isInput:Bool;

    public function new(title:String, description:String, ?inputList:Array<String>, ?onEnter:(text:String, input:Int)->Void) {
        super();

		id = title.toLowerCase();
		this.isInput = inputList != null;

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
			for (i => placeholder in inputList) {
				var inputBg = new FlxSprite();
				inputBg.makeGraphic(700, 50, FlxColor.BLACK);
				inputBg.x = text.x;
				inputBg.y = descText.y + descText.textField.textHeight + 10;
				inputBg.alpha = 0.6;
				add(inputBg);

				var inputPlaceholder = new FlxText();
				inputPlaceholder.text = placeholder;
				inputPlaceholder.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				inputPlaceholder.alpha = 0.5;
				inputPlaceholder.x = inputBg.x + 20;
				inputPlaceholder.y = inputBg.y + inputBg.height / 2 - inputPlaceholder.height / 2;
				add(inputPlaceholder);

				var input = new InputText(0, 0, inputBg.width - 20, (text) -> onEnter(text, i));
				input.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				input.setPosition(inputPlaceholder.x, inputPlaceholder.y);
				add(input);

				inputBg.y += i * 50;
				inputPlaceholder.y += i * 50;
				input.y += i * 50;

				inputBgs.push(inputBg);
				inputPhs.push(inputPlaceholder);
				inputs.push(input);
			}
		}

		var width = Std.int(width) + 10;
		if (width < 700) {
			width = 700;
		}

		box.makeGraphic(Std.int(width) + 10, Std.int(height) + 20, 0x81000000);

		borderline = new FlxSprite(box.x, box.y);
		borderline.makeGraphic(Std.int(box.width), Std.int(box.height), FlxColor.TRANSPARENT);
		FlxSpriteUtil.drawRect(borderline, 0, 0, borderline.width, borderline.height, FlxColor.TRANSPARENT, {thickness: 6, color: 0x34FFFFFF});
		borderline.visible = false;
		add(borderline);
    }

	//var targetScale:Float = 1;
	override function update(elapsed) {
		super.update(elapsed);

		if (isInput)
			for (i => input in inputs)
				inputPhs[i].visible = input.text == "";

		//targetScale = alpha == 1 ? 1.02 : 1;
		//scale.set(FlxMath.lerp(scale.x, targetScale, elapsed * 10), FlxMath.lerp(scale.y, targetScale, elapsed * 10));
	}
}