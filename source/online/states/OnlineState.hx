package online.states;

import states.FreeplayState;
import lime.system.Clipboard;
import haxe.Json;
import states.MainMenuState;
import openfl.events.KeyboardEvent;
import flixel.addons.text.FlxTextField;

class OnlineState extends MusicBeatState {
	var items:FlxTypedSpriteGroup<FlxText>;

	var itms:Array<String> = [
        "JOIN",
        "HOST",
        "FIND",
		"OPTIONS",
		"MOD DOWNLOADER",
		"DISCORD",
		"WIKI",
    ];

	var itemDesc:FlxText;
	var playersOnline:FlxText;

	static var curSelected = 0;

	var inputWait = false;
	var inputString(get, set):String;
	function get_inputString():String {
		switch (curSelected) {
			case 0:
				return daCoomCode;
		}
		return null;
	}
	function set_inputString(v) {
		switch (curSelected) {
			case 0:
				return daCoomCode = v;
		}
		return null;
	}

	var daCoomCode:String = "";
	var disableInput = false;

	var selectLine:FlxSprite;
	var descBox:FlxSprite;

    function onRoomJoin(err:Dynamic) {
		if (err != null) {
			disableInput = false;
			return;
		}

		Waiter.put(() -> {
			FlxG.switchState(() -> new Room());
		});
    }

	function getItemName(item:String) {
		if (curSelected == 0 && item == "JOIN" && inputWait)
		{
			return "JOIN CODE: " + inputString;
		}
		return item;
	}

    override function create() {
        super.create();

		if(FreeplayState.vocals != null) FreeplayState.vocals.destroy();
		if (FlxG.sound.music == null || !FlxG.sound.music.playing)
			FlxG.sound.playMusic(Paths.music('freakyMenu'));

		OnlineMods.checkMods();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Online Menu.", null, null, false);
		#end

        var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
        bg.color = 0xff3f2b5a;
        bg.updateHitbox();
        bg.screenCenter();
        bg.antialiasing = ClientPrefs.data.antialiasing;
        add(bg);

		var lines:FlxSprite = new FlxSprite().loadGraphic(Paths.image('coolLines'));
		lines.updateHitbox();
		lines.screenCenter();
		lines.antialiasing = ClientPrefs.data.antialiasing;
		add(lines);

		selectLine = new FlxSprite();
		selectLine.makeGraphic(1, 1, FlxColor.BLACK);
		selectLine.alpha = 0.3;
		add(selectLine);

		descBox = new FlxSprite(0, FlxG.height - 125);
		descBox.makeGraphic(1, 1, FlxColor.BLACK);
		descBox.alpha = 0.4;
		add(descBox);

        items = new FlxTypedSpriteGroup<FlxText>();
		var prevText:FlxText = null;
        var i = 0;
        for (itm in itms) {
			var text = new FlxText(0, 0, 0, getItemName(itm));
			if (prevText != null) {
				text.y += prevText.height * i;
			}
            text.ID = i;
			text.setFormat("VCR OSD Mono", 40, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			text.alpha = inputWait ? 0.5 : 0.8;
			if (text.ID == curSelected) {
				text.text = "> " + text.text + " <";
				text.alpha = 1;
			}
			items.add(prevText = text);
			i++;
        }
		items.screenCenter(Y);
        add(items);

		itemDesc = new FlxText(0, FlxG.height - 125);
		itemDesc.setFormat("VCR OSD Mono", 25, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		itemDesc.screenCenter(X);
		add(itemDesc);

		playersOnline = new FlxText(0, 100);
		playersOnline.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		playersOnline.alpha = 0.7;
		add(playersOnline);
		
		changeSelection(0);

		GameClient.getServerPlayerCount((v) -> {
			if (v == null) {
				playersOnline.text = "OFFLINE";
				//thought this would look cool
				//playersOnline.applyMarkup("$•$ OFFLINE $•$", [new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.GRAY), "$")]);
			}
			else {
				playersOnline.text = 'Players Online: $v';
				//playersOnline.applyMarkup("$•$ Players Online: " + v + " $•$", [new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.GREEN), "$")]);
			}
			
			playersOnline.screenCenter(X);
		});

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);

		FlxG.mouse.visible = true;
    }

	override function destroy() {
		super.destroy();

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
	}

    override function update(elapsed) {
        super.update(elapsed);

        if (disableInput) return;

		for (item in items) {
			item.text = getItemName(itms[item.ID]);
			item.alpha = inputWait ? 0.5 : 0.8;
			if (item.ID == curSelected) {
				item.text = "> " + item.text + " <";
				item.alpha = 1;
			}
			item.screenCenter(X);
		}

		var mouseInItems = FlxG.mouse.y > items.y && FlxG.mouse.y < items.y + items.members.length * 40;

		if (FlxG.mouse.justPressed && inputWait) {
			if (!FlxG.mouse.overlaps(items.members[curSelected])) {
				inputWait = false;
				return;
			}
			enterInput();
			return;
		}

		if (FlxG.mouse.justPressedRight && inputWait && Clipboard.text != null) {
			inputString += Clipboard.text;
		}

		if (FlxG.mouse.justMoved && !inputWait && mouseInItems) {
			curSelected = Std.int((FlxG.mouse.y - (items.y)) / 40);
			changeSelection(0);
		}

		if (!inputWait) {
			if (controls.UI_UP_P)
				changeSelection(-1);
			else if (controls.UI_DOWN_P)
				changeSelection(1);

			if (controls.ACCEPT || (FlxG.mouse.justPressed && mouseInItems)) {
				switch (itms[curSelected].toLowerCase()) {
					case "join":
						inputWait = true;
					case "find":
						disableInput = true;
						// FlxG.openURL(GameClient.serverAddress + "/rooms");
						FlxG.switchState(() -> new FindRoom());
					case "host":
						disableInput = true;
						GameClient.createRoom(GameClient.serverAddress, onRoomJoin);
					case "options":
						disableInput = true;
						FlxG.switchState(() -> new OptionsState());
					case "mod downloader":
						disableInput = true;
						FlxG.switchState(() -> new BananaDownload());
					case "discord":
						RequestState.requestURL("https://discord.gg/juHypjWuNc", true);
					case "wiki":
						RequestState.requestURL("https://github.com/Snirozu/Funkin-Psych-Online/wiki", true);
				}
			}

			if (controls.BACK) {
				disableInput = true;

				FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
				FlxG.mouse.visible = false;

				FlxG.sound.play(Paths.sound('cancelMenu'));
				FlxG.switchState(() -> new MainMenuState());
			}
			
			if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.V) {
				disableInput = true;
				GameClient.joinRoom(Clipboard.text, onRoomJoin);
			}
		}
    }
	
	function changeSelection(diffe:Int) {
		curSelected += diffe;

		if (curSelected >= items.length) {
			curSelected = 0;
		}
		else if (curSelected < 0) {
			curSelected = items.length - 1;
		}

		switch (curSelected) {
			case 0:
				itemDesc.text = "Join a room using a room code";
			case 1:
				itemDesc.text = "Creates a room";
			case 2:
				itemDesc.text = "Opens a list of all available public rooms";
			case 3:
				itemDesc.text = "Psych Online options, configure stuff here!";
			case 4:
				itemDesc.text = "Download mods from Gamebanana here!";
			case 5:
				itemDesc.text = "Also join the Discord server of this mod!";
			case 6:
				itemDesc.text = "Documentation, Tips, FAQ etc.";
		}
		itemDesc.screenCenter(X);

		descBox.scale.set(FlxG.width - 100, (itemDesc.text.split("\n").length + 2) * (itemDesc.size));
		descBox.y = (FlxG.height - 125) + descBox.scale.y * 0.5 - itemDesc.size;
		descBox.screenCenter(X);
		
		selectLine.y = (items.y + 20) + (curSelected) * 40;
		selectLine.scale.set(FlxG.width, 40);
		selectLine.screenCenter(X);

		for (item in items) {
			item.text = getItemName(itms[item.ID]);
			item.alpha = inputWait ? 0.5 : 0.8;
			if (item.ID == curSelected) {
				item.text = "> " + item.text + " <";
				item.alpha = 1;
			}
			item.screenCenter(X);
		}
	}

    // some code from FlxInputText
	function onKeyDown(e:KeyboardEvent) {
		if (!inputWait) return;

		var key = e.keyCode;

		if (e.charCode == 0) { // non-printable characters crash String.fromCharCode
			return;
		}

		if (key == 46) { //delete
            return;
        }

		if (key == 8) { //bckspc
			inputString = inputString.substring(0, inputString.length - 1);
            return;
        }
		else if (key == 13) { //enter
			enterInput();
            return;
        }
		else if (key == 27) { //esc
			inputWait = false;
			tempDisableInput();
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
			inputString += newText;
		}
    }

	function enterInput() {
		inputWait = false;

		if (inputString.length >= 0) {
			switch (itms[curSelected].toLowerCase()) {
				case "join":
					disableInput = true;
					GameClient.joinRoom(daCoomCode, onRoomJoin);
			}
		}

		tempDisableInput();
	}

    function tempDisableInput() {
		disableInput = true;
        new FlxTimer().start(0.1, (t) -> disableInput = false);
    }
}