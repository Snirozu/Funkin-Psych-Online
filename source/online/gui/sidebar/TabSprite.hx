package online.gui.sidebar;

@:allow(online.gui.sidebar.SideUI)
class TabSprite extends Sprite {
	public var widthTab:Float = 0;

	public function new(width:Float) {
		super();

		widthTab = width;

		if (stage != null)
			_init();
		else
			addEventListener(Event.ADDED_TO_STAGE, _init);
	}

	public static inline function getDefaultFormat() {
		return new TextFormat(Assets.getFont('assets/fonts/vcr.ttf').fontName, 15, 0xFFFFFFFF);
	}

	var initialized:Bool = false;
	function _init(?e):Void {
		if (!initialized)
			create();
		init();

		initialized = true;
	}
	function create():Void {}
	function init():Void {}
	function onShow():Void {}
	function onHide():Void {}

	function keyDown(event:KeyboardEvent):Void {}
	function mouseDown(e:MouseEvent):Void {}
	function mouseMove(e:MouseEvent):Void {}
	function mouseWheel(e:MouseEvent):Void {}
}