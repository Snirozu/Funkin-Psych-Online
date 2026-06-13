package mobile.openfl.controls;

class DPad extends InputHandler {
	public var controlIDs:Array<String> = [];

	public function new(data:Dynamic) {
		super(data.position != null ? data.position[0] : 0, data.position != null ? data.position[1] : 0, data.showbounds);
		controlIDs = data.id;
		loadElementGraphics(data.graphic, data.subgraphic, data.spritesheet, MobileControls.DPAD_PATH, data.color, data.scale != null ? data.scale : 1.0);

		var bW = baseGraphic.scrollRect != null ? baseGraphic.scrollRect.width : baseGraphic.bitmapData.width;
		var bH = baseGraphic.scrollRect != null ? baseGraphic.scrollRect.height : baseGraphic.bitmapData.height;
		var relMidX = (bW * baseScale) / 2;
		var relMidY = (bH * baseScale) / 2;

		if (data.clickposition != null && data.clickbound != null) {
			for (i in 0...controlIDs.length) {
				var cPos:Array<Float> = data.clickposition[i];
				var cBnd:Array<Int> = data.clickbound[i];

				var relBoundX = relMidX + (cPos[0] * baseScale) - ((cBnd[0] * baseScale) / 2);
				var relBoundY = relMidY + (cPos[1] * baseScale) - ((cBnd[1] * baseScale) / 2);

				createBoundHitbox(relBoundX, relBoundY, cBnd[0] * baseScale, cBnd[1] * baseScale);
			}
		}
	}

	override public function updateInputs(pointers:Map<Int, MobileControls.Pointer>) {
		if (disabled)
			return;
		super.updateInputs(pointers);

		var anyPressed = false;
		for (i in 0...hitboxes.length) {
			var box = hitboxes[i];
			var isPressed = checkOverlap(box, pointers);

			if (isPressed) {
				activeIDs.push(controlIDs[i]);
				anyPressed = true;
			}
			updateBoundBrightness(box, isPressed);
		}
		applyBrightness(anyPressed);
	}
}
