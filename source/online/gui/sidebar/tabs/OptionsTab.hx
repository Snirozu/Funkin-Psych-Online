package online.gui.sidebar.tabs;

class OptionsTab extends TabSprite {
	public function new() {
		super('Options', 'wheel');
	}

	override function create() {
		super.create();

		var title = this.createText(0, 0, 20, FlxColor.WHITE);
		title.setText('Options Test');
		addChild(title);
	}
}