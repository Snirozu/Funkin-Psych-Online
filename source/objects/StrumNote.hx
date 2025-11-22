package objects;

import flixel.graphics.frames.FlxAtlasFrames;
import online.GameClient;
import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;
import backend.NoteSkinData;

class StrumNote extends FlxSprite
{
	public var rgbShader:RGBShaderReference;
	public var resetAnim:Float = 0;
	private var noteData:Int = 0;
	public var direction:Float = 90;//plan on doing scroll directions soon -bb
	public var downScroll:Bool = false;//plan on doing scroll directions soon -bb
	public var sustainReduce:Bool = true;
	private var player:Int;
	public var maxAlpha:Float = 1.;
	
	public var texture(default, set):String = null;
	private function set_texture(value:String):String {
		if(texture != value) {
			Note.colArray = Note.getColArrayFromKeys();
			if (Note.colArray[noteData % Note.maniaKeys] == 'odd' && !value.endsWith('_ODD')) {
				value = value + '_ODD';
			}
			texture = value;
			reloadNote();
		}
		return value;
	}

	public var useRGBShader:Bool = true;
	public function new(x:Float, y:Float, leData:Int, player:Int) {
		var mustPress = player == 1;

		rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(leData, mustPress));
		rgbShader.enabled = false;
		if(PlayState.SONG != null && PlayState.SONG.disableNoteRGB) useRGBShader = false;

		var arr:Array<FlxColor> = ClientPrefs.getRGBColor(mustPress == (GameClient.getPlayerSelf()?.bfSide ?? true) ? 0 : 1)[leData];
		if(PlayState.isPixelStage) arr = ClientPrefs.getRGBPixelColor(mustPress == (GameClient.getPlayerSelf()?.bfSide ?? true) ? 0 : 1)[leData];

		if(arr.length >= 3)
		{
			@:bypassAccessor
			{
				rgbShader.r = arr[0];
				rgbShader.g = arr[1];
				rgbShader.b = arr[2];
			}
		}

		noteData = leData;
		this.player = player;
		this.noteData = leData;
		super(x, y);

		var skin:String = null;
		if(PlayState.SONG != null && PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1) skin = PlayState.SONG.arrowSkin;
		else skin = Note.defaultNoteSkin;

		var customSkin:String = skin + Note.getNoteSkinPostfix(mustPress);
		if(Paths.fileExists('images/$customSkin.png', IMAGE)) skin = customSkin;

		texture = skin; //Load texture and anims
		scrollFactor.set();
	}

	public function reloadNote()
	{
		var lastAnim:String = null;
		if(animation.curAnim != null) lastAnim = animation.curAnim.name;

		Note.colArray = Note.getColArrayFromKeys();

		if(PlayState.isPixelStage)
		{
			var graphic = Paths.image('pixelUI/' + texture);
			if (graphic == null && texture.endsWith('_ODD')) {
				@:bypassAccessor texture = texture.substring(0, texture.length - '_ODD'.length);
				graphic = Paths.image('pixelUI/' + texture);
				Note.colArray = Note.getColArrayFromKeys(true);
			}

			loadGraphic(graphic);
			if (!texture.endsWith('_ODD'))
				width = width / 4;
			height = height / 5;
			loadGraphic(Paths.image('pixelUI/' + texture), true, Math.floor(width), Math.floor(height));

			antialiasing = false;
			setGraphicSize(Std.int(width * PlayState.daPixelZoom * Note.noteScale));

			animation.add('green', [6]);
			animation.add('red', [7]);
			animation.add('blue', [5]);
			animation.add('purple', [4]);
			animation.add('odd', [1]);

			addDirection();
		}
		else
		{
			frames = Paths.getSparrowAtlas(texture);
			if (graphic == null && texture.endsWith('_ODD')) {
				@:bypassAccessor texture = texture.substring(0, texture.length - '_ODD'.length);
				frames = Paths.getSparrowAtlas(texture);
				Note.colArray = Note.getColArrayFromKeys(true);
			}

			animation.addByPrefix('green', 'arrowUP');
			animation.addByPrefix('blue', 'arrowDOWN');
			animation.addByPrefix('purple', 'arrowLEFT');
			animation.addByPrefix('red', 'arrowRIGHT');
			animation.addByPrefix('odd', 'arrowODD');

			antialiasing = ClientPrefs.data.antialiasing;
			setGraphicSize(Std.int(width * 0.7 * Note.noteScale));

			addDirection();
		}

		updateHitbox();

		if(lastAnim != null)
		{
			playAnim(lastAnim, true);
		}
	}

	function addDirection() {
		var colDirs = [
			'purple' => addLeft,
			'blue' => addDown,
			'odd' => addOdd,
			'green' => addUp,
			'red' => addRight
		];

		colDirs.get(Note.getColArrayFromKeys()[Std.int(Math.abs(noteData) % Note.maniaKeys)])();
	}

	function addLeft() {
		if (PlayState.isPixelStage) {
			animation.add('static', [0]);
			animation.add('pressed', [4, 8], 12, false);
			animation.add('confirm', [12, 16], 24, false);
			return;
		}
		animation.addByPrefix('static', 'arrowLEFT');
		animation.addByPrefix('pressed', 'left press', 24, false);
		animation.addByPrefix('confirm', 'left confirm', 24, false);
	}

	function addDown() {
		if (PlayState.isPixelStage) {
			animation.add('static', [1]);
			animation.add('pressed', [5, 9], 12, false);
			animation.add('confirm', [13, 17], 24, false);
			return;
		}
		animation.addByPrefix('static', 'arrowDOWN');
		animation.addByPrefix('pressed', 'down press', 24, false);
		animation.addByPrefix('confirm', 'down confirm', 24, false);
	}

	function addUp() {
		if (PlayState.isPixelStage) {
			animation.add('static', [2]);
			animation.add('pressed', [6, 10], 12, false);
			animation.add('confirm', [14, 18], 12, false);
			return;
		}
		animation.addByPrefix('static', 'arrowUP');
		animation.addByPrefix('pressed', 'up press', 24, false);
		animation.addByPrefix('confirm', 'up confirm', 24, false);
	}

	function addRight() {
		if (PlayState.isPixelStage) {
			animation.add('static', [3]);
			animation.add('pressed', [7, 11], 12, false);
			animation.add('confirm', [15, 19], 24, false);
			return;
		}
		animation.addByPrefix('static', 'arrowRIGHT');
		animation.addByPrefix('pressed', 'right press', 24, false);
		animation.addByPrefix('confirm', 'right confirm', 24, false);
	}

	function addOdd() {
		if (!Note.colArray.contains('odd')) {
			addUp();
			return;
		}

		if (PlayState.isPixelStage) {
			animation.add('static', [0]);
			animation.add('pressed', [1, 2], 12, false);
			animation.add('confirm', [3, 4], 24, false);
			return;
		}
		animation.addByPrefix('static', 'arrowODD');
		animation.addByPrefix('pressed', 'odd press', 24, false);
		animation.addByPrefix('confirm', 'odd confirm', 24, false);
	}

	var initialized:Bool = false;

	public function postAddedToGroup() {
		playAnim('static');
		x += Note.swagScaledWidth * noteData;
		x -= Note.getNoteOffsetX() * noteData;
		// if (FlxG.state is PlayState) {
		// 	var player = player;
		// 	if (ClientPrefs.data.middleScroll && !PlayState.playsAsBF()) {
		// 		player = player == 0 ? 1 : 0;
		// 	}
		// 	x += FlxG.width / 2;
		// 	if (player == 0) {
		// 		x -= Note.swagScaledWidth * Note.maniaKeys;
		// 	}
		// }
		ID = noteData;
		initialized = true;
	}

	public var forceHide:Bool = false;

	override function update(elapsed:Float) {
		
		if (forceHide) {
			alpha = 0;
		}

		if (alpha > maxAlpha)
			alpha = maxAlpha;
		
		if(resetAnim > 0) {
			resetAnim -= elapsed;
			if(resetAnim <= 0) {
				playAnim('static');
				resetAnim = 0;
			}
		}
		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false) {
		animation.play(anim, force);
		if(animation.curAnim != null)
		{
			centerOffsets();
			centerOrigin();
		}
		if(useRGBShader) rgbShader.enabled = (animation.curAnim != null && animation.curAnim.name != 'static');
	}

	override function set_visible(value:Bool):Bool {
		if (initialized) {
			if (forceHide)
				return super.set_visible(false);

			if (ClientPrefs.data.disableStrumMovement)
				return visible;
		}
		return super.set_visible(value);
	}

	override function set_alpha(value:Float):Float {
		if (initialized) {
			if (forceHide)
				return super.set_alpha(0);

			if (ClientPrefs.data.disableStrumMovement)
				return super.set_alpha(FlxMath.bound(value, 0.75, 1));
		}
		return super.set_alpha(value);
	}

	override function set_x(value:Float):Float {
		if (initialized && ClientPrefs.data.disableStrumMovement) {
			return x;
		}
		return super.set_x(value);
	}

	override function set_y(value:Float):Float {
		if (initialized && ClientPrefs.data.disableStrumMovement) {
			return y;
		}
		return super.set_y(value);
	}
}
