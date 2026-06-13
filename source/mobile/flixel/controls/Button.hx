package mobile.flixel.controls;

#if flixel
class Button extends InputHandler {
	public var controlID:String;

	public function new(data:Dynamic) {
		var posX:Float = data.position != null ? data.position[0] : 0;
		var posY:Float = data.position != null ? data.position[1] : 0;
		super(posX, posY, false);
		name = data.name;

		controlID = data.id;
		var scale:Float = data.scale != null ? data.scale : 1.0;

		loadElementGraphics(data.graphic, data.subgraphic, data.spritesheet, MobileControls.BUTTON_PATH, data.color, scale);
	}

	override public function updateInputs() {
		if (checkOverlap(baseGraphic)) {
			activeIDs.push(controlID);
		}

		applyBrightness(activeIDs.length > 0);
	}
}
#end