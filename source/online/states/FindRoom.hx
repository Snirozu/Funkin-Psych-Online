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

    public function new() {
        super();

		coolControls = controls;

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xff2d3683;
		bg.updateHitbox();
		bg.screenCenter();
		bg.scrollFactor.set(0, 0);
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);
        
		swagRooms = new FlxTypedSpriteGroup<RoomText>();
		add(swagRooms);
		curSelected = 0;

		noRoomsText = new FlxText(0, 0, 0, "(No rooms found! Refresh the list using R)");
		noRoomsText.setFormat("VCR OSD Mono", 25, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		noRoomsText.screenCenter(XY);
		noRoomsText.scrollFactor.set(0, 0);
		add(noRoomsText);
    }

    override function create() {
		refreshRooms();
    }

    override function update(elapsed) {
        super.update(elapsed);

		noRoomsText.visible = swagRooms.length <= 0;

        if (FlxG.keys.justPressed.R) {
            refreshRooms();
        }

		if (controls.UI_UP_P)
			curSelected--;
		else if (controls.UI_DOWN_P)
			curSelected++;

		if (curSelected >= swagRooms.length) {
			curSelected = 0;
		}
		else if (curSelected < 0) {
			curSelected = swagRooms.length - 1;
		}

		
        if (controls.BACK) {
			FlxG.switchState(new Lobby());
			FlxG.sound.play(Paths.sound('cancelMenu'));
        }
    }

    function refreshRooms() {
		curSelected = 0;
		swagRooms.clear();

		GameClient.getAvailableRooms((err, rooms) -> {
            Waiter.put(() -> {
                if (err != null) {
					FlxG.switchState(new MainMenuState());
					FlxG.sound.play(Paths.sound('cancelMenu'));
                    Application.current.window.alert("ERROR: " + err.code + " - " + err.message + (err.code == 0 ? "\nTry again in a few minutes! The server is probably restarting!" : ""), "Couldn't connect!");
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
		daText = "Code: " + code + " | Player: " + room.metadata.name;

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
				alpha = 0.8;
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