package online.objects;

import flixel.util.FlxStringUtil;
import online.network.FunkinNetwork;
import flixel.util.FlxSpriteUtil;

//slop class, i coded it really lazily 
class ProfileBox extends FlxSpriteGroup {
    public var isSelf:Bool = false;

	public var user:String;
	public var verified:Bool = false;
	public var cardHeight:Int;
	public var autoCardHeight:Bool = true;
	public var profileData:Dynamic;

    var bg:FlxSprite;
	var avatar:FlxSprite;
	public var text:FlxText;
	public var desc:FlxText;
	
	public var autoUpdateThings:Bool = true;
	public var sizeAdd:Int = 0;

	public function new(leUser:String, leVerified:Bool, ?leCardHeight:Int = 100, ?sizeAdd:Int = 0) {
        super();

		this.sizeAdd = sizeAdd;

        bg = new FlxSprite();
		bg.alpha = 0.7;
        add(bg);

        avatar = new FlxSprite(0, 0);
		avatar.antialiasing = ClientPrefs.data.antialiasing;
		avatar.visible = false;
        add(avatar);

		text = new FlxText(0, 0, 0, "");
		text.setFormat("VCR OSD Mono", 16 + sizeAdd, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(text);

		desc = new FlxText(0, 0, 0, "");
		desc.setFormat("VCR OSD Mono", 14 + sizeAdd, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(desc);

		cardHeight = leCardHeight;

		updateData(leUser, leVerified);
    }

	public function updateData(leUser:String, leVerified:Bool) {
		if (destroyed)
			return;

		user = leUser;
		verified = leVerified;

		avatar.makeGraphic(0, 0, FlxColor.TRANSPARENT);
		avatar.visible = false;

		profileData = null;
		drawBG();
		if (autoUpdateThings) {
			text.text = "";
			desc.text = "";
		}

		Thread.run(() -> {
			isSelf = verified && user == FunkinNetwork.nickname;

			if (verified)
				profileData = FunkinNetwork.fetchUserInfo(user);
			else
				profileData = null;

			Waiter.put(creativo);
		});
	}

    public function creativo() {
		if (destroyed)
			return;

		if (autoUpdateThings) {
			text.text = "";
			desc.text = "";
		}

		if (verified) {
			if (profileData != null) {
				if (autoUpdateThings) {
					if (isSelf)
						text.text = "Welcome, " + user + "!";
					else
						text.text = user;
					desc.text = "Points: " + FlxStringUtil.formatMoney(profileData.points ?? 0, false);
					desc.text += "\nRank: " + ShitUtil.toOrdinalNumber(profileData.rank);
					desc.text += "\nAvg. Accuracy: " + FlxMath.roundDecimal((profileData.avgAccuracy * 100), 2) + "%";
				}

				Thread.run(() -> {
					var avatarData = FunkinNetwork.getUserAvatar(user);

					Waiter.put(() -> {
						if (!destroyed && avatarData != null) {
							avatar.visible = true;
							avatar.loadGraphic(avatarData);
							fitAvatar();
							updatePositions();
						}
					});
				});
			}
			else {
				if (autoUpdateThings) {
					if (isSelf) {
						text.text = "Not logged in!";
						desc.text = "(Click to register)";
					}
					else
						text.text = "User not found!";
					cardHeight = 50;
				}
			}
		}

		drawBG();
    }

    public function drawBG() {
		var profileHue = profileData?.profileHue ?? 230;

		bg.makeGraphic(320 + 10 * sizeAdd, cardHeight, FlxColor.TRANSPARENT);
		// later concept for detailed cards, fill a tall round rectangle with darker color and then draw the normal card
		FlxSpriteUtil.drawRoundRect(bg, 0, 0, 320 + 10 * sizeAdd, cardHeight, 40, 40, FlxColor.fromHSL(profileHue, 0.25, 0.25));
		bg.updateHitbox();

		fitAvatar();
        updatePositions();
    }

    public function fitAvatar() {
		if (avatar == null || avatar.width < 1)
            return;

		avatar.setGraphicSize(Math.min(cardHeight * 0.8, 80), Math.min(cardHeight * 0.8, 80));
		avatar.updateHitbox();
		updatePositions();
    }

	var maxTextSize:Float = 0.0;
	var maxTextSizeDesc:Float = 0.0;
	var _cardHeight:Int;
    public function updatePositions() {
		if (destroyed)
			return;
		
		avatar.x = x + 20;
		avatar.y = y + height / 2 - avatar.height / 2;
		text.x = avatar.x + avatar.width + 20;
		text.y = y + 15;
		desc.x = text.x;
		if (!avatar.visible) {
			text.x = x + bg.width / 2 - text.width / 2;
			desc.x = x + bg.width / 2 - desc.width / 2;
			// text.y = y + bg.height / 2 - text.height / 2 - (desc.text.length > 0 ? (cardHeight >= 80 ? 20 : 10) : 0);
        }
		text.alignment = LEFT;
		desc.y = text.y + text.height + 5;
		if (desc.text.length < 1) {
			if (!avatar.visible)
				text.alignment = CENTER;
			desc.y = text.y + text.height;
			desc.height = 0;
		}

		maxTextSize = bg.width - (text.x - x) - 20;
		text.fieldWidth = maxTextSize;
		//text.scale.x = Math.min(1, maxTextSizeDesc / text.width);

		maxTextSizeDesc = bg.width - (desc.x - x) - 20;
		desc.fieldWidth = maxTextSizeDesc;
		//desc.scale.x = Math.min(1, maxTextSizeDesc / desc.width);

		if (autoCardHeight) {
			_cardHeight = Std.int(Math.max((desc.y - y) + desc.height, (avatar.y - y) + avatar.height) + 20);
			if (cardHeight != _cardHeight) {
				cardHeight = _cardHeight;
				drawBG();
			}
		}
    }

    override function update(elapsed) {
        super.update(elapsed);

		bg.alpha = FlxG.mouse.overlaps(this, camera) ? 1 : 0.8;
		if (FlxG.mouse.overlaps(this, camera) && FlxG.mouse.justPressed) {
			if (user != null)
				online.gui.sidebar.tabs.ProfileTab.view(user);
			else if (isSelf && !FunkinNetwork.loggedIn)
				FlxG.switchState(() -> new OnlineOptionsState(true));
        }
    }

    var destroyed:Bool = false;
    override function destroy() {
		destroyed = true;
        super.destroy();
    }
}