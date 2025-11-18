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
			_init();
		else
			addEventListener(Event.ADDED_TO_STAGE, _init);
	}

	public static inline function getDefaultFormat() {
		return new TextFormat(Assets.getFont('assets/fonts/vcr.ttf').fontName, 18, 0xFFFFFFFF);
	}

	var initialized:Bool = false;
	function _init(?e):Void {
		if (!initialized) {
			initialized = true;

			tabBg = new Bitmap(new BitmapData(tabWidth, heightSpace, true, FlxColor.fromRGB(10, 10, 10)));
			tabBg.alpha = 0.95;
			addChild(tabBg);

			create();
		}
		init();
	}
	function create():Void {}
	function init():Void {}
	function onShow():Void {
		scrollRect.x = 0;
		scrollRect.y = 0;
	}
	function onRemove():Void {}
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