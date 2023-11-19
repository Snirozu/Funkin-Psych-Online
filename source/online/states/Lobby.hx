package online.states;

import haxe.Json;
import states.MainMenuState;
import openfl.events.KeyboardEvent;
import flixel.addons.text.FlxTextField;

class Lobby extends MusicBeatState {
	var items:FlxTypedSpriteGroup<FlxText>;

	var itms:Array<String> = [
        "JOIN",
        "HOST",
        "FIND",
		"NAME",
		"DISCORD"
    ];

	var itemDesc:FlxText;

	var curSelected = 0;

	var inputWait = false;
	var inputString(get, set):String;
	function get_inputString():String {
		switch (curSelected) {
			case 0:
				return daCoomCode;
			case 3:
				return daName;
		}
		return null;
	}
	function set_inputString(v) {
		switch (curSelected) {
			case 0:
				return daCoomCode = v;
			case 3:
				return daName = v;
		}
		return null;
	}

	var daCoomCode:String = "";
	var daName:String;

	var disableInput = false;

    function onRoomJoin() {
		Waiter.put(() -> {
			MusicBeatState.switchState(new Room());
		});
    }

	function getItemName(item:String) {
		if (curSelected == 0 && item == "JOIN" && inputWait)
		{
			return "JOIN CODE: " + inputString;
		}
		if (curSelected == 3 && item.toLowerCase().startsWith("name") && inputWait) {
			return "NAME: " + inputString;
		}
		return item;
	}

    override function create() {
        super.create();

		daName = ClientPrefs.data.nickname;

        var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
        bg.color = 0xff6f2d83;
        bg.updateHitbox();
        bg.screenCenter();
        bg.antialiasing = ClientPrefs.data.antialiasing;
        add(bg);

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
			items.add(prevText = text);
			i++;
        }
		items.screenCenter(Y);
        add(items);

		itemDesc = new FlxText(0, FlxG.height - 150);
		itemDesc.setFormat("VCR OSD Mono", 25, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		itemDesc.screenCenter(X);
		add(itemDesc);

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
    }

	override function destroy() {
		super.destroy();

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
	}

    override function update(elapsed) {
        super.update(elapsed);

		for (item in items) {
			item.text = getItemName(itms[item.ID]);
            item.alpha = 0.8;
            if (item.ID == curSelected) {
				item.text = "> " + item.text + " <";
				item.alpha = 1;
            }
            item.screenCenter(X);
        }

        if (disableInput) return;

		if (controls.UI_UP_P && !inputWait)
			curSelected--;
		else if (controls.UI_DOWN_P && !inputWait)
			curSelected++;

        if (curSelected >= items.length) {
			curSelected = 0;
        }
		else if (curSelected < 0) {
			curSelected = items.length - 1;
        }

		switch (curSelected) {
			case 0:
				itemDesc.text = "Join a room using room code";
			case 1:
				itemDesc.text = "Creates a room";
			case 2:
				itemDesc.text = "Opens a list of all available public rooms";
			case 3:
				itemDesc.text = "Set your nickname here!";
			case 4:
				itemDesc.text = "Also join the Discord server of this mod!";
		}
		itemDesc.screenCenter(X);

		if (controls.ACCEPT && !inputWait) {
			switch (itms[curSelected].toLowerCase()) {
				case "join":
					inputWait = true;
                case "find":
                    //FlxG.openURL(GameClient.serverAddress + "/rooms");
					FlxG.switchState(new FindRoom());
				case "host":
					GameClient.createRoom(onRoomJoin);
				case "discord":
					FlxG.openURL("https://discord.gg/juHypjWuNc");
			}
			if (curSelected == 3) {
				inputWait = true;
			}
		}

		if (controls.BACK && !inputWait) {
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);

			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
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
			inputWait = false;

            if (inputString.length >= 0) {
				switch (itms[curSelected].toLowerCase()) {
					case "join":
						GameClient.joinRoom(daCoomCode, onRoomJoin);
				}
				if (curSelected == 3) {
					ClientPrefs.data.nickname = daName;
					ClientPrefs.saveSettings();
				}
            }

			tempDisableInput();
            return;
        }
		else if (key == 27) { //esc
			inputWait = false;
			tempDisableInput();
			if (curSelected == 3) {
				ClientPrefs.data.nickname = daName;
				ClientPrefs.saveSettings();
			}
            return;
        }

		var newText:String = String.fromCharCode(e.charCode);
		if ((curSelected == 0 && !e.shiftKey) || (curSelected != 0 && e.shiftKey)) {
			newText = newText.toUpperCase();
        }
        else {
			newText = newText.toLowerCase();
        }

		if (newText.length > 0) {
			inputString += newText;
		}
    }

    function tempDisableInput() {
		disableInput = true;
        new FlxTimer().start(0.1, (t) -> disableInput = false);
    }
}