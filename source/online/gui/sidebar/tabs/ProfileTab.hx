package online.gui.sidebar.tabs;

import com.yagp.GifPlayerWrapper;
import com.yagp.GifPlayer;
import com.yagp.GifDecoder;
import com.yagp.Gif;
import online.http.HTTPHandler;

class ProfileTab extends TabSprite {
	static var flagCDN:HTTPHandler;
	static var flagsAPI:HTTPHandler;

	var nextUsername:String = null;
	var username(default, set):String;
	var user:UserDetailsData;

	var loading(default, set):Bool = false;

	var avatar:Bitmap;
	var flag:Bitmap;
	var usernameTxt:TextField;
	var role:TextField;
	var seen:TextField;
	var stats:TextField;
	var loadingTxt:TextField;
	var desc:TextField;
	var line1:Bitmap;
	var line2:Bitmap;
	var statsTitle:TextField;

	var addFriend:TabButton;
	var removeFriend:TabButton;
	var invitePlay:TabButton;
	var settings:TabButton;
	var web:TabButton;

    public function new() {
        super('Profile', 'profile');
    }

    public static function view(username:String) {
		SideUI.instance.active = true;
		cast(SideUI.instance.tabs[SideUI.instance.initTabs.indexOf(ProfileTab)], ProfileTab).nextUsername = username;
		SideUI.instance.curTabIndex = SideUI.instance.initTabs.indexOf(ProfileTab);
    }

    override function create() {
        super.create();

		flagCDN = new HTTPHandler('https://flagcdn.com');
		flagsAPI = new HTTPHandler('https://flagsapi.com');
		
		loadingTxt = this.createText(20, 20, 40);
		loadingTxt.setText('Fetching...');
		loadingTxt.visible = false;
		addChild(loadingTxt);

		avatar = new Bitmap(FunkinNetwork.getDefaultAvatar());
		avatar.width = 125;
		avatar.height = 125;
		avatar.x = 20;
		avatar.y = 20;
		addChild(avatar);

		flag = new Bitmap(new BitmapData(1, 1, true, 0x00000000));
		addChild(flag);

		usernameTxt = this.createText(avatar.x + avatar.width + 20, avatar.y + 10, 40);
		addChild(usernameTxt);

		role = this.createText(usernameTxt.x, usernameTxt.y + 40, 22);
		addChild(role);

		seen = this.createText(role.x, role.y + 30, 20, 0xFF7C7C7C);
		addChild(seen);

		desc = this.createText(avatar.x, avatar.y + avatar.height + 10, 15);
		desc.setText("");
		addChild(desc);

		line1 = new Bitmap(new BitmapData(1, 2, true, 0xFFFFFFFF));
		line1.x = desc.x;
		line1.y = desc.y + desc.height + 10;
		line1.scaleX = tabBg.width - 40;
		addChild(line1);

		statsTitle = this.createText(0, line1.y + 20, 30);
		statsTitle.setText("Statistics");
		statsTitle.x = tabBg.width / 2 - statsTitle.textWidth / 2;
		addChild(statsTitle);

		line2 = new Bitmap(new BitmapData(1, 2, true, 0xFFFFFFFF));
		line2.x = line1.x;
		line2.y = statsTitle.y + 50;
		line2.scaleX = line1.scaleX;
		addChild(line2);

		stats = this.createText(50, line2.y + 20, 22);
		addChild(stats);

		web = new TabButton('internet', () -> {
			FlxG.openURL(FunkinNetwork.client.getURL("/user/" + StringTools.urlEncode(username)));
		});
		web.x = tabBg.width - web.width - 20;
		web.y = tabBg.height - web.height - 20;
		addChild(web);

		settings = new TabButton('wheel', () -> {
			FlxG.openURL(FunkinNetwork.client.getURL("/api/account/cookie?id=" + Auth.authID + "&token=" + Auth.authToken));
		});
		settings.x = web.x;
		settings.y = web.y;
		addChild(settings);

		addFriend = new TabButton('add_friend', () -> inviteToFriends());
		addFriend.x = web.x - web.width - 20;
		addFriend.y = web.y;
		addChild(addFriend);

		removeFriend = new TabButton('remove_friend', () -> removeFromFriends());
		removeFriend.x = addFriend.x;
		removeFriend.y = web.y;
		addChild(removeFriend);

		invitePlay = new TabButton('invite', () -> Util.inviteToPlay(username));
		invitePlay.x = addFriend.x - addFriend.width - 20;
		invitePlay.y = web.y;
		addChild(invitePlay);
    }

	override function onShow() {
        super.onShow();

		if (nextUsername == null)
            username = FunkinNetwork.nickname;
		else
			username = nextUsername;
    }

	override function onHide() {
		super.onHide();

		if (!SideUI.instance.active)
			nextUsername = null;
	}

	function set_username(v:String) {
		username = v;

		loading = true;
		Thread.run(() -> {
			var response = FunkinNetwork.requestAPI('/api/user/details?name=' + StringTools.urlEncode(username));

			if (response != null && !response.isFailed()) {
				Waiter.putPersist(() -> {
					if (v == username) {
						user = Json.parse(response.getString());
						renderData();
                    }
				});
			}
		});

        return username;
	}

	function set_loading(v:Bool) {
		for (child in __children) {
			child.visible = !v;
		}
		tabBg.visible = true;
		loadingTxt.visible = v;
		if (v)
			tabBg.bitmapData = new BitmapData(tabBg.bitmapData.width, tabBg.bitmapData.height, true, FlxColor.fromRGB(10, 10, 10));
		return loading = v;
	}

	function removeFromFriends() {
		LoadingScreen.toggle(true);

		var daUsername = username;
		Thread.run(() -> {
			var response = FunkinNetwork.requestAPI('/api/user/friends/remove?name=' + StringTools.urlEncode(daUsername));

			LoadingScreen.toggle(false);

			if (response != null && !response.isFailed()) {
				Waiter.putPersist(() -> {
					Alert.alert('Removed ' + daUsername + " from friends");
					if (username == daUsername)
						username = username;
				});
			}
		});
	}

	function inviteToFriends() {
		LoadingScreen.toggle(true);

		var daUsername = username;
		Thread.run(() -> {
			var response = FunkinNetwork.requestAPI('/api/user/friends/request?name=' + StringTools.urlEncode(daUsername));

			LoadingScreen.toggle(false);

			if (response != null && !response.isFailed()) {
				Waiter.putPersist(() -> {
					Alert.alert('Friend invite has been sent to ' + daUsername + "!");
					if (username == daUsername)
						username = username;
				});
			}
		});
	}

    function renderData() {
		loading = false;
        var loadingUser = username;
		
		tabBg.bitmapData = new BitmapData(tabBg.bitmapData.width, tabBg.bitmapData.height, true, FlxColor.fromHSL(user.profileHue, 0.2, 0.2));

		var prevAvatar = avatar;
		avatar = new Bitmap(FunkinNetwork.getDefaultAvatar());

		addChildAt(avatar, getChildIndex(prevAvatar));
		removeChild(prevAvatar);

		avatar.x = 20;
		avatar.y = 20;
		avatar.width = 125;
		avatar.height = 125;

		flag.bitmapData = new BitmapData(1, 1, true, 0x00000000);
		flag.visible = false;
		Thread.run(() -> {
			var avatarData = FunkinNetwork.getUserAvatar(loadingUser);

			Waiter.putPersist(() -> {
				if (loadingUser == username) {
					var prevAvatar = avatar;

					if (avatarData == null)
						avatar = new Bitmap(FunkinNetwork.getDefaultAvatar());
					else if (!ShitUtil.isGIF(avatarData))
						avatar = new Bitmap(BitmapData.fromBytes(avatarData));
					else
						avatar = new GifPlayerWrapper(new GifPlayer(GifDecoder.parseBytes(avatarData)));

					addChildAt(avatar, getChildIndex(prevAvatar));
					removeChild(prevAvatar);

					avatar.x = 20;
					avatar.y = 20;
					avatar.width = 125;
					avatar.height = 125;
				}
			});

			loadFlag(loadingUser, user.country);
		});

		updateUsernameText();
		role.setText(user.role != null ? user.role : 'Member');
		var seenAgo = ShitUtil.timeAgo(ShitUtil.parseISODate(user.lastActive).getTime());
		if (seenAgo == 'just now')
			seen.setText("ONLINE", null, FlxColor.LIME);
		else
			seen.setText("Seen " + seenAgo, null, 0xFF7C7C7C);

		desc.setText(ShitUtil.pickReadableHTML(user.bio ?? '').wrapText());
		desc.selectable = true;

		line1.x = desc.x;
		line1.y = desc.y + desc.height + 10;

		statsTitle.x = tabBg.width / 2 - statsTitle.textWidth / 2;
		statsTitle.y = line1.y + 20;

		line2.x = line1.x;
		line2.y = statsTitle.y + 50;

		stats.y = line2.y + 20;

		var joinDate = ShitUtil.parseISODate(user.joined);
		stats.setText("Rank: " + ShitUtil.toOrdinalNumber(user.rank) + '\n' + "Points: " + FlxStringUtil.formatMoney(user.points, false) + "FP\n" + "Avg. Accuracy: "
			+ FlxMath.roundDecimal((user.avgAccuracy * 100), 2) + "%\n" + "Joined: " + joinDate.getDate() + '/' + (joinDate.getMonth() + 1) + '/'
			+ (joinDate.getFullYear() + '').substr(2) + "\n\n");
		removeFriend.visible = user.friends.contains(FunkinNetwork.nickname);
		addFriend.visible = !removeFriend.visible && user.canFriend;
		invitePlay.visible = removeFriend.visible;

		settings.visible = username == FunkinNetwork.nickname;
		web.visible = username != FunkinNetwork.nickname;
		if (settings.visible) {
			addFriend.visible = false;
			invitePlay.visible = false;
		}
    }

	function updateUsernameText() {
		usernameTxt.setText(username, 150 + (!flag.visible ? 65 : 0));
		flag.x = usernameTxt.x + usernameTxt.width + 20;
		flag.y = avatar.y + 10 + 5;
		usernameTxt.y = avatar.y + 10 + (40 / 2) - (40 * usernameTxt.scaleY) / 2;
	}

	override function __enterFrame(delta) {
		super.__enterFrame(delta);

		invitePlay.alpha = GameClient.isConnected() ? 1.0 : 0.5;
	}

	function loadFlag(loadingUser:String, country:String, ?retry:Bool = false) {
		var flagResponse = !retry ? flagCDN.request({
			path: "h24/" + country.toLowerCase() + ".png",
		}) : flagsAPI.request({
			path: country + "/flat/24.png",
		});

		if (!flagResponse.isFailed()) {
			Waiter.putPersist(() -> {
				if (flag != null && loadingUser == username) {
					flag.visible = true;
					flag.bitmapData = BitmapData.fromBytes(flagResponse.getBytes());
					updateUsernameText();
				}
			});
		}
		else if (!retry) {
			loadFlag(loadingUser, country, true);
		}
	}
}

typedef UserDetailsData = {
	var role:String;
	var joined:String;
	var lastActive:String;
	var points:Float;
	var isSelf:Bool;
	var bio:String;
	var friends:Array<String>;
	var canFriend:Bool;
	var profileHue:Int;
	var avgAccuracy:Float;
	var rank:Float;
	var country:String;
}