package objects;

import online.away.AnimatedSprite3D;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxSort;
import flixel.util.FlxDestroyUtil;
#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#end
import openfl.utils.AssetType;
import openfl.utils.Assets;
import tjson.TJSON as Json;
import backend.Song;
import backend.Section;
import states.stages.objects.TankmenBG;
import online.GameClient;

typedef CharacterFile = {
	var animations:Array<AnimArray>;
	var image:String;
	var scale:Float;
	var sing_duration:Float;
	var healthicon:String;

	var position:Array<Float>;
	var camera_position:Array<Float>;

	var flip_x:Bool;
	var no_antialiasing:Bool;
	var healthbar_colors:Array<Int>;
	@:optional var vocals_file:String;
	@:optional var dead_character:Null<String>;
}

typedef AnimArray = {
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
	@:optional var sound:String;
	@:optional var flip_x:Bool;
}

class Character extends FlxSprite {
	public var sprite3D:AnimatedSprite3D;

	public var animOffsets:Map<String, Array<Dynamic>>;
	public var debugMode:Bool = false;

	public var isPlayer:Bool = false;
	public var curCharacter:String = DEFAULT_CHARACTER;
	public var isMissing:Bool = false;

	public var colorTween:FlxTween;
	// uh... check if opponent is holding
	public var noteHold(default, set):Bool = false;
	function set_noteHold(v) {
		if (PlayState.isCharacterPlayer(this) && noteHold != v) {
			GameClient.send("noteHold", v);
		}
		return noteHold = v;
	}
	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var animationNotes:Array<Dynamic> = [];
	public var stunned:Bool = false;
	public var singDuration:Float = 4; // Multiplier of how long a character holds the sing pose
	public var idleSuffix:String = '';
	public var danceIdle:Bool = false; // Character use "danceLeft" and "danceRight" instead of "idle"
	public var skipDance:Bool = false;
	public var vocalsFile:String = '';
	public var deadName:String = null;

	public var gameIconIndex:Int = 0;
	public var healthIcon:String = 'face';
	public var animationsArray:Array<AnimArray> = [];

	public var positionArray:Array<Float> = [0, 0];
	var ogPositionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];

	// x offset index (for multiple characters)
	public var ox:Int = 0;

	public var hasMissAnimations:Bool = true;
	// Used on Character Editor
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var healthColorArray:Array<Int> = [255, 0, 0];

	public var isSkin:Bool = false;
	public var loadFailed:Bool = false;

	public var animSounds:Map<String, openfl.media.Sound> = new Map<String, openfl.media.Sound>();
	public var sound:FlxSound;

	public var modDir:String = null;

	public var animSuffix:String;

	public var onAtlasAnimationComplete:String->Void;

	public var Custom(get, set):Bool;
	
	function set_Custom(value:Bool):Bool
	{
		return this.isSkin = value;
	}

	function get_Custom():Bool
	{
		return this.isSkin;
	}

	public var custom(get,never):Bool;

	function get_custom():Bool
	{
		return this.isSkin;
	}

	function set_custom(value:Bool):Bool
	{
		return this.isSkin = value;
	}
	public static var DEFAULT_CHARACTER:String = 'bf'; // In case a character is missing, it will use BF on its place

	public static function getCharacterFile(character:String, ?instance:Character):CharacterFile {
		var characterPath:String = 'characters/' + character + '.json';

		#if MODS_ALLOWED
		var path:String = Paths.modFolders(characterPath);
		if (!FileSystem.exists(path)) {
			path = Paths.getPreloadPath(characterPath);
		}

		if (!FileSystem.exists(path))
		#else
		var path:String = Paths.getPreloadPath(characterPath);
		if (!Assets.exists(path))
		#end
		{
			if (instance != null)
				instance.loadFailed = true;
			path = Paths.getPreloadPath('characters/' + DEFAULT_CHARACTER + '.json'); // If a character couldn't be found, change him to BF just to prevent a crash
		}

		#if MODS_ALLOWED
		var rawJson = File.getContent(path);
		#else
		var rawJson = Assets.getText(path);
		#end

		return cast Json.parse(rawJson);
	}

	public function new(x:Float, y:Float, ?character:String = 'bf', ?isPlayer:Bool = false, ?isSkin:Bool = false, ?charType:String) {
		super(x, y);

		modDir = Mods.currentModDirectory;

		animOffsets = new Map<String, Array<Dynamic>>();
		curCharacter = character;
		this.isPlayer = isPlayer;
		this.isSkin = isSkin;
		var library:String = null;
		switch (curCharacter) {
			// case 'your character name in case you want to hardcode them instead':

			default:
				var json:CharacterFile = getCharacterFile(curCharacter, this);
				isAnimateAtlas = false;

				var split:Array<String> = json.image.split(',');
				imageFile = split[0];

				#if MODS_ALLOWED
				var modAnimToFind:String = Paths.modFolders('images/' + imageFile + '/Animation.json');
				var animToFind:String = Paths.getPath('images/' + imageFile + '/Animation.json', TEXT);
				if (FileSystem.exists(modAnimToFind) || FileSystem.exists(animToFind) || Assets.exists(animToFind))
				#else
				if (Assets.exists(Paths.getPath('images/' + imageFile + '/Animation.json', TEXT)))
				#end
				isAnimateAtlas = true;

				if (!isAnimateAtlas) {
					frames = Paths.getAtlas(imageFile);
				}
				#if flxanimate
				else
				{
					atlas = new FlxAnimate();
					atlas.showPivot = false;
					try
					{
						Paths.loadAnimateAtlas(atlas, imageFile);
					}
					catch(e:Dynamic)
					{
						FlxG.log.warn('Could not load atlas ${imageFile}: $e');
						trace('Could not load atlas ${imageFile}: $e');
					}
				}
				#end

				if (frames != null) {
					if (!loadFailed && graphic.bitmap != null && FlxG.state is PlayState && PlayState.instance.stage3D != null) {
						sprite3D = PlayState.instance.stage3D.createSprite(charType, true, graphic.bitmap);
					}

					for (imgFile in split) {
						if (!imageFile.contains(imgFile))
							imageFile += ',$imgFile';
						var daAtlas = Paths.getAtlas(imgFile);
						if (daAtlas != null)
							cast(frames, FlxAtlasFrames).addAtlas(daAtlas);
					}
				}

				if (json.scale != 1) {
					jsonScale = json.scale;
					scale.set(jsonScale, jsonScale);
					updateHitbox();
				}

				// positioning
				ogPositionArray = positionArray = json.position;
				cameraPosition = json.camera_position;

				// data
				healthIcon = json.healthicon;
				singDuration = json.sing_duration;
				flipX = (json.flip_x == true);

				if (json.healthbar_colors != null && json.healthbar_colors.length > 2)
					healthColorArray = json.healthbar_colors;

				vocalsFile = json.vocals_file ?? curCharacter;
				
				deadName = json.dead_character;

				// antialiasing
				noAntialiasing = (json.no_antialiasing == true);
				antialiasing = ClientPrefs.data.antialiasing ? !noAntialiasing : false;

				// animations
				animationsArray = json.animations;
				if (animationsArray != null && animationsArray.length > 0) {
					for (anim in animationsArray) {
						var animAnim:String = '' + anim.anim;
						var animName:String = '' + anim.name;
						var animFps:Int = anim.fps;
						var animLoop:Bool = !!anim.loop; // Bruh
						var animIndices:Array<Int> = anim.indices;
						var flipX:Bool = !!anim.flip_x;
						if(!isAnimateAtlas)
						{
							if (animIndices != null && animIndices.length > 0) {
								animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop, flipX);
							}
							else {
								animation.addByPrefix(animAnim, animName, animFps, animLoop, flipX);
							}
						}
						#if flxanimate
						else
						{
							// no flipX in flxanimate bcs not supported bye
							if(animIndices != null && animIndices.length > 0)
								atlas.anim.addBySymbolIndices(animAnim, animName, animIndices, animFps, animLoop);
							else
								atlas.anim.addBySymbol(animAnim, animName, animFps, animLoop);
						}
						#end

						if (anim.offsets != null && anim.offsets.length > 1) 
							addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
						else
							addOffset(anim.anim, 0, 0);

						if (anim.sound != null) {
							var sound = Paths.sound(anim.sound);
							if (sound != null)
								animSounds.set(animAnim, sound);
						}
					}
				}
				else {
					quickAnimAdd('idle', 'BF idle dance');
				}

				setup3D();

				#if flxanimate
				if(isAnimateAtlas) copyAtlasValues();
				#end
				// trace('Loaded file to character ' + curCharacter);
		}
		originalFlipX = flipX;

		if(animOffsets.exists('singLEFTmiss') || animOffsets.exists('singDOWNmiss') || animOffsets.exists('singUPmiss') || animOffsets.exists('singRIGHTmiss')) hasMissAnimations = true;
		recalculateDanceIdle();
		dance();

		if (isPlayer) {
			flipX = !flipX;

			/*// Doesn't flip for BF, since his are already in the right place???
				if (!curCharacter.startsWith('bf'))
				{
					// var animArray
					if(animation.getByName('singLEFT') != null && animation.getByName('singRIGHT') != null)
					{
						var oldRight = animation.getByName('singRIGHT').frames;
						animation.getByName('singRIGHT').frames = animation.getByName('singLEFT').frames;
						animation.getByName('singLEFT').frames = oldRight;
					}

					// IF THEY HAVE MISS ANIMATIONS??
					if (animation.getByName('singLEFTmiss') != null && animation.getByName('singRIGHTmiss') != null)
					{
						var oldMiss = animation.getByName('singRIGHTmiss').frames;
						animation.getByName('singRIGHTmiss').frames = animation.getByName('singLEFTmiss').frames;
						animation.getByName('singLEFTmiss').frames = oldMiss;
					}
			}*/
		}

		if (curCharacter.endsWith('-speaker') && loadMappedAnims()) {
			// skipDance = true;
			playAnim("shoot1");
		}
	}

	public function setup3D() {
		if (sprite3D != null) {
			sprite3D.addAnimationsFromFlxSprite(this);
			for (name => offset in animOffsets) {
				sprite3D.animations.get(name).setOffset(offset[0], offset[1]);
			}
			sprite3D.scaleX = jsonScale;
			sprite3D.scaleY = jsonScale;
			sprite3D.antialiasing = !noAntialiasing;
			visible = false;
		}
	}

	public var noAnimationBullshit:Bool = false;
	public var noHoldBullshit:Bool = false;

	override function update(elapsed:Float) {
		if(isAnimateAtlas) atlas.update(elapsed);
		if (sprite3D != null) {
			sprite3D.play(animation.name, animation.curAnim.curFrame, true);
		}

		if (noAnimationBullshit) {
			super.update(elapsed);
			return;
		}

		if (!debugMode && !isAnimationNull()) {
			if (heyTimer > 0) {
				heyTimer -= elapsed * (PlayState.instance?.playbackRate ?? 1);
				if (heyTimer <= 0) {
					var anim:String = getAnimationName();

					if (specialAnim && anim == 'hey' || anim == 'cheer') {
						specialAnim = false;
						dance();
					}
					heyTimer = 0;
				}
			}
			else if (specialAnim && isAnimationFinished()) {
				specialAnim = false;
				dance();
			}
			else if ((getAnimationName().endsWith('miss') || isMissing) && isAnimationFinished()) {
				dance();
				finishAnimation();
			}

			// apparently animationNotes can be null, great!
			if (animationNotes != null && animationNotes.length > 0) {
				if (Conductor.songPosition > animationNotes[0][0]) {
					var noteData:Int = 1;
					if (animationNotes[0][1] > 2)
						noteData = 3;

					noteData += FlxG.random.int(0, 1);
					playAnim('shoot' + noteData, true);
					animationNotes.shift();
				}
				// if (isAnimationFinished())
				// 	dance();
					// playAnim(getAnimationName(), false, false, animation.curAnim.frames.length - 3);
			}

			if (getAnimationName().startsWith('sing'))
				holdTimer += elapsed;
			else if (PlayState.isCharacterPlayer(this) || GameClient.isConnected())
				holdTimer = 0;

			// (!GameClient.isConnected() && PlayState.instance.self != this) // check for null or not connected
			// || PlayState.instance.self

			if (!noHoldBullshit && holdTimer >= Conductor.stepCrochet * (0.0011 / (FlxG.sound.music != null ? FlxG.sound.music.pitch : 1)) * singDuration) {
				dance();
				holdTimer = 0;
			}

			var name:String = getAnimationName();
			if(isAnimationFinished() && animOffsets.exists('$name-loop'))
				playAnim('$name-loop');
		}
		super.update(elapsed);
	}

	inline public function isAnimationNull():Bool
		return !isAnimateAtlas ? (animation.curAnim == null) : (atlas.anim.curSymbol == null);

	inline public function getAnimationName():String
	{
		var name:String = '';
		@:privateAccess
		if(!isAnimationNull()) name = !isAnimateAtlas ? animation.curAnim.name : atlas.anim.curSymbol.name;
		return (name != null) ? name : '';
	}

	public function isAnimationFinished():Bool
	{
		if(isAnimationNull()) return false;
		return !isAnimateAtlas ? animation.curAnim.finished : atlas.anim.finished;
	}

	public function finishAnimation():Void
	{
		if(isAnimationNull()) return;
		if(!isAnimateAtlas) animation.curAnim.finish();
		else atlas.anim.curFrame = atlas.anim.length - 1;
	}

	public var animPaused(get, set):Bool;
	private function get_animPaused():Bool
	{
		if(isAnimationNull()) return false;
		return !isAnimateAtlas ? animation.curAnim.paused : atlas.anim.isPlaying;
	}
	private function set_animPaused(value:Bool):Bool
	{
		if(isAnimationNull()) return value;
		if(!isAnimateAtlas) animation.curAnim.paused = value;
		else
		{
			if(value) atlas.anim.pause();
			else atlas.anim.resume();
		} 
		return value;
	}

	public var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance() {
		if (!debugMode && !skipDance && !specialAnim) {
			if (danceIdle) {
				danced = !danced;

				if (danced)
					playAnim('danceRight' + idleSuffix);
				else
					playAnim('danceLeft' + idleSuffix);
			}
			else if (animOffsets.exists('idle' + idleSuffix)) {
				playAnim('idle' + idleSuffix);
			}
		}
	}

	final randomDirections:Array<String> = ['LEFT', 'DOWN', 'UP', 'RIGHT'];

	var colorTransformBefore:Array<Float> = [1, 1, 1]; // red, green, blue
	var colorTransformWasChanged:Bool = false;

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void {
		if (AnimName == null)
			return;

		if (animSuffix != null)
			AnimName += animSuffix;

		if(colorTransform != null && colorTransformWasChanged) {
			colorTransform.redMultiplier = colorTransformBefore[0];
			colorTransform.greenMultiplier = colorTransformBefore[1];
			colorTransform.blueMultiplier = colorTransformBefore[2];
		}

		specialAnim = false;
		isMissing = AnimName.endsWith("miss");

		if (AnimName == "taunt" || AnimName == "taunt-alt") {
			specialAnim = true;
			heyTimer = 1;
		}

		if (!animExists(AnimName)) {
			if ((AnimName == "taunt" || AnimName == "taunt-alt") && !animExists(AnimName)) {
				if (AnimName == "taunt-alt")
					AnimName = "hey-alt";
				else
					AnimName = "hey";
			}

			if (AnimName.endsWith("-alt") && !animExists(AnimName)) {
				AnimName = AnimName.substring(0, AnimName.length - "-alt".length);
			}
			
			if (AnimName == "hurt" && !animExists(AnimName)) {
				AnimName = 'sing' + randomDirections[FlxG.random.int(0, randomDirections.length - 1)] + 'miss';
			}

			if (AnimName == "hey" && !animExists(AnimName)) {
				if (curCharacter.startsWith("tankman")) {
					AnimName = "singUP-alt";
				}
				else {
					AnimName = "singUP";
					// specialAnim = false;
					// heyTimer = 0;
				}
			}

			if (AnimName.startsWith("sing") && !animExists(AnimName)) {
				for (anim in ['singLEFT', 'singRIGHT', 'singUP', 'singDOWN']) {
					if (AnimName.startsWith(anim)) {
						AnimName = anim + (AnimName.contains('miss') ? 'miss' : '');
						break;
					}
				}
			}

			if (AnimName.endsWith("miss") && !animExists(AnimName)) {
				AnimName = AnimName.substring(0, AnimName.length - "miss".length);

				colorTransformBefore = [colorTransform.redMultiplier, colorTransform.greenMultiplier, colorTransform.blueMultiplier];
				colorTransformWasChanged = true;

				colorTransform.redMultiplier = 0.5;
				colorTransform.greenMultiplier = 0.3;
				colorTransform.blueMultiplier = 0.5;
			}
		}

		if (animSounds != null /* ?? */ && animSounds.exists(AnimName)) {
			if (sound != null) {
				sound.stop();
				sound.destroy();
				sound = null;
			}

			sound = FlxG.sound.play(animSounds.get(AnimName));
			if (sound != null) {
				sound.onComplete = () -> {
					sound.destroy();
					sound = null;
				};
			}
		}

		if(!isAnimateAtlas) animation.play(AnimName, Force, Reversed, Frame);
		else {
			atlas.anim.play(AnimName, Force, Reversed, Frame);
			atlas.anim.onComplete.add(() -> {
				if (onAtlasAnimationComplete != null)
					onAtlasAnimationComplete(AnimName);
			});
		}

		var daOffset = animOffsets.get(AnimName);
		if (animOffsets.exists(AnimName)) {
			offset.set(daOffset[0], daOffset[1]);
		}

		if (curCharacter.startsWith('gf')) {
			if (AnimName == 'singLEFT') {
				danced = true;
			}
			else if (AnimName == 'singRIGHT') {
				danced = false;
			}

			if (AnimName == 'singUP' || AnimName == 'singDOWN') {
				danced = !danced;
			}
		}

		if (AnimName == 'redheadsAnim') {
			animSuffix = '-bloody';
		}
	}

	/**
	 * this nullifies the positions set in the character data
	 * and replaces them with v-slice-like positioning
	 * *unused*
	 */
	public function setPositionToFeet(v:Bool) {
		if (!v) {
			positionArray[0] = ogPositionArray[0];
			positionArray[1] = ogPositionArray[1];
			return;
		}

		positionArray[0] = -(width / 2) + ogPositionArray[0];
		positionArray[1] = -(height) + ogPositionArray[1];
	}

	public function animExists(AnimName:String) {
		return animOffsets.exists(AnimName);
	}

	function loadMappedAnims():Bool {
		var noteData:Array<SwagSection> = Song.loadFromJson('picospeaker', Paths.formatToSongPath(PlayState.SONG.song)).notes;
		if (noteData == null)
			return false;
		for (section in noteData) {
			for (songNotes in section.sectionNotes) {
				animationNotes.push(songNotes);
			}
		}
		TankmenBG.animationNotes = animationNotes;
		animationNotes.sort(sortAnims);
		return true;
	}

	function sortAnims(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int {
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}

	public var danceEveryNumBeats:Int = 2;

	private var settingCharacterUp:Bool = true;

	public function recalculateDanceIdle() {
		var lastDanceIdle:Bool = danceIdle;
		danceIdle = (animOffsets.exists('danceLeft' + idleSuffix) && animOffsets.exists('danceRight' + idleSuffix));

		if (settingCharacterUp) {
			danceEveryNumBeats = (danceIdle ? 1 : 2);
		}
		else if (lastDanceIdle != danceIdle) {
			var calc:Float = danceEveryNumBeats;
			if (danceIdle)
				calc /= 2;
			else
				calc *= 2;

			danceEveryNumBeats = Math.round(Math.max(calc, 1));
		}
		settingCharacterUp = false;
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0) {
		animOffsets[name] = [x, y];
	}

	public function quickAnimAdd(name:String, anim:String)
	{
		if(!isAnimateAtlas)
			animation.addByPrefix(name, anim, 24, false);
		#if flxanimate
		else
			atlas.anim.addBySymbol(name, anim, 24, false);
		#end
	}

	public var isAnimateAtlas:Bool = false;
	#if flxanimate
	public var atlas:FlxAnimate;

	public function copyAtlasValues()
	{
		@:privateAccess
		{
			atlas.cameras = cameras;
			atlas.scrollFactor = scrollFactor;
			atlas.scale = scale;
			atlas.offset = offset;
			atlas.origin = origin;
			atlas.x = x;
			atlas.y = y;
			atlas.angle = angle;
			atlas.alpha = alpha;
			atlas.visible = visible;
			atlas.flipX = flipX;
			atlas.flipY = flipY;
			atlas.shader = shader;
			atlas.antialiasing = antialiasing;
			atlas.colorTransform = colorTransform;
			atlas.color = color;
		}
	}
	
	public override function draw()
	{
		if(isAnimateAtlas)
		{
			copyAtlasValues();
			atlas.draw();
			return;
		}
		super.draw();
	}

	public function destroyAtlas()
	{
		if (atlas != null)
			atlas = FlxDestroyUtil.destroy(atlas);
	}
	#end

	override public function destroy() {
		super.destroy();

		if (sound != null) {
			sound.stop();
			sound.destroy();
			sound = null;
		}

		#if flxanimate
		destroyAtlas();
		#end
	}

	public function onCombo(from:Int, to:Int) {}
	public function onHealth(from:Float, to:Float) {}
}
