package mobile.openfl.controls;

class Button extends InputHandler {
	public var controlID:String;

	public function new(data:Dynamic) {
		super(data.position != null ? data.position[0] : 0, data.position != null ? data.position[1] : 0, false);
		controlID = data.id;
		loadElementGraphics(data.graphic, data.subgraphic, data.spritesheet, MobileControls.BUTTON_PATH, data.color, data.scale != null ? data.scale : 1.0);
	}

	override public function updateInputs(pointers:Map<Int, MobileControls.Pointer>) {
		if (disabled)
			return;

		super.updateInputs(pointers);

		var isHit = false;
		for (p in pointers) {
			if (p.isDown && this.hitTestPoint(p.x, p.y, true)) {
				isHit = true;
				break;
			}
		}

		if (isHit)
			activeIDs.push(controlID);
		applyBrightness(activeIDs.length > 0);
	}
}
