package online.states;

import openfl.filters.BlurFilter;
import substates.GameplayChangersSubstate;
import options.OptionsState;
import flixel.util.FlxSpriteUtil;

class ServerSettingsSubstate extends MusicBeatSubstate {
    var bg:FlxSprite;
	var prevMouseVisibility:Bool = false;
	var items:FlxTypedSpriteGroup<Option>;
	var curSelectedID:Int = 0;

	var blurFilter:BlurFilter;
	var coolCam:FlxCamera;

    //options
	var skinSelect:Option;
	var gameOptions:Option;
	var publicRoom:Option;
	var anarchyMode:Option;
	var swapSides:Option;

	override function create() {
		super.create();

		blurFilter = new BlurFilter();
		for (cam in FlxG.cameras.list) {
			if (cam.filters == null)
				cam.filters = [];
			cam.filters.push(blurFilter);
		}

		coolCam = new FlxCamera();
		coolCam.bgColor.alpha = 0;
		FlxG.cameras.add(coolCam, false);

		cameras = [coolCam];

		prevMouseVisibility = FlxG.mouse.visible;

		FlxG.mouse.visible = true;

		bg = new FlxSprite();
		bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.7;
		add(bg);

		items = new FlxTypedSpriteGroup<Option>(40, 40);

		var i = 0;

		items.add(publicRoom = new Option("Public Room", "If enabled, this room is publicly listed in the FIND tab.", () -> {
			if (GameClient.hasPerms()) {
				GameClient.send("togglePrivate");
			}
		}, (elapsed) -> {
			publicRoom.alpha = GameClient.hasPerms() ? 1 : 0.8;

			publicRoom.checked = !GameClient.room.state.isPrivate;
		}, 0, 80 * i, !GameClient.room.state.isPrivate));
		publicRoom.ID = i++;

		items.add(anarchyMode = new Option("Anarchy Mode", "This option gives Player 2 host permissions.", () -> {
			if (GameClient.hasPerms()) {
				GameClient.send("anarchyMode");
			}
		}, (elapsed) -> {
			anarchyMode.alpha = GameClient.hasPerms() ? 1 : 0.8;

			anarchyMode.checked = GameClient.room.state.anarchyMode;
		}, 0, 80 * i, GameClient.room.state.anarchyMode));
		anarchyMode.ID = i++;

		items.add(swapSides = new Option("Swap Sides", "Swaps Player 1's strums with Player 2.", () -> {
			if (GameClient.hasPerms()) {
				GameClient.send("swapSides");
			}
		}, (elapsed) -> {
			swapSides.alpha = GameClient.hasPerms() ? 1 : 0.8;

			swapSides.checked = GameClient.room.state.swagSides;
		}, 0, 80 * i, GameClient.room.state.swagSides));
		swapSides.ID = i++;

		var unlockModifiers:Option;
		items.add(unlockModifiers = new Option("Unlock Gameplay Modifiers", "This will use player's local gameplay settings instead of room ones.", () -> {
			if (GameClient.hasPerms()) {
				GameClient.send("toggleLocalModifiers", GameClient.room.state.permitModifiers ? ClientPrefs.data.gameplaySettings : null);
			}
		}, (elapsed) -> {
			unlockModifiers.alpha = GameClient.hasPerms() ? 1 : 0.8;

			unlockModifiers.checked = GameClient.room.state.permitModifiers;
		}, 0, 80 * i, GameClient.room.state.permitModifiers));
		unlockModifiers.ID = i++;

		var modifers:Option;
		items.add(modifers = new Option("Game Modifiers", "Select room's gameplay modifiers here!", () -> {
			close();
			FlxG.state.openSubState(new GameplayChangersSubstate());
		}, null, 0, 80 * i, false, true));
		modifers.ID = i++;

		items.add(skinSelect = new Option("Select Skin", "Select your skin here!", () -> {
			GameClient.clearOnMessage();
			LoadingState.loadAndSwitchState(new SkinsState());
		}, null, 0, 80 * i, false, true));
		skinSelect.ID = i++;

		items.add(gameOptions = new Option("Game Options", "Open your game options here!", () -> {
			GameClient.clearOnMessage();
			LoadingState.loadAndSwitchState(new OptionsState());
			OptionsState.onPlayState = false;
			OptionsState.onOnlineRoom = true;
		}, null, 0, 80 * i, false, true));
		gameOptions.ID = i++;

		add(items);

		GameClient.send("status", "In the Room Settings");
	}

	override function closeSubState() {
		super.closeSubState();

		GameClient.send("status", "In the Room Settings");
	}

	override function destroy() {
		super.destroy();

		for (cam in FlxG.cameras.list) {
			if (cam?.filters != null)
				cam.filters.remove(blurFilter);
		}
		FlxG.cameras.remove(coolCam);
	}

    override function update(elapsed) {
        if (controls.BACK) {
            close();
			FlxG.mouse.visible = prevMouseVisibility;
        }

		if (!GameClient.isConnected()) {
			return;
		}

		super.update(elapsed);

		if (controls.UI_UP_P)
			curSelectedID--;
		else if (controls.UI_DOWN_P)
			curSelectedID++;

		if (curSelectedID >= items.length) {
			curSelectedID = 0;
		}
		else if (curSelectedID < 0) {
			curSelectedID = items.length - 1;
		}

        items.forEach((option) -> {
			if (GameClient.room == null)
				return;
			
			if (FlxG.mouse.justMoved && FlxG.mouse.overlaps(option, camera)) {
				curSelectedID = option.ID;
            }

			if (FlxG.mouse.overlaps(option, camera) && FlxG.mouse.justPressed) {
				option.onClick();
			}

			if (option.ID == curSelectedID) {
				option.text.alpha = 1;

                if (controls.ACCEPT) {
                    option.onClick();
                }
            }
            else {
				option.text.alpha = 0.7;
            }
        });
    }
}

class Option extends FlxSpriteGroup {
	public var box:FlxSprite;
	public var checkbox:FlxSprite;
	var check:FlxSprite;
	public var text:FlxText;
	public var descText:FlxText;
	public var onClick:Void->Void;
	var onUpdate:Float->Void;
	
	public var checked(default, set):Bool;
	function set_checked(value:Bool):Bool {
		if (value == checked)
			return value;

		if (value && check != null) {
			check.angle = 0;
			check.alpha = 1;
			check.scale.set(1.2, 1.2);
		}
		return checked = value;
	}

	var noCheckbox:Bool = false;

	public function new(title:String, description:String, onClick:Void->Void, onUpdate:Float->Void, x:Int, y:Int, isChecked:Bool, ?noCheckbox:Bool = false) {
        super(x, y);

		this.onClick = onClick;
		this.onUpdate = onUpdate;
		this.noCheckbox = noCheckbox;

		box = new FlxSprite();
        box.setPosition(-5, -5);
        add(box);

		if (!noCheckbox) {
			checkbox = new FlxSprite();
			checkbox.makeGraphic(50, 50, 0x50000000);
			FlxSpriteUtil.drawRect(checkbox, 0, 0, checkbox.width, checkbox.height, FlxColor.TRANSPARENT, {thickness: 5, color: FlxColor.WHITE});
			checkbox.updateHitbox();
			add(checkbox);

			check = new FlxSprite();
			check.loadGraphic(Paths.image('check'));
			check.alpha = isChecked ? 1 : 0;
			add(check);

			checked = isChecked;
			if (checked) {
				check.scale.set(1, 1);
			}
			else {
				check.alpha = 0;
				check.scale.set(0.01, 0.01);
			}
		}

		text = new FlxText(0, 0, 0, title);
		text.setFormat("VCR OSD Mono", 22, FlxColor.WHITE);
		text.x = checkbox != null ? checkbox.width + 10 : 10;
        //text.y = checkbox.height / 2 - text.height / 2;
        add(text);

		descText = new FlxText(0, 0, 0, description);
		descText.setFormat("VCR OSD Mono", 18, FlxColor.WHITE);
		descText.x = text.x;
		descText.y = text.height + 2;
		add(descText);

		box.makeGraphic(Std.int(width) + 10, Std.int(height) + 10, 0x81000000);
    }

    override function update(elapsed) {
        super.update(elapsed);

		if (!noCheckbox) {
			if (checked) {
				if (check.scale.x != 1 || check.scale.y != 1)
					check.scale.set(FlxMath.lerp(check.scale.x, 1, elapsed * 10), FlxMath.lerp(check.scale.y, 1, elapsed * 10));
			}
			else {
				if (check.alpha != 0) {
					check.alpha = FlxMath.lerp(check.alpha, 0, elapsed * 15);
					check.angle += elapsed * 800;
				}
				if (check.scale.x != 0.01 || check.scale.y != 0.01)
					check.scale.set(FlxMath.lerp(check.scale.x, 0.01, elapsed * 15), FlxMath.lerp(check.scale.y, 0.01, elapsed * 15));
			}
		}

		if (onUpdate != null)
			onUpdate(elapsed);

		descText.alpha = text.alpha;
		if (!noCheckbox)
			checkbox.alpha = text.alpha;
    }
}