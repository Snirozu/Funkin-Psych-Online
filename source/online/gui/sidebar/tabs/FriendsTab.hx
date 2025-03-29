package online.gui.sidebar.tabs;

import openfl.geom.Rectangle;
import online.gui.sidebar.obj.TabSprite.ITabInteractable;

class FriendsTab extends TabSprite {

	var data:FriendsResponseData;

	var loading(default, set):Bool = false;
	var loadingTxt:TextField;

	var friendsTxt:TextField;
	var requestsTxt:TextField;
	var pendingTxt:TextField;

	var trashedProfiles:Array<SmolProfile> = [];
	var friendsList:Array<SmolProfile> = [];

	var realHeight:Float = 0;

    public function new() {
        super('Friends', 'friends');
    }

    override function create() {
        super.create();

		scrollRect = new Rectangle(0, 0, tabWidth, heightSpace);

		loadingTxt = this.createText(20, 20, 40);
		loadingTxt.setText('Fetching...');
		loadingTxt.visible = false;
		addChild(loadingTxt);

		friendsTxt = this.createText(0, 0, 25, FlxColor.WHITE);
		friendsTxt.setText('My Friends');
		friendsTxt.x = tabWidth / 2 - friendsTxt.width / 2;
		friendsTxt.y = 10;
		addChild(friendsTxt);

		requestsTxt = this.createText(0, 0, 25, FlxColor.WHITE);
		requestsTxt.setText('Incoming Friend Invites');
		requestsTxt.x = tabWidth / 2 - requestsTxt.width / 2;
		addChild(requestsTxt);

		pendingTxt = this.createText(0, 0, 25, FlxColor.WHITE);
		pendingTxt.setText('Pending Friend Invites from You');
		pendingTxt.x = tabWidth / 2 - pendingTxt.width / 2;
		addChild(pendingTxt);
    }

	function renderData() {
		for (profile in friendsList) {
			trashedProfiles.push(profile);
			removeChild(profile);
		}
		friendsList = [];

		data.friends.sort((a, b) -> {
			if (a.status == b.status)
				return 0;
			return a.status.toLowerCase() != 'offline' ? -1 : 1;
		});
		
		for (i => friend in data.friends) {
			var profile = trashedProfiles.length > 0 ? trashedProfiles.pop() : new SmolProfile();
			profile.create(friend);
			profile.y = i * profile.height + friendsTxt.getTextHeight() + 20;
			friendsList.push(profile);
			addChild(profile);
		}
		
		var lastProfile = friendsList[friendsList.length - 1];
		requestsTxt.y = lastProfile.y + lastProfile.height;

		for (i => name in data.requests) {
			var profile = trashedProfiles.length > 0 ? trashedProfiles.pop() : new SmolProfile();
			profile.create({
				name: name,
				isNotFriend: true,
				canFriend: true
			});
			profile.y = i * profile.height + requestsTxt.y + 30;
			friendsList.push(profile);
			addChild(profile);
		}

		lastProfile = friendsList[friendsList.length - 1];
		pendingTxt.y = lastProfile.y + lastProfile.height;

		for (i => name in data.pending) {
			var profile = trashedProfiles.length > 0 ? trashedProfiles.pop() : new SmolProfile();
			profile.create({
				name: name,
				isNotFriend: true
			});
			profile.y = i * profile.height + pendingTxt.y + 30;
			friendsList.push(profile);
			addChild(profile);
		}

		lastProfile = friendsList[friendsList.length - 1];
		
		pendingTxt.visible = data.pending.length > 0;
		requestsTxt.visible = data.requests.length > 0;

		tabBg.bitmapData = new BitmapData(tabWidth, Std.int(height), true, FlxColor.fromRGB(10, 10, 10));

		realHeight = this.getRealHeight();
	}

	override function onShow() {
		super.onShow();

		loadData();
	}

    function loadData() {
        loading = true;
		Thread.run(() -> {
			var response = FunkinNetwork.requestAPI('/api/account/friends');

			if (response != null && !response.isFailed()) {
				Waiter.put(() -> {
					loading = false;
					data = Json.parse(response.getString());
					renderData();
				});
			}
		});
    }

	function set_loading(v:Bool) {
		for (child in __children) {
			child.visible = !v;
		}
		tabBg.visible = true;
		loadingTxt.visible = v;
		return loading = v;
	}

	override function mouseWheel(e:MouseEvent):Void {
		super.mouseWheel(e);

		autoScroll(e.delta);
	}

	function autoScroll(?scrollDelta:Float = 0) {
		var rect = scrollRect;
		rect.y -= scrollDelta * 40;
		if (rect.y <= 0)
			rect.y = 0;
		if (rect.y + rect.height >= realHeight)
			rect.y = realHeight - rect.height;
		scrollRect = rect;
	}
}

class SmolProfile extends Sprite implements ITabInteractable {
	public var icon:Bitmap;
	public var nick:TextField;
	public var status:TextField;
	public var invitePlay:TabButton;
	public var addFriend:TabButton;
	public var viewProfile:TabButton;
	public var underlay:Bitmap;

    public function new() {
        super();

		underlay = new Bitmap(new BitmapData(SideUI.DEFAULT_TAB_WIDTH, 100, true, FlxColor.fromHSL(0, 0.2, 0.3)));
		addChild(underlay);

		icon = new Bitmap(new BitmapData(80, 80, true, 0x00000000));
		icon.smoothing = false;
		icon.x = 10;
		icon.y = 10;
		addChild(icon);

		nick = this.createText(icon.width + 20, 20, 22);
		addChild(nick);

		status = this.createText(nick.x, nick.y + 30, 18);
		addChild(status);

		invitePlay = new TabButton('invite', () -> {});
		invitePlay.x = underlay.width - invitePlay.width - 20;
		invitePlay.y = underlay.height / 2 - invitePlay.height / 2;
		addChild(invitePlay);

		addFriend = new TabButton('add_friend', () -> {});
		addFriend.x = underlay.width - invitePlay.width - 20;
		addFriend.y = underlay.height / 2 - invitePlay.height / 2;
		addChild(addFriend);

		viewProfile = new TabButton('profile', () -> {});
		viewProfile.x = invitePlay.x - viewProfile.width - 10;
		viewProfile.y = underlay.height / 2 - viewProfile.height / 2;
		addChild(viewProfile);

		updateVisual();
    }

	public function create(data:FriendData) {
		underlay.bitmapData = new BitmapData(SideUI.DEFAULT_TAB_WIDTH, 100, true, FlxColor.fromHSL(data.hue, 0.2, 0.3));
		icon.bitmapData = new BitmapData(80, 80, true, 0x00000000);

		status.visible = !data.isNotFriend;
		invitePlay.visible = !data.isNotFriend;
		addFriend.visible = data.isNotFriend && data.canFriend;

		nick.setText(data.name, 140);
		status.setText(data.status, 140);

		var statusFormat = status.defaultTextFormat;
		if (data.status.toLowerCase() != "offline") {
			statusFormat.color = FlxColor.LIME;
		}
		else {
			statusFormat.color = FlxColor.GRAY;
		}
		status.defaultTextFormat = statusFormat;

		invitePlay.onClick = () -> {
			Util.inviteToPlay(data.name);
		}
		viewProfile.onClick = () -> {
			ProfileTab.view(data.name);
		}
		addFriend.onClick = () -> {
			LoadingScreen.toggle(true);

			var daUsername = data.name;
			Thread.run(() -> {
				var response = FunkinNetwork.requestAPI('/api/user/friends/request?name=' + StringTools.urlEncode(daUsername));

				LoadingScreen.toggle(false);
			});
		}

		Thread.run(() -> {
			var avatarData = FunkinNetwork.getUserAvatar(data.name);

			Waiter.put(() -> {
				if (avatarData != null) {
					icon.bitmapData = avatarData;
					icon.width = 80;
					icon.height = 80;
				}
			});
		});
	}

	override function __enterFrame(delta) {
		super.__enterFrame(delta);

		invitePlay.alpha = GameClient.isConnected() ? 1.0 : 0.5;
	}

	private function mouseDown(event:MouseEvent) {}
	private function mouseMove(event:MouseEvent) {
		updateVisual();
    }

    function updateVisual() {
		underlay.alpha = 0.3;
		if (this.overlapsMouse()) {
			underlay.alpha = 0.6;
		}
    }

	private function keyDown(event:KeyboardEvent) {};
	private function mouseWheel(event:MouseEvent) {};
}

typedef FriendsResponseData = {
	var friends:Array<FriendData>;
	var pending:Array<String>; // list of requests the player has sent to other players
	var requests:Array<String>; // requests to be ignored or accepted
}

typedef FriendData = {
	var name:String;
	var ?status:String;
	var ?hue:Int;
	var ?isNotFriend:Bool;
	var ?canFriend:Bool;
}