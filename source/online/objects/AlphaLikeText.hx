package online.objects;

import flixel.math.FlxPoint;

class AlphaLikeText extends FlxText implements Scrollable {
	public var targetY:Int = 0;
	public var distancePerItem:FlxPoint = new FlxPoint(20, 120);
	public var startPosition:FlxPoint = new FlxPoint(0, 0); // for the calculations
	public var isMenuItem:Bool = true;
	public var scaleX(default, set):Float = 1;
	public var scaleY(default, set):Float = 1;
	public var changeX:Bool = true;
	public var changeY:Bool = true;

	public function new(x:Float, y:Float, text:String = "") {
		super(x, y);

		this.startPosition.x = x;
		this.startPosition.y = y;
		this.offset.x = 5;
		this.text = " " + text + "\n "; //space because border cuts at the start and at the bottom
		this.setFormat('Pixel Arial 11 Bold', 40, FlxColor.WHITE, LEFT);
        this.setBorderStyle(OUTLINE, FlxColor.BLACK, 6);
	}

	override function update(elapsed:Float) {
		if (isMenuItem) {
			var lerpVal:Float = FlxMath.bound(elapsed * 9.6, 0, 1);
			if (changeX)
            	x = FlxMath.lerp(x, (targetY * distancePerItem.x) + startPosition.x, lerpVal);
			if (changeY)
            	y = FlxMath.lerp(y, (targetY * 1.3 * distancePerItem.y) + startPosition.y, lerpVal);
		}
		super.update(elapsed);
	}

    public function snapToPosition()
	{
		if (changeX)
        	x = (targetY * distancePerItem.x) + startPosition.x;
		if (changeX)
        	y = (targetY * 1.3 * distancePerItem.y) + startPosition.y;
	}

	private function set_scaleX(value:Float) {
		if (value == scaleX)
			return value;

		return scale.x = scaleX = value;
	}

	private function set_scaleY(value:Float) {
		if (value == scaleY)
			return value;

		return scale.y = scaleY = value;
	}
}