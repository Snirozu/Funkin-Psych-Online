package online;

import flixel.util.FlxSpriteUtil;

class ServerSettingsSubstate extends MusicBeatSubstate {
    var bg:FlxSprite;
	var prevMouseVisibility:Bool = false;
	var items:FlxTypedSpriteGroup<CheckboxOption>;
	var curSelectedID:Int = 0;

    //options
	var publicRoom:CheckboxOption;
	var anarchyMode:CheckboxOption;
	var swapSides:CheckboxOption;
    
    public function new() {
        super();

		prevMouseVisibility = FlxG.mouse.visible;

		FlxG.mouse.visible = true;

        bg = new FlxSprite();
        bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg.alpha = 0.8;
        add(bg);

		items = new FlxTypedSpriteGroup<CheckboxOption>(40, 40);

		items.add(publicRoom = new CheckboxOption("Public Room", "If enabled, this room is publicly listed in the FIND tab.", () -> {
			if (GameClient.hasPerms()) {
				GameClient.send("togglePrivate");
			}
        }, (elapsed) -> {
			publicRoom.alpha = GameClient.hasPerms() ? 1 : 0.8;

			publicRoom.check.visible = !GameClient.room.state.isPrivate;
        }, 0, 0));
		publicRoom.ID = 0;

		items.add(anarchyMode = new CheckboxOption("Anarchy Mode", "This option gives Player 2 host permissions.", () -> {
			if (GameClient.hasPerms()) {
				GameClient.send("anarchyMode");
			}
        }, (elapsed) -> {
			anarchyMode.alpha = GameClient.hasPerms() ? 1 : 0.8;

			anarchyMode.check.visible = GameClient.room.state.anarchyMode;
        }, 0, 80));
		anarchyMode.ID = 1;

		items.add(swapSides = new CheckboxOption("Swap Sides", "Swaps Player 1's strums with Player 2.", () -> {
			if (GameClient.hasPerms()) {
				GameClient.send("swapSides");
			}
        }, (elapsed) -> {
			swapSides.alpha = GameClient.hasPerms() ? 1 : 0.8;

			swapSides.check.visible = GameClient.room.state.swagSides;
        }, 0, 80 * 2));
		swapSides.ID = 2;

		add(items);
    }

    override function update(elapsed) {
        super.update(elapsed);

        if (controls.BACK) {
            close();
			FlxG.mouse.visible = prevMouseVisibility;
        }

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
			if (FlxG.mouse.justMoved && FlxG.mouse.overlaps(option)) {
				curSelectedID = option.ID;
            }

			if (option.ID == curSelectedID) {
                option.box.visible = true;

                if (controls.ACCEPT) {
                    option.onClick();
                }
            }
            else {
				option.box.visible = false;
            }
        });
    }
}

class CheckboxOption extends FlxSpriteGroup {
	public var box:FlxSprite;
	var checkbox:FlxSprite;
	public var check:FlxSprite;
	public var text:FlxText;
	public var descText:FlxText;
	public var onClick:Void->Void;
	var onUpdate:Float->Void;

	public function new(title:String, description:String, onClick:Void->Void, onUpdate:Float->Void, x:Int, y:Int) {
        super(x, y);

		this.onClick = onClick;
		this.onUpdate = onUpdate;

		box = new FlxSprite();
        box.setPosition(-5, -5);
        add(box);

        checkbox = new FlxSprite();
		checkbox.makeGraphic(50, 50, 0x50000000);
		FlxSpriteUtil.drawRect(checkbox, 0, 0, checkbox.width, checkbox.height, FlxColor.TRANSPARENT, {thickness: 5, color: FlxColor.WHITE});
        checkbox.updateHitbox();
        add(checkbox);

        check = new FlxSprite();
        check.loadGraphic(Paths.image('check'));
		check.visible = false;
        add(check);

		text = new FlxText(0, 0, 0, title);
		text.setFormat("VCR OSD Mono", 22, FlxColor.WHITE);
		text.x = checkbox.width + 10;
        //text.y = checkbox.height / 2 - text.height / 2;
        add(text);

		descText = new FlxText(0, 0, 0, description);
		descText.setFormat("VCR OSD Mono", 18, FlxColor.WHITE);
		descText.x = checkbox.width + 10;
		descText.y = text.height + 2;
		add(descText);

		box.makeGraphic(Std.int(width) + 10, Std.int(height) + 10, 0x80000000);
		box.visible = false;
    }

    override function update(elapsed) {
        super.update(elapsed);

		if (GameClient.room == null)
			return;

        if (FlxG.mouse.overlaps(this) && FlxG.mouse.justPressed) {
            onClick();
        }

		onUpdate(elapsed);
    }
}