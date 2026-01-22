package online.gui.sidebar.obj;

import openfl.display.DisplayObject;

@:allow(online.gui.sidebar.SideUI)
class TabSprite extends Sprite {
	public var title:String;
	public var icon:String;

	public var tabWidth(get, default):Null<Int>;
	function get_tabWidth() {
		return tabWidth ?? SideUI.DEFAULT_TAB_WIDTH;
	}

	public var widthSpace:Int;
	public var heightSpace:Int;

	public var tabBg:Bitmap;

	public function new(title:String, icon:String, ?tabWidth:Null<Int> = null) {
		super();

		this.title = title;
		this.icon = icon;
		this.tabWidth = tabWidth;

		if (stage != null)
			_addedToStage();
		else
			addEventListener(Event.ADDED_TO_STAGE, _addedToStage);
	}

	public static inline function getDefaultFormat() {
		return new TextFormat(Assets.getFont('assets/fonts/vcr.ttf').fontName, 18, 0xFFFFFFFF);
	}

	var initialized:Bool = false;
	function _addedToStage(?e):Void {
		if (!initialized) {
			initialized = true;

			tabBg = new Bitmap(new BitmapData(tabWidth, heightSpace, true, FlxColor.fromRGB(10, 10, 10)));
			tabBg.alpha = 0.95;
			addChild(tabBg);

			create();
		}
		addedToStage();
	}
	/**
	 * Called when this tab gets added to the sidebar stage, only the first time
	 */
	function create():Void {}
	/**
	 * Called when this tab gets added to the sidebar stage
	 */
	function addedToStage():Void {}
	/**
	 * Called when this tab gets refreshed, or when the sidebar gets shown.
	 */
	function onShow():Void {
		if (scrollRect != null) {
			var rect = scrollRect;
			rect.x = 0;
			rect.y = 0;
			scrollRect = rect;
		}
	}
	/**
	 * Always called after `onShow()`
	 */
	function onShowOnline():Void {}
	/**
	 * Always called after `onShow()`
	 */
	function onShowOffline():Void {}
	/**
	 * Called after this tab gets removed from the stage, and after `onHide()`
	 */
	function onRemove():Void {}
	/**
	 * Called when this tab gets either changed or refreshed, or when the sidebar gets hidden.
	 */
	function onHide():Void {};

	function keyDown(e:KeyboardEvent):Void {
		iterateTabChildren(child -> child.keyDown(e));
	}
	function mouseDown(e:MouseEvent):Void {
		iterateTabChildren(child -> child.mouseDown(e));
	}
	function mouseMove(e:MouseEvent):Void {
		iterateTabChildren(child -> child.mouseMove(e));
	}
	function mouseWheel(e:MouseEvent):Void {
		iterateTabChildren(child -> child.mouseWheel(e));
	}

	function iterateTabChildren(task:ITabInteractable->Void, ?object:DisplayObject) {
		if (object == null)
			object = this;

		// this field has no reason to be private?
		for (child in @:privateAccess object.__children) {
			if (child is ITabInteractable)
				task(cast child);
			if (child.__children != null)
				iterateTabChildren(task, child);
		}
	}
}

@:allow(online.gui.sidebar.obj.TabSprite)
interface ITabInteractable {
	private function keyDown(event:KeyboardEvent):Void;
	private function mouseDown(event:MouseEvent):Void;
	private function mouseMove(event:MouseEvent):Void;
	private function mouseWheel(event:MouseEvent):Void;
}