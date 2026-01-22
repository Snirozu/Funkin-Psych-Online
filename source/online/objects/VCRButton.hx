package online.objects;

import flixel.util.FlxSpriteUtil;

class VCRButton extends FlxSpriteGroup {
	var label:FlxText;
	var bg:FlxSprite;
	var borderline:FlxSprite;

    var selected = false;

	var callback:Void->Void;

    public function new(text:String, callback:Void->Void, ?size:Int = 25, ?x:Float = 0, ?y:Float = 0) {
        super(x, y);
        
		this.callback = callback;

		label = new FlxText(10, 10);
		label.setFormat("VCR OSD Mono", size, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		label.text = text;
		add(label);

        bg = new FlxSprite();
		bg.makeGraphic(Std.int(label.width + 20), Std.int(label.height + 20), 0x93000000);
		add(bg);

		borderline = new FlxSprite();
		borderline.makeGraphic(bg.frameWidth, bg.frameHeight, FlxColor.TRANSPARENT);
		FlxSpriteUtil.drawRect(borderline, 0, 0, borderline.width, borderline.height, FlxColor.TRANSPARENT, {thickness: 6, color: 0x5BFFFFFF});
        add(borderline);
    }

    override function update(elapsed) {
        super.update(elapsed);

		if (FlxG.mouse.deltaX != 0 || FlxG.mouse.deltaY != 0) {
			selected = FlxG.mouse.overlaps(this, camera);
        }

        if (selected && FlxG.mouse.justPressed) {
			if (callback != null)
				callback();
        }

        borderline.alpha = selected ? 1 : 0.6;
    }
}