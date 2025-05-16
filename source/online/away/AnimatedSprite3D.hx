package online.away;

import flixel.graphics.frames.FlxFrame;
import online.away.AnimationDataParser;
import openfl.display.BitmapData;
import away3d.animators.nodes.AnimationClipNodeBase;
import openfl.Lib;
import openfl.events.Event;
import away3d.textfield.RectangleBitmapTexture;
import away3d.materials.TextureMaterial;
import away3d.containers.ObjectContainer3D;
import away3d.animators.data.SpriteSheetAnimationFrame;
import away3d.animators.nodes.SpriteSheetClipNode;
import away3d.animators.SpriteSheetAnimationSet;
import away3d.animators.SpriteSheetAnimator;

/**
 * im sooo glad it finally works after days of trying 🙏
 * be free to use it in your mod (with credit), i wanna see some cool 3d stuff
 * @author Snirozu
 */
@:access(away3d.animators.SpriteSheetAnimator)
class AnimatedSprite3D extends ObjectContainer3D {
	var _spriteSheetAnimationSet:SpriteSheetAnimationSet = new SpriteSheetAnimationSet();
	var _texture:RectangleBitmapTexture;

	var spriteMesh:StaticSprite3D;
	var animator(default, null):SpriteSheetAnimator;

	var animFramesData:AnimationFrameDataMap = new AnimationFrameDataMap();
	public var animations:AnimationDataMap = new AnimationDataMap();

	var _prevAnimName:String = null;
	var _anim:AnimationData;
	var anim(get, never):AnimationData;

	public var antialiasing(get, set):Bool;

	public var flipX(default, set):Bool;
	public var flipY(default, set):Bool;
	public var applyFlipToOffset(default, set):Bool = true;

	public var tileSize:Null<Array<Int>>;

	public function new(?spriteProps:SpriteProps, ?bitmap:BitmapData) {
		super();

		spriteProps ??= {};
		spriteProps.completeSize = false;
		spriteProps.bothSides = true;

		if (spriteProps.frameSize != null) {
			tileSize = [spriteProps.frameSize[0], spriteProps.frameSize[1] ?? spriteProps.frameSize[0]]; 
		}
		else if (bitmap == null && spriteProps.animations != null && spriteProps.image != null) {
			var atlas = Paths.getAtlas(spriteProps.image);
			bitmap = atlas.parent.bitmap;
			addFlxFrames(atlas.frames);
		}

		spriteMesh = new StaticSprite3D(spriteProps, bitmap);
		this._texture = cast(cast(spriteMesh.material, TextureMaterial).texture);
		spriteMesh.animator = this.animator = new SpriteSheetAnimator(_spriteSheetAnimationSet);
		addChild(spriteMesh);

		if (tileSize != null) {
			addTiles();
		}

		if (spriteProps.animations != null) {
			for (anim in spriteProps.animations) {
				addAnimation(anim);
			}
		}
	}

	public function play(animID:String, ?offset:Int = 0, ?stop:Bool = false) {
		if (!animator._animationSet.hasAnimation(animID))
			return;

		animator.play(animID, null, offset);
		if (stop)
			animator.gotoAndStop(offset);
		else
			animator.gotoAndPlay(offset);
		animator.fps = anim.fps;
		cast(animator.activeAnimation, AnimationClipNodeBase).looping = anim.loop;
		// todo: animator.playbackSpeed = flixel global sprite speed;
		updateFrame();
	}

	public function addTiles() {
		animFramesData ??= new AnimationFrameDataMap();

		if (!animFramesData.exists(''))
			animFramesData.set('', []);

		var i = 0;
		for (fY in 0...Std.int(spriteMesh.graphic.height / tileSize[1])) {
			for (fX in 0...Std.int(spriteMesh.graphic.width / tileSize[0])) {
				animFramesData.get('').push({
					rawName: i + '',
					x: fX * tileSize[0],
					y: fY * tileSize[1],
					width: tileSize[0],
					height: tileSize[1],
					frameX: 0,
					frameY: 0,
				});
				i++;
			}
		}
	}

	public function addSparrowAtlas(data:String) {
		AnimationDataParser.parseSparrowXML(data, animFramesData);
	}

	public function addPackerAtlas(data:String) {
		AnimationDataParser.parsePackerTXT(data, animFramesData);
	}

	// worse way to get frames (that flixel uses), only here so they work 
	function getFramesByPrefix(prefix:String):Array<FrameData> {
		var frames:Array<FrameData> = null;
		for (anim in animFramesData) {
			for (frame in anim) {
				if (frame.rawName.startsWith(prefix)) {
					frames ??= [];
					frames.push(frame);
				}
			}
		}
		return frames;
	}

	public function addAnimation(props:AnimationData):AnimationData {
		var animation = props ?? new AnimationData();
		animation.frames ??= [];
		animations.set(animation.id, animation);

		var spriteSheetClipNode:SpriteSheetClipNode = new SpriteSheetClipNode();
		spriteSheetClipNode.name = animation.id;

		var frame:SpriteSheetAnimationFrame;
		var framesData:Array<FrameData> = null;
		if (animation.frames != null && animation.frames.length > 0) framesData = animation.frames.copy();
		framesData ??= animFramesData.get(animation.name);
		framesData ??= getFramesByPrefix(animation.name);

		if (framesData == null) {
			trace('Animation "${animation.id}" couldn\'t be found!');
			return null;
		}

		if (animation.indices == null)
			for (animFrame in framesData) {
				animation.frames.push(animFrame);
			}
		else
			for (frameIndex in animation.indices) {
				if (framesData[frameIndex] == null)
					continue;
				animation.frames.push(framesData[frameIndex]);
			}

		if (animation.frames == null) {
			trace('Frames for Animation "${animation.id}" in "${animation.name}" couldn\'t be found!');
			return null;
		}

		for (i => animFrame in animation.frames) {
			frame = new SpriteSheetAnimationFrame();
			frame.offsetU = animFrame.x / _texture.bitmapData.width;
			frame.offsetV = animFrame.y / _texture.bitmapData.height;
			frame.scaleU = animFrame.width / _texture.bitmapData.width;
			frame.scaleV = animFrame.height / _texture.bitmapData.height;
			frame.mapID = i;
			spriteSheetClipNode.addFrame(frame, 1);
		}

		_spriteSheetAnimationSet.addAnimation(spriteSheetClipNode);
		if (animator.activeAnimationName == null) {
			play(animation.id);
		}
		return animations.get(animation.id);
	}

	public function addFlxFrames(framesData:Array<FlxFrame>) {
		for (frame in framesData) {
			if (!animFramesData.exists(frame.name))
				animFramesData.set(frame.name, []);

			animFramesData.get(frame.name).push(frameOfFlxFrame(frame));
		}
	}

	function frameOfFlxFrame(frame:FlxFrame) {
		return {
			rawName: frame.name,
			x: Std.int(frame.frame.x),
			y: Std.int(frame.frame.y),
			width: Std.int(frame.frame.width),
			height: Std.int(frame.frame.height),

			frameX: Std.int(frame.offset.x),
			frameY: Std.int(frame.offset.y),
			frameWidth: null,
			frameHeight: null
		}
	}

	public function addAnimationsFromFlxSprite(sprite:FlxSprite) {
		for (name => anim in @:privateAccess sprite.animation._animations) {
			var animFrames:Array<FrameData> = [];
			for (frame in anim.frames) {
				animFrames.push(frameOfFlxFrame(sprite.frames.frames[frame]));
			}
			var animationData = new AnimationData();
			animationData.id = name;
			animationData.frames = animFrames;
			addAnimation(animationData);
		}
	}

	override function setParent(v:ObjectContainer3D) {
		super.setParent(v);

		if (v == null) {
			Lib.current.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			return;
		}

		Lib.current.addEventListener(Event.ENTER_FRAME, onEnterFrame);
	}

	
	function onEnterFrame(e:Event) {
		if (spriteMesh == null)
			return;

		if (_prevFrame != animator.currentFrameNumber) {
			updateFrame();
		}
	}

	var _prevFrame:Int = -1;
	function updateFrame() {
		if (animator.activeAnimationName == null)
			return;

		var frame = anim.frames[animator.currentFrameNumber];

		spriteMesh.scaleX = frame.width;
		spriteMesh.scaleY = frame.height;

		spriteMesh.x = (frame.width / 2 - frame.frameX) * (flipX ? -1 : 1);
		spriteMesh.x -= anim.offsetX * (flipX && applyFlipToOffset ? -1 : 1) / scaleX;

		spriteMesh.y = (-frame.height / 2 + frame.frameY) * (flipY ? -1 : 1);
		spriteMesh.y += anim.offsetY * (flipY && applyFlipToOffset ? -1 : 1) / scaleY;

		_prevFrame = animator.currentFrameNumber;
	}

	function get_anim() {
		if (_prevAnimName != animator.activeAnimationName) {
			_anim = animations.get(animator.activeAnimationName);
		}
		_prevAnimName = animator.activeAnimationName;
		return _anim;
	}
	function get_antialiasing() return spriteMesh.material.smooth;
	function set_antialiasing(v) return spriteMesh.material.smooth = v;

	function set_flipX(v) {
		flipX = v;
		spriteMesh.rotationY = v ? 180 : 0;
		updateFrame();
		return flipX;
	}

	function set_flipY(v) {
		flipY = v;
		spriteMesh.rotationX = v ? 180 : 0;
		updateFrame();
		return flipY;
	}

	function set_applyFlipToOffset(v) {
		applyFlipToOffset = v;
		updateFrame();
		return applyFlipToOffset;
	}

	override function set_scaleX(v) {
		super.set_scaleX(v);
		updateFrame();
		return scaleX;
	}

	override function set_scaleY(v) {
		super.set_scaleY(v);
		updateFrame();
		return scaleY;
	}
}