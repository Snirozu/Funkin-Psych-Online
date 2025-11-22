package online.gui.sidebar.tabs;

import haxe.ds.Either;
import com.yagp.GifDecoder;
import com.yagp.GifPlayer;
import com.yagp.GifPlayerWrapper;
import openfl.geom.Rectangle;
import online.gui.sidebar.obj.TabSprite.ITabInteractable;

class NotificationsTab extends TabSprite {

	var data:Array<NotificationData>;

	var loading(default, set):Bool = false;
	var loadingTxt:TextField;

	var trashedNotifs:Array<Notification> = [];
	var notifsList:Array<Notification> = [];

	var realHeight:Float = 0;

    public function new() {
        super('Notifications', 'notif');
    }

    override function create() {
        super.create();

		scrollRect = new Rectangle(0, 0, tabWidth, heightSpace);

		loadingTxt = this.createText(20, 20, 40);
		loadingTxt.setText('Fetching...');
		loadingTxt.visible = false;
		addChild(loadingTxt);
    }

	function renderData() {
		for (notif in notifsList) {
			notif.isAction = false;
			trashedNotifs.push(notif);
			removeChild(notif);
		}
		notifsList = [];

		if (data.length == 0) {
			loadingTxt.setText('None...');
			loadingTxt.visible = true;
			return;
		}

		var nextY = 0.0;
		for (i => notifData in data) {
			var notif = trashedNotifs.length > 0 ? trashedNotifs.pop() : new Notification();
			notif.create(notifData);
			notif.y = Std.int(nextY);
			nextY += notif.height;
			notifsList.push(notif);
			addChild(notif);
		}

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
			var response = FunkinNetwork.requestAPI('/api/account/notifications');

			if (response != null && !response.isFailed()) {
				Waiter.putPersist(() -> {
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
		loadingTxt.setText('Fetching...');
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
		if (realHeight > rect.height) {
			if (rect.y + rect.height - y >= realHeight)
				rect.y = realHeight - rect.height + y;
		}
		else {
			rect.y = 0;
		}
		scrollRect = rect;
	}
}

class Notification extends Sprite implements ITabInteractable {
	public var icon:Bitmap;
	public var title:TextField;
	public var desc:TextField;
	public var underlay:Bitmap;
	var remove:TabButton;
	var view:TabButton;
	public var isAction(default, set):Bool = false;
	var _actionTime:Float = 0;

	function set_isAction(v) {
		_actionTime = 0;
		title.visible = !v;
		desc.visible = !v;
		remove.visible = v;
		view.visible = v;
		return isAction = v;
	}

    public function new() {
        super();

		underlay = new Bitmap(new BitmapData(SideUI.DEFAULT_TAB_WIDTH, 100, true, FlxColor.fromHSL(0, 0.2, 0.3)));
		addChild(underlay);

		icon = new Bitmap(new BitmapData(1, 1, true, FlxColor.TRANSPARENT));
		icon.smoothing = true;
		icon.width = 80;
		icon.height = 80;
		icon.x = 10;
		icon.y = 10;
		addChild(icon);

		title = this.createText(icon.width + 20, 20, 22);
		title.wordWrap = true;
		title.multiline = true;
		title.width = SideUI.instance.curTab.tabWidth - title.x - 20;
		addChild(title);

		desc = this.createText(title.x, title.y + 30, 18);
		desc.wordWrap = true;
		desc.multiline = true;
		desc.width = SideUI.instance.curTab.tabWidth - desc.x - 20;
		addChild(desc);

		remove = new TabButton('cancel', () -> {
			if (_actionTime < 0.1)
				return;

			FunkinNetwork.requestAPI('/api/account/notifications/delete/' + data.id);
			SideUI.instance.curTabIndex = SideUI.instance.curTabIndex;
		});
		remove.x = underlay.width - remove.width - 20;
		remove.y = underlay.height / 2 - remove.height / 2;
		addChild(remove);

		view = new TabButton('internet', () -> {
			if (_actionTime < 0.1)
				return;
			
			var url = data.href.startsWith('/') ? FunkinNetwork.client.getURL(data.href) : data.href;
			FlxG.openURL(url);
		});
		view.x = remove.x - view.width - 10;
		view.y = underlay.height / 2 - view.height / 2;
		addChild(view);

		isAction = isAction;

		updateVisual();
    }

	var data:NotificationData;
	public function create(data:NotificationData) {
		this.data = data;

		title.text = (data.title);
		desc.text = (data.content);

		underlay.bitmapData = new BitmapData(SideUI.DEFAULT_TAB_WIDTH, Std.int(Math.max(100, desc.y + desc.textHeight + 20)), true, FlxColor.fromHSL(0, 0.2, 0.3));

		Thread.run(() -> {
			var url = data.image.startsWith('/') ? FunkinNetwork.client.getURL(data.image) : data.image;
			var imgData = ShitUtil.fetchBitmapBytesfromURL(url);

			Waiter.putPersist(() -> {
				var prevIcon = icon;
				var iconData:Either<BitmapData, com.yagp.Gif>;

				if (imgData == null)
					iconData = Left(FunkinNetwork.getDefaultAvatar());
				else if (!ShitUtil.isGIF(imgData))
					iconData = Left(BitmapData.fromBytes(imgData));
				else
					iconData = Right(GifDecoder.parseBytes(imgData));

				switch (iconData) {
					case Left(v):
						icon = new Bitmap(v);
					case Right(v):
						icon = new GifPlayerWrapper(new GifPlayer(v));
					default:
				}


				addChildAt(icon, getChildIndex(prevIcon));
				removeChild(prevIcon);

				icon.x = 10;
				icon.y =  10;
				icon.width = 80;
				icon.height = 80;
			});
		});
	}

	override function __enterFrame(delta) {
		super.__enterFrame(delta);

		if (isAction) {
			_actionTime += delta / 1000;
		}
	}

	private function mouseDown(event:MouseEvent) {
		if (this.overlapsMouse() && !remove.overlapsMouse() && !view.overlapsMouse()) {
			isAction = !isAction;
		}
	}
	private function mouseMove(event:MouseEvent) {
		updateVisual();

		if (isAction && !this.overlapsMouse()) {
			isAction = false;
		}
    }

    function updateVisual() {
		underlay.alpha = 0.3;
		if (this.overlapsMouse()) {
			underlay.alpha = 0.8;
		}
    }

	private function keyDown(event:KeyboardEvent) {};
	private function mouseWheel(event:MouseEvent) {};
}

typedef NotificationData = {
	var id:String;
	var date:String;
	var title:String;
	var content:String;
	var image:String;
	var href:String;
}