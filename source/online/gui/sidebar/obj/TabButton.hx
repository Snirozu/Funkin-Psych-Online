package online.gui.sidebar.obj;

import online.gui.sidebar.obj.TabSprite.ITabInteractable;

class TabButton extends Sprite implements ITabInteractable {

	public var onClick:Void->Void;

	public var icon:Bitmap;
	public var underlay:Bitmap;
	public var border:Bitmap;

    public function new(daIcon:String, onClick:Void->Void) {
        super();

		this.onClick = onClick;

		border = new Bitmap(Paths.image('sidebar/button_border', null, false).bitmap);
		border.smoothing = false;
		border.width = 56;
		border.height = 56;

		icon = new Bitmap(Paths.image('sidebar/' + daIcon, null, false).bitmap);
		icon.smoothing = false;
		icon.x = 3;
		icon.y = 3;
		icon.width = 50;
		icon.height = 50;

		underlay = new Bitmap(new BitmapData(50, 50, true, FlxColor.fromRGB(100, 100, 100)));
		underlay.x = icon.x;
		underlay.y = icon.y;

		addChild(underlay);
		addChild(icon);
		addChild(border);

		updateVisual();
    }

	private function mouseDown(event:MouseEvent) {
		if (this.overlapsMouse()) {
			onClick();
		}
    }
	private function mouseMove(event:MouseEvent) {
		updateVisual();
    }

    function updateVisual() {
		underlay.alpha = 0.4;
		border.alpha = 0.4;
		if (this.overlapsMouse()) {
			underlay.alpha = 1;
			border.alpha = 1;
		}
    }

	private function keyDown(event:KeyboardEvent) {};
	private function mouseWheel(event:MouseEvent) {};
}