package online.gui.sidebar;

import backend.InputFormatter;
import flixel.input.keyboard.FlxKey;
import sys.FileSystem;
import online.gui.sidebar.tabs.*;
import online.gui.sidebar.obj.*;
import online.network.FunkinNetwork;
import flixel.FlxG;
import flixel.util.FlxColor;
import openfl.Lib;

class SideUI extends WSprite {
	public static var instance:SideUI;

	public var active(default, set):Bool;
	public var cursor:Bitmap;

	public static final DEFAULT_TAB_WIDTH:Int = 400;

	public var initTabs:Array<Class<TabSprite>> = [
		NotificationsTab,
		ProfileTab,
		FriendsTab,
		ChatTab,
		#if !mobile HostServerTab #end,
		// TODO 
		// DownloaderTab,
		// ReportTab,
		// ServerTab
		// DebugTab
	];

	public var tabUI:Sprite;

	public var upBar:Bitmap;
	public var leftBar:Bitmap;
	public var welcome:TextField;
	public var tip:TextField;
	public var tabTitle:TextField;

	var tabButtons:Array<Bitmap> = [];
	var tabButtonsUnderlay:Array<Bitmap> = [];

	public var tabs:Array<TabSprite> = [];
	public var curTabIndex(default, set):Int;
	function set_curTabIndex(v:Int) {
		if (curTab != null) {
			curTab.onHide();
			tabUI.removeChild(curTab);
			curTab.onRemove();
		}

		curTabIndex = v;

		if (active) {
			tabUI.addChild(curTab);
			curTab.onShow();
		}

		onChangedTab();

		return curTabIndex;
	}
	public var curTab(get, never):TabSprite;
	function get_curTab() {
		return tabs[curTabIndex];
	}

	var _wasMouseShown:Bool = false;

	public function new() {
		super();

		instance = this;

		for (file in FileSystem.readDirectory('assets/images/sidebar')) {
			Paths.excludeAsset('assets/images/sidebar/' + file);
		}

		if (stage != null)
			init();
		else
			addEventListener(Event.ADDED_TO_STAGE, init);
	}

	function init(?e:Event) {
		alpha = 0;

		var bg = new Bitmap(new BitmapData(Lib.application.window.width, Lib.application.window.height, true, 0x8E000000));
		addChild(bg);

		tabUI = new Sprite();
		addChild(tabUI);

		leftBar = new Bitmap(new BitmapData(50, Lib.application.window.height, true, FlxColor.fromRGB(30, 30, 30)));
		tabUI.addChild(leftBar);
		
		upBar = new Bitmap(new BitmapData(Lib.application.window.width, 50, true, FlxColor.BLACK));
		addChild(upBar);

		welcome = this.createText(15, 15, 20);
		welcome.setText('...');
		addChild(welcome);

		tip = this.createText(15, 15, 15);
		tip.setText('Use ' + InputFormatter.getKeyName(cast(ClientPrefs.keyBinds.get('sidebar')[0], FlxKey)) + ' to toggle the Network Sidebar!', upBar.width, 0xFF535353);
		tip.x = upBar.width / 2 - tip.width / 2;
		tip.y = welcome.y;
		addChild(tip);

		tabTitle = this.createText(15, 15, 20);
		addChild(tabTitle);

		cursor = new Bitmap(new GraphicCursor(0, 0));
		cursor.visible = false;
		stage.addChild(cursor);

		for (i => tabClass in initTabs) {
			var daTab = Type.createInstance(tabClass, []);
			daTab.x = leftBar.width;
			daTab.y = upBar.height;
			daTab.widthSpace = Std.int(Lib.application.window.width - daTab.x);
			daTab.heightSpace = Std.int(Lib.application.window.height - daTab.y);
			tabs.push(daTab);
			
			var tabIconUnderlay = new Bitmap(new BitmapData(50, 50, true, FlxColor.fromRGB(100, 100, 100)));
			tabIconUnderlay.y = upBar.height + i * 50;
			tabButtonsUnderlay.push(tabIconUnderlay);
			tabUI.addChild(tabIconUnderlay);

			var tabIcon = new Bitmap(GAssets.image('sidebar/' + daTab.icon));
			tabIcon.smoothing = false;
			tabIcon.width = 50;
			tabIcon.height = 50;
			tabIcon.y = tabIconUnderlay.y;
			tabButtons.push(tabIcon);
			tabUI.addChild(tabIcon);
		}

		tabUI.x = -totalTabWidth();

		onChangedTab();

		stage.addEventListener(KeyboardEvent.KEY_DOWN, (e:KeyboardEvent) -> {
			if (LoadingScreen.loading)
				return;

			if ((e.keyCode.checkKey('sidebar') || (e.keyCode == 27 && active)) && stage.focus == null) {
				active = !active;
				// if (FunkinNetwork.loggedIn) {
				// 	active = !active;
				// 	return;
				// }
				// else {
				// 	Waiter.put(() -> {
				// 		Alert.alert("Forbidden!", "Sidebar is only accessible for\npeople that are logged to the network!");
				// 	});
				// }
			}
			
			if (active) {
				curTab.keyDown(e);

				if (e.keyCode == Keyboard.F1) {
					trace("reloading syncscript!");
					online.backend.SyncScript.initScript();
				}
			}
		});
		stage.addEventListener(MouseEvent.MOUSE_MOVE, (e:MouseEvent) -> {
			cursor.x = e.stageX;
			cursor.y = e.stageY;

			if (LoadingScreen.loading)
				return;

			if (active) {
				onChangedTab();
				curTab.mouseMove(e);
			}
		});
		stage.addEventListener(MouseEvent.MOUSE_DOWN, (e:MouseEvent) -> {
			if (LoadingScreen.loading)
				return;

			if (e.localY > upBar.height * scaleY && e.localX > totalTabWidth() * scaleX && !Alert.isAnyFreezed())
				active = false;

			if (active) {
				for (i => button in tabButtons) {
					if (tabButtonsUnderlay[i].overlapsMouse()) {
						curTabIndex = i;
						break;
					}
				}
				curTab.mouseDown(e);
			}
		});
		stage.addEventListener(MouseEvent.MOUSE_WHEEL, (e:MouseEvent) -> {
			if (LoadingScreen.loading)
				return;

			if (active)
				curTab.mouseWheel(e);
		});
	}

	function onChangedTab() {
		tabTitle.setText(curTab.title, upBar.width);
		tabTitle.x = 20;
		tabTitle.y = upBar.height / 2 - tabTitle.getTextHeight() / 2 - 5;

		for (i => tile in tabButtonsUnderlay) {
			tile.alpha = 0.2;
			if (tile.overlapsMouse())
				tile.alpha = 0.5;
			if (curTabIndex == i)
				tile.alpha = 1;
		}
	}

	function set_active(show:Bool) {
		if (show == active)
			return active;

		active = show;

		stage.focus = null;
		Actuate.stop(this);
		Actuate.stop(tabUI);
		Actuate.stop(upBar);

		FlxG.mouse.enabled = !active;
		FlxG.keys.enabled = !active;
		cursor.visible = active;

		function onOnline() {
			if (!active)
				return;

			welcome.setText('Logged as ${FunkinNetwork.nickname}', upBar.width);
			welcome.x = upBar.width - welcome.width - 50;
			welcome.y = upBar.height / 2 - welcome.getTextHeight() / 2 - 5;

			tip.x = upBar.width / 2 - tip.width / 2;
			tip.y = welcome.y;

			curTab.onShowOnline();
		}

		function onOffline() {
			if (!active)
				return;

			welcome.setText('Not logged in', upBar.width);
			welcome.x = upBar.width - welcome.width - 50;
			welcome.y = upBar.height / 2 - welcome.getTextHeight() / 2 - 5;

			tip.y = welcome.y;

			curTab.onShowOffline();
		}

		if (active) {
			tabUI.addChild(curTab);
			curTab.onShow();
			_wasMouseShown = FlxG.mouse.visible;
			FlxG.mouse.visible = false;

			if (!FunkinNetwork.loggedIn)
				Thread.run(() -> {
					FunkinNetwork.ping();

					if (FunkinNetwork.loggedIn)
						Waiter.putPersist(onOnline);
					else
						Waiter.putPersist(onOffline);
				});
			else
				onOnline();

			Actuate.tween(this, 0.5, {alpha: 1});
			Actuate.tween(upBar, 0.2, {y: 0}).onComplete(() -> {
				Actuate.tween(tabUI, 0.2, {x: 0});
			});
		}
		else {
			FlxG.mouse.visible = _wasMouseShown;

			curTab.onHide();

			Actuate.tween(this, 0.5, {alpha: 0}).onComplete(() -> {
				tabUI.removeChild(curTab);
				curTab.onRemove();
			});
			Actuate.tween(tabUI, 0.3, {x: -totalTabWidth()}).onComplete(() -> {
				Actuate.tween(upBar, 0.2, {y: -upBar.height});
			});
		}
		return active;
	}

	function totalTabWidth() {
		return leftBar.width + (curTab?.tabWidth ?? DEFAULT_TAB_WIDTH);
	}
}

@:bitmap("assets/images/ui/cursor.png")
private class GraphicCursor extends BitmapData {}
