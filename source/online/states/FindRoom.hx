package online.states;

import states.MainMenuState;
import flixel.FlxObject;
import io.colyseus.Client.RoomAvailable;
import lime.app.Application;

class FindRoom extends MusicBeatState {
	var swagRooms:FlxTypedSpriteGroup<RoomText>;
    public static var curSelected:Int;
    public static var curRoom:Room;
    public static var coolControls:Controls;

    var noRoomsText:FlxText;

	var selectLine:FlxSprite;

    public function new() {
        super();

		coolControls = controls;
    }

    override function create() {
		super.create();

		DiscordClient.changePresence("Finding a room.", null, null, false);

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xff252844;
		bg.updateHitbox();
		bg.screenCenter();
		bg.scrollFactor.set(0, 0);
		bg.antialiasing = Wrapper.prefAntialiasing;
		add(bg);

		var lines:FlxSprite = new FlxSprite().loadGraphic(Paths.image('coolLines'));
		lines.updateHitbox();
		lines.screenCenter();
		lines.antialiasing = Wrapper.prefAntialiasing;
		lines.scrollFactor.set(0, 0);
		add(lines);

		selectLine = new FlxSprite();
		selectLine.makeGraphic(1, 1, FlxColor.BLACK);
		selectLine.alpha = 0.3;
		selectLine.scale.set(FlxG.width, 25);
		selectLine.screenCenter(XY);
		selectLine.y -= 8;
		selectLine.scrollFactor.set(0, 0);
		add(selectLine);

		swagRooms = new FlxTypedSpriteGroup<RoomText>();
		add(swagRooms);
		curSelected = 0;

		noRoomsText = new FlxText(0, 0, 0, "(No rooms found! Refresh the list using R)");
		noRoomsText.setFormat("VCR OSD Mono", 25, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		noRoomsText.screenCenter(XY);
		noRoomsText.scrollFactor.set(0, 0);
		add(noRoomsText);

		refreshRooms();
    }

    override function update(elapsed) {
        super.update(elapsed);

		noRoomsText.visible = swagRooms.length <= 0;
		selectLine.visible = swagRooms.length > 0;

        if (FlxG.keys.justPressed.R) {
            refreshRooms();
        }

		if (controls.UI_UP_P || FlxG.mouse.wheel == 1)
			curSelected--;
		else if (controls.UI_DOWN_P || FlxG.mouse.wheel == -1)
			curSelected++;

		if (curSelected >= swagRooms.length) {
			curSelected = swagRooms.length - 1;
		}
		else if (curSelected < 0) {
			curSelected = 0;
		}
		
		if (controls.BACK || FlxG.mouse.justPressedRight) {
			MusicBeatState.switchState(new OnlineState());
			FlxG.sound.play(Paths.sound('cancelMenu'));
        }
    }

    function refreshRooms() {
		curSelected = 0;
		swagRooms.clear();

		LoadingScreen.toggle(true);
		GameClient.getAvailableRooms((err, rooms) -> {
            Waiter.put(() -> {
				LoadingScreen.toggle(false);
				
                if (err != null) {
					MusicBeatState.switchState(new OnlineState());
					FlxG.sound.play(Paths.sound('cancelMenu'));
					Alert.alert("Couldn't connect!", "ERROR: " + err.code + " - " + err.message + (err.code == 0 ? "\nTry again in a few minutes! The server is probably restarting!" : ""));
                    return;
                }

				curSelected = 0;
				swagRooms.clear();

                var i = 0;
                for (room in rooms) {
					var swagRoom = new RoomText(room);
					swagRoom.ID = i;
                    swagRoom.y += 30 * i;
                    swagRooms.add(swagRoom);
					i++;
                }
            });
        });
    }
}

class RoomText extends FlxText {
    public var code:String;
    var daText:String;

    var _prevSelected:Int = -1;

    public function new(room:RoomAvailable) {
		code = room.roomId;
		daText = "Code: " + code + " • Player: " + room.metadata.name + " • " + room.metadata.ping + "ms";

		super(0, 0, FlxG.width, daText);
	    setFormat("VCR OSD Mono", 30, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    }

    override function update(elapsed) {
        super.update(elapsed);

		if (FindRoom.curSelected != _prevSelected) {
			if (FindRoom.curSelected == ID) {
				text = "> " + daText + " <";
				alpha = 1;
				FlxG.camera.follow(this);
			}
			else {
				text = daText;
				alpha = 0.5;
			}
        }

		if (FindRoom.curSelected == ID && !FlxG.keys.justPressed.R && FindRoom.coolControls.ACCEPT) {
			GameClient.joinRoom(code, () -> Waiter.put(() -> {
                trace("joining room: " + code);
				MusicBeatState.switchState(new Room());
			}));
		}

		_prevSelected = FindRoom.curSelected;
    }
}