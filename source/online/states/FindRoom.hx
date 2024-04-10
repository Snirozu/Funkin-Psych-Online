package online.states;

import openfl.Lib;
import flixel.FlxObject;

class FindRoom extends MusicBeatState {
    public static var instance:FindRoom;

    public var items:FlxTypedGroup<RoomBox>;
    public var selected(default, set):Int = 0;
    function set_selected(v) {
		if (v >= items.length) {
			v = items.length - 1;
		}
		else if (v < 0) {
			v = 0;
		}

        return selected = v;
    }

	public var camFollow:FlxObject;

    var refreshTimer:FlxTimer;

	var tip:FlxText;
	var tipBg:FlxSprite;
    var emptyMessage:FlxText;

    override function create() {
        instance = this;

		super.create();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Finding a room.", null, null, false);
		#end

		camera.follow(camFollow = new FlxObject(FlxG.width / 2), 0.1);

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xff252844;
		bg.updateHitbox();
		bg.screenCenter();
		bg.scrollFactor.set(0, 0);
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

        add(items = new FlxTypedGroup<RoomBox>());
        refreshRooms();
		refreshTimer = new FlxTimer().start(5, (t) -> {
			refreshRooms(false);
		}, 0);

		tip = new FlxText(0, 0, 0, 'ACCEPT - Enter selected room.');
		tip.setFormat("VCR OSD Mono", 18, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		tip.scrollFactor.set(0, 0);
		tip.screenCenter(X);
		tip.y = FlxG.height - tip.height - 40;
		tip.alpha = 0.6;

		tipBg = new FlxSprite(tip.x - 5, tip.y - 5);
		tipBg.makeGraphic(Std.int(tip.width) + 10, Std.int(tip.height) + 10, 0x81000000);
		tipBg.scrollFactor.set(0, 0);
		add(tipBg);
		add(tip);

		emptyMessage = new FlxText(0, 0, FlxG.width, 'No available rooms found!');
		emptyMessage.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		emptyMessage.scrollFactor.set(0, 0);
		emptyMessage.screenCenter();
		emptyMessage.visible = false;
		add(emptyMessage);
    }

    override function update(elapsed) {
		if (controls.UI_UP_P)
            selected--;
		else if (controls.UI_DOWN_P)
			selected++;

        if (FlxG.keys.justPressed.R) {
			@:privateAccess refreshTimer._timeCounter = 0;
			refreshRooms();
        }
		else if (controls.BACK) {
			refreshTimer.cancel();
            LoadingScreen.toggle(false);
			FlxG.sound.music.volume = 1;
			FlxG.switchState(() -> new OnlineState());
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}

		camera.scroll.x = FlxG.width / 2 - camFollow.getMidpoint().x;

		tip.visible = items.length > 0;
		tipBg.visible = tip.visible;

        super.update(elapsed);
    }

	function refreshRooms(wLoading:Bool = true) {
		if (wLoading)
		    LoadingScreen.toggle(true);
		GameClient.getAvailableRooms(GameClient.serverAddress, (err, rooms) -> {
            Waiter.put(() -> {
                if (destroyed)
                    return;

				var lastCode = null;
				if (items.length > 0)
					lastCode = items.members[selected].code;

				items.clear();

                if (err != null) {
					Alert.alert("Couldn't connect!", "ERROR: " + err.code + " - " + err.message + (GameClient.serverAddress.endsWith(".onrender.com") ? "\nTry again in a few minutes! The server is probably restarting!" : ""));
                    return;
                }

				if (wLoading)
					LoadingScreen.toggle(false);

                var i = 0;
                var newSelected = null;

                for (room in rooms) {
					var swagRoom = new RoomBox(room.metadata.name, room.roomId, room.metadata.ping ?? "?");
					swagRoom.ID = i++;
					items.add(swagRoom);
                    
					if (swagRoom.code == lastCode) {
						newSelected = swagRoom.ID;
                    }
                }

				emptyMessage.visible = items.length <= 0;
                if (newSelected != null)
					selected = newSelected;
				selected += 0;
            });
        });
    }

    public function getAddress() {
        return GameClient.serverAddress;
    }
}

class RoomBox extends FlxSpriteGroup {

    public var code:String;

    var bg:FlxSprite;
    var title:FlxText;
	var ping:FlxText;
	var detailsTxt:FlxText;

    public var hitbox:FlxObject;

    public function new(name:String, code:String, pingMs:String) {
        super();

		this.code = code;

		hitbox = new FlxObject(0, 0, 700, 0);

        bg = new FlxSprite();
		bg.makeGraphic(Std.int(hitbox.width), 1, 0x81000000);
        add(bg);

		title = new FlxText(0, 0, bg.width - 20, name);
		title.setFormat("VCR OSD Mono", 22, FlxColor.WHITE, LEFT);
		title.setPosition(10, 10);
		add(title);

		ping = new FlxText(0, 0, bg.width - 20, pingMs + "ms");
		ping.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, RIGHT);
		ping.setPosition(10, title.y);
		add(ping);

		detailsTxt = new FlxText(0, 0, bg.width - 20, '> Enter: $code < ');
		detailsTxt.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, CENTER);
		detailsTxt.setPosition(10, title.y + title.height + 20);
		add(detailsTxt);

		// bg.scale.y = details ? detailsTxt.y + detailsTxt.height + 10 : title.y + title.height + 10;
		bg.scale.y = title.y + title.height + 10;
		bg.updateHitbox();
		screenCenter(X);
    }

    override function update(elapsed) {
        super.update(elapsed);

		hitbox.x = x;
		hitbox.y = y;

		if (FlxG.mouse.overlaps(hitbox) && (FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0 || FlxG.mouse.justPressed)) {
			FindRoom.instance.selected = ID;
        }

        if (ID == FindRoom.instance.selected) {
            alpha = 1.0;
			detailsTxt.visible = true;
			hitbox.height = detailsTxt.y - hitbox.y + detailsTxt.height;
			FindRoom.instance.camFollow.setPosition(hitbox.getMidpoint().x, hitbox.getMidpoint().y);

			if (FindRoom.instance.controls.ACCEPT || (FlxG.mouse.justPressed && FlxG.mouse.overlaps(hitbox))) {
				GameClient.joinRoom('$code;${FindRoom.instance.getAddress()}', (err) -> Waiter.put(() -> {
					if (err != null) {
						return;
					}
					FlxG.switchState(() -> new Room());
				}));
			}
        }
        else {
            alpha = 0.6;
			detailsTxt.visible = false;
			hitbox.height = bg.height;
        }

        if (ID <= 0)
            return;
		y = FindRoom.instance.items.members[ID - 1].y + FindRoom.instance.items.members[ID - 1].hitbox.height + 20;
    }
}