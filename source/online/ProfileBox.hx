package online;

import online.net.FunkinNetwork;
import flixel.util.FlxSpriteUtil;

class ProfileBox extends FlxSpriteGroup {
	var data:Dynamic;

	var avatar:FlxSprite;
	public var text:FlxText;

    public function new(user:String) {
        super();

		data = FunkinNetwork.fetchUserInfo(user); 

        var bg = new FlxSprite();
		FlxSpriteUtil.drawRoundRect(bg, 0, 0, 300, 200, 20, 20, FlxColor.fromHSL(data.profileHue ?? 250, 0.2, 0.2));
        add(bg);

        avatar = new FlxSprite();
        add(avatar);

		text = new FlxText(0, 0, 0, "PLAYER 1");
		text.setFormat("VCR OSD Mono", 15, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(text);

		updatePositions();

        Thread.run(() -> {
			var avatarData = FunkinNetwork.getUserAvatar(user);

            Waiter.put(() -> {
				if (!destroyed && avatarData != null) {
					avatar.loadGraphic(avatarData);
					avatar.width = 100;
					avatar.height = 100;
					updatePositions();
				}
            });
        });
    }

    public function updatePositions() {
        
    }

    var destroyed:Bool = false;
    override function destroy() {
		destroyed = true;
        super.destroy();
    }
}