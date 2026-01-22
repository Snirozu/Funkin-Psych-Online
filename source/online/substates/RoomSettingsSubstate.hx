package online.substates;

import openfl.filters.BlurFilter;
import substates.GameplayChangersSubstate;
import options.OptionsState;
import flixel.util.FlxSpriteUtil;
import states.ModsMenuState;

class RoomSettingsSubstate extends MusicBeatSubstate {
    var bg:FlxSprite;
	var prevMouseVisibility:Bool = false;
	var items:FlxTypedSpriteGroup<Option>;
	var curSelectedID:Int = 0;

	var blurFilter:BlurFilter;
	var coolCam:FlxCamera;

    //options
	var hideGF:Option;
	var disableSkins:Option;
	var winCondition:Option;
	var modifers:Option;
	var mods:Option;
	var skinSelect:Option;
	var gameOptions:Option;
	var stageSelect:Option;
	var publicRoom:Option;
	var anarchyMode:Option;
	var swapSides:Option;
	var teamMode:Option;
	var royalMode:Option;
	var royalModeBfSide:Option;

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
		bg.scrollFactor.set(0, 0);
		add(bg);

		items = new FlxTypedSpriteGroup<Option>(40, 40);

		items.add(publicRoom = new Option("Public Room", "If enabled, this room will be publicly listed in the FIND tab.", () -> {
			GameClient.send("togglePrivate");
		}, (elapsed) -> {
			publicRoom.alpha = GameClient.hasPerms() ? 1 : 0.8;

			publicRoom.checked = !GameClient.room.state.isPrivate;
		}, 0, 0, !GameClient.room.state.isPrivate));

		items.add(anarchyMode = new Option("Anarchy Mode", "This option gives other players host permissions.", () -> {
			GameClient.send("anarchyMode");
		}, (elapsed) -> {
			anarchyMode.alpha = GameClient.hasPerms() ? 1 : 0.8;

			anarchyMode.checked = GameClient.room.state.anarchyMode;
		}, 0, 0, GameClient.room.state.anarchyMode));

		items.add(swapSides = new Option("Boyfriend Side", "Play on Boyfriend's side.", () -> {
			GameClient.send("swapSides");
		}, (elapsed) -> {
			swapSides.alpha = GameClient.hasPerms() ? 1 : 0.8;

			swapSides.checked = GameClient.getPlayerSelf().bfSide;
		}, 0, 0, GameClient.getPlayerSelf().bfSide));

		items.add(teamMode = new Option("Team Mode", "Compete in Teams rather than individually! Your performance will be averaged with your teammate.", () -> {
			GameClient.send("teamMode");
		}, (elapsed) -> {
			teamMode.alpha = GameClient.hasPerms() ? 1 : 0.8;

			teamMode.checked = GameClient.room.state.teamMode;
		}, 0, 0, GameClient.room.state.teamMode));

		items.add(royalMode = new Option("Royal Mode", "Everybody plays on the same side!", () -> {
			GameClient.send("royalMode");
		}, (elapsed) -> {
			royalMode.alpha = GameClient.hasPerms() ? 1 : 0.8;

			royalMode.checked = GameClient.room.state.royalMode;

			updateItems();
		}, 0, 0, GameClient.room.state.royalMode));
		
		items.add(royalModeBfSide = new Option("Royal Mode Opponent Side", "Everybody plays on opponent side when enabled.", () -> {
			GameClient.send("royalModeBfSide");
		}, (elapsed) -> {
			royalModeBfSide.alpha = GameClient.hasPerms() ? 1 : 0.8;

			royalModeBfSide.checked = !GameClient.room.state.royalModeBfSide;
		}, 0, 0, !GameClient.room.state.royalModeBfSide));
		
		items.add(hideGF = new Option("Hide Girlfriend", "Hides GF from the stage.", () -> {
			GameClient.send("toggleGF");
		}, (elapsed) -> {
			hideGF.alpha = GameClient.hasPerms() ? 1 : 0.8;

			hideGF.checked = GameClient.room.state.hideGF;
		}, 0, 0, GameClient.room.state.hideGF));

		items.add(disableSkins = new Option("Disable Skins", "Forbids players from using skins.", () -> {
			GameClient.send("toggleSkins");
		}, (elapsed) -> {
			disableSkins.alpha = GameClient.hasPerms() ? 1 : 0.8;

			disableSkins.checked = GameClient.room.state.disableSkins;
		}, 0, 0, GameClient.room.state.disableSkins));

		var prevCond:Int = -1;
		items.add(winCondition = new Option("Win Condition", "...", () -> {
			GameClient.send("nextWinCondition");
		}, (elapsed) -> {
			if (GameClient.room.state.winCondition != prevCond) {
				switch (GameClient.room.state.winCondition) {
					case 0:
						winCondition.descText.text = 'Side with the highest Accuracy wins!';
					case 1:
						winCondition.descText.text = 'Side with the highest Score wins!';
					case 2:
						winCondition.descText.text = 'Side with the least Misses wins!';
					case 3:
						winCondition.descText.text = 'Side with the most FP wins!';
					case 4:
						winCondition.descText.text = 'Side with the highest Combo wins!';
				}
				winCondition.descText.text += ' (Click to Change)';
				winCondition.box.makeGraphic(Std.int(winCondition.descText.x - winCondition.x + winCondition.descText.width) + 10, Std.int(winCondition.height), 0x81000000);
			}

			prevCond = GameClient.room.state.winCondition;
		}, 0, 0, false, true));

		items.add(modifers = new Option("Game Modifiers", "Set your Gameplay Modifiers here!", () -> {
			close();
			FlxG.state.openSubState(new GameplayChangersSubstate());
		}, null, 0, 0, false, true));

		items.add(stageSelect = new Option("Select Stage", "Currently Selected: " + (GameClient.room.state.stageName == "" ? '(default)' : GameClient.room.state.stageName), () -> {
			if (GameClient.hasPerms()) {
				close();
				FlxG.state.openSubState(new SelectStageSubstate());
			}
		}, (elapsed) -> {
			stageSelect.alpha = GameClient.hasPerms() ? 1 : 0.8;
		}, 0, 0, false, true));

		items.add(skinSelect = new Option("Select Skin", "Select your Skin here!", () -> {
			if (!GameClient.room.state.disableSkins) {
				LoadingState.loadAndSwitchState(new SkinsState());
			}
			else {
				Alert.alert('Skins are disabled!');
			}
		}, null, 0, 0, false, true));

		items.add(gameOptions = new Option("Game Options", "Open your Game Options here!", () -> {
			LoadingState.loadAndSwitchState(new OptionsState());
			OptionsState.onPlayState = false;
			OptionsState.onOnlineRoom = true;
		}, null, 0, 0, false, true));

		items.add(mods = new Option("Mods", "Check your installed Mods here!", () -> {
			LoadingState.loadAndSwitchState(new ModsMenuState());
			ModsMenuState.onOnlineRoom = true;
		}, null, 0, 0, false, true));

		updateItems();

		add(items);

		GameClient.send("status", "In the Room Settings");
	}

	function updateItems() {
		var i = 0;

		function nextItem(item:Option) {
			item.y = items.y + 80 * i;
			item.ID = i++;
		}

		nextItem(publicRoom);
		nextItem(anarchyMode);
		nextItem(swapSides);
		nextItem(teamMode);
		nextItem(royalMode);
		royalModeBfSide.visible = GameClient.room.state.royalMode;
		if (royalModeBfSide.visible) {
			nextItem(royalModeBfSide);
		}
		nextItem(hideGF);
		nextItem(disableSkins);
		nextItem(winCondition);
		nextItem(modifers);
		nextItem(stageSelect);
		nextItem(skinSelect);
		nextItem(gameOptions);
		nextItem(mods);
		
		var lastItem = items.members[items.length - 1];
		coolCam.setScrollBounds(FlxG.width, FlxG.width, 0, lastItem.y + lastItem.height + 40 > FlxG.height ? lastItem.y + lastItem.height + 40 : FlxG.height);
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

	var mouseSelectTime = 0.0;

    override function update(elapsed) {
        if (controls.BACK) {
            close();
			FlxG.mouse.visible = prevMouseVisibility;
        }

		if (!GameClient.isConnected()) {
			return;
		}

		super.update(elapsed);

		if (mouseSelectTime > 0.0)
			mouseSelectTime -= elapsed;

		if (FlxG.mouse.justPressed || FlxG.mouse.deltaX != 0 || FlxG.mouse.deltaY != 0)
			mouseSelectTime = 0.5;

		if (controls.UI_UP_P || FlxG.mouse.wheel == 1)
			curSelectedID--;
		else if (controls.UI_DOWN_P || FlxG.mouse.wheel == -1)
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
			
			if (mouseSelectTime > 0 && FlxG.mouse.overlaps(option, camera)) {
				curSelectedID = option.ID;
            }

			if (FlxG.mouse.overlaps(option, camera) && FlxG.mouse.justPressed) {
				option.onClick();
			}

			if (option.ID == curSelectedID) {
				coolCam.follow(option, TOPDOWN, 0.1);
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