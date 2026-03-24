package objects;

import flixel.graphics.frames.FlxTileFrames;

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;
	private var isOldIcon:Bool = false;
	public var isPlayer:Bool = false;
	private var char:String = '';
	public var ox:Int;

	public function new(char:String = 'bf', isPlayer:Bool = false, ?allowGPU:Bool = true)
	{
		super();
		isOldIcon = (char == 'bf-old');
		this.isPlayer = isPlayer;
		if (char != null)
			changeIcon(char, allowGPU);
		scrollFactor.set();
	}

	override function update(elapsed:Float) {
		snapToTracker();

		super.update(elapsed);
	}

	public function snapToTracker() {
		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 30);
	}

	public static function findIconPath(char:String) {
		var name:String = 'icons/' + char;
		if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-' + char; //Older versions of psych engine's support
		if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-face'; //Prevents crash from missing icon
		return name;
	}

	private var iconOffsets:Array<Float> = [0, 0];
	public function changeIcon(char:String, ?allowGPU:Bool = true) {
		if(this.char != char) {
			var name:String = findIconPath(char);
			
			var graphic = Paths.image(name, allowGPU);
			if (graphic == null) {
				if (char != 'face')
					changeIcon('face');
				return;
			}

			this.char = char;
			loadIcon(graphic);
		}
	}

	public function loadIcon(asset:flixel.system.FlxAssets.FlxGraphicAsset) {
		loadGraphic(asset, true);

		final tileFrames:FlxTileFrames = cast frames;
		if (tileFrames?.tileSize == null)
			return;

		var iSize:Float = Math.round(tileFrames.parent.width / tileFrames.parent.height);
		tileFrames.tileSize.set(Math.floor(tileFrames.parent.width / iSize), Math.floor(tileFrames.parent.height));
		iconOffsets[0] = (width - 150) / iSize;
		iconOffsets[1] = (height - 150) / iSize;
		updateHitbox();

		animation.add(char, [for(i in 0...frames.frames.length) i], 0, false, isPlayer);
		animation.play(char);

		if(char.endsWith('-pixel'))
			antialiasing = false;
		else
			antialiasing = ClientPrefs.data.antialiasing;
	}

	override function updateHitbox()
	{
		super.updateHitbox();
		offset.x = iconOffsets[0];
		offset.y = iconOffsets[1];
	}

	public function getCharacter():String {
		return char;
	}
}
