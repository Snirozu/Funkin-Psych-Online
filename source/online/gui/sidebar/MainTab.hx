package online.gui.sidebar;

import haxe.io.BytesOutput;
import haxe.io.Bytes;
import haxe.crypto.Base64;
import online.net.FunkinNetwork;

class MainTab extends TabSprite {
	var nickname:TextField;
	var nameDesc:TextField;
	var avatar:Bitmap;
	var avatarLoaded:Bool = false;

	override function create() {
		var bitmap = new Bitmap(new BitmapData(Std.int(widthTab), 150 + (30 * 2), true, FlxColor.fromRGB(0, 0, 0, 200)));
		addChild(bitmap);

		nickname = new TextField();
		nickname.selectable = false;
		var format = getDefaultFormat();
		format.size = 20;
		nickname.defaultTextFormat = format;
		nickname.width = widthTab;
		nickname.y = 40;
		nickname.x = widthTab / 2 - nickname.width / 2;
		addChild(nickname);

		nameDesc = new TextField();
		nameDesc.selectable = false;
		nameDesc.defaultTextFormat = getDefaultFormat();
		nameDesc.width = widthTab;
		nameDesc.y = nickname.y + 30;
		nameDesc.x = nickname.x;
		addChild(nameDesc);

		avatar = new Bitmap(new BitmapData(30, 30, true, FlxColor.fromRGB(0, 0, 0, 0)));
		addChild(avatar);
	}

    override function init() {
		nickname.text = FunkinNetwork.loggedIn ? "Welcome, " + FunkinNetwork.nickname : "Not Logged In";
		nameDesc.text = "Points: " + FunkinNetwork.points;

		if (FunkinNetwork.loggedIn && !avatarLoaded) {
			Thread.run(() -> {
				var output = new BytesOutput();
				var avatarResponse = FunkinNetwork.requestAPI({
					path: 'api/avatar/' + Base64.encode(Bytes.ofString(FunkinNetwork.nickname)),
					bodyOutput: output
				});
				if (!avatarResponse.isFailed()) {
					Waiter.put(() -> {
						if (avatar != null) {
							avatarLoaded = true;
							avatar.bitmapData = BitmapData.fromBytes(output.getBytes());
							avatar.width = 150;
							avatar.height = 150;
							avatar.x = 50;
							avatar.y = 30;

							nickname.x = avatar.x + avatar.width + 20;
							nameDesc.x = nickname.x;
						}
					});
				}
			});
		}
    }
}