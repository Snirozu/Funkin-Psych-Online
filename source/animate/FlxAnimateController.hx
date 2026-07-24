package animate;

import animate.internal.Timeline;
import flixel.FlxG;
import flixel.animation.FlxAnimation;
import flixel.animation.FlxAnimationController;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxRect;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.util.FlxSignal;
import animate.FlxAnimate;

using StringTools;

@:access(animate.FlxAnimate)
class FlxAnimateController extends FlxAnimationController
{


	/**
     * Backwards compatibility stuff for flxanimate.
     * Siema atesz!
	 */

    public var symbolDictionary(get, null):Map<String, animate.internal.SymbolItem>;
    inline private function get_symbolDictionary() return _animate.library.dictionary;

    public var framerate(get, null):Dynamic;
    inline private function get_framerate() return _animate.library.frameRate;

    public var curFrame(get, set):Dynamic;
    inline private function get_curFrame() return frameIndex;
    inline private function set_curFrame(d:Dynamic) {frameIndex = d; return d;}

    public var length(get, null):Dynamic;
    inline private function get_length() {trace(curAnim.frames.length); return 1;};

    public final onComplete = new FlxSignal();

	/**
	 * Dispatches each time the current animation's frame label changes.
	 * Exclusive to Texture Atlas animations.
	 *
	 * @param frameLabel The label of the current frame
	 */

	public final onFrameLabel = new FlxTypedSignal<(frameLabel:String) -> Void>();

	public function new(sprite:FlxAnimate)
	{
		super(sprite);

        finishCallback = (name:String) -> {
            onComplete.dispatch();
        };
	}

	/**
	 * Adds a new animation to the sprite, requires to be loaded with a Texture Atlas.
	 *
	 * @param name			What this animation should be called (e.g. `"run"`).
	 * @param label			Frame label tag to load the animation from.
	 * @param frameRate		The speed in frames per second that the animation should play at (e.g. `40` fps), leave ``null`` to use the default framerate.
	 * @param looped		Whether or not the animation is looped or just plays once.
	 * @param flipX			Whether the frames should be flipped horizontally.
	 * @param flipY			Whether the frames should be flipped vertically.
	 * @param timeline		Optional, ``Timeline`` object used to add the frame labels from.
	 */
	public function addByFrameLabel(name:String, label:String, ?frameRate:Float, ?looped:Bool = true, ?flipX:Bool, ?flipY:Bool, ?timeline:Timeline):Void
	{
		if (!hasAnimateAtlas)
		{
			FlxG.log.warn('Sprite is not loaded with a texture atlas.');
			return;
		}

		var usedTimeline = timeline ?? getDefaultTimeline();
		var foundFrames = findFrameLabelIndices(label, usedTimeline);

		if (foundFrames.length <= 0)
		{
			var collectionTimelines = getCollectionTimelines();
			if (collectionTimelines.length > 0)
			{
				for (timeline in collectionTimelines)
				{
					var newFrames = findFrameLabelIndices(label, timeline);
					if (newFrames.length > 0)
					{
						FlxG.log.notice('Found frame label "${label}" in timeline "${timeline.name}" from texture atlas "${timeline.parent.path}".');
						foundFrames = newFrames;
						usedTimeline = timeline;
						break;
					}
				}
			}
			else
			{
				FlxG.log.warn('No frames found with label "$label" in timeline "${usedTimeline.name}".');
				return;
			}
		}

		frameRate ??= getDefaultFramerate();

		var anim = new FlxAnimateAnimation(this, name, foundFrames, frameRate, looped, flipX, flipY);
		anim.timeline = usedTimeline;
		_animations.set(name, anim);
	}

	/**
	 * Adds a new animation to the sprite, requires to be loaded with a Texture Atlas.
	 *
	 * @param name 			What this animation should be called (e.g. `"run"`).
	 * @param label 		Frame label tag to load the animation from.
	 * @param indices		An array of numbers indicating what frames to play in what order (e.g. `[0, 1, 2]`).
	 * @param frameRate 	The speed in frames per second that the animation should play at (e.g. `40` fps), leave ``null`` to use the default framerate.
	 * @param looped 		Whether or not the animation is looped or just plays once.
	 * @param flipX 		Whether the frames should be flipped horizontally.
	 * @param flipY 		Whether the frames should be flipped vertically.
	 * @param timeline 		Optional, ``Timeline`` object used to add the frame labels from.
	 */
	public function addByFrameLabelIndices(name:String, label:String, indices:Array<Int>, ?frameRate:Float, ?looped:Bool = true, ?flipX:Bool, ?flipY:Bool,
			?timeline:Timeline)
	{
		if (!hasAnimateAtlas)
		{
			FlxG.log.warn('Sprite is not loaded with a texture atlas.');
			return;
		}

		var usedTimeline = timeline ?? getDefaultTimeline();
		var foundFrames:Array<Int> = findFrameLabelIndices(label, usedTimeline);
		var useableFrames:Array<Int> = [];

		if (foundFrames.length <= 0)
		{
			var collectionTimelines = getCollectionTimelines();
			if (collectionTimelines.length > 0)
			{
				for (timeline in collectionTimelines)
				{
					var newFrames = findFrameLabelIndices(label, timeline);
					if (newFrames.length > 0)
					{
						FlxG.log.notice('Found frame label "${label}" in timeline "${timeline.name}" from texture atlas "${timeline.parent.path}".');
						foundFrames = newFrames;
						usedTimeline = timeline;
						break;
					}
				}
			}
		}

		for (index in indices)
		{
			var frameIndex:Null<Int> = foundFrames[index];
			if (frameIndex != null)
				useableFrames.push(frameIndex);
		}

		if (useableFrames.length <= 0)
		{
			FlxG.log.warn('No frames useable with label "$label" and indices $indices in timeline "${usedTimeline.name}".');
			return;
		}

		frameRate ??= getDefaultFramerate();

		var anim = new FlxAnimateAnimation(this, name, useableFrames, frameRate, looped, flipX, flipY);
		anim.timeline = usedTimeline;
		_animations.set(name, anim);
	}

	/**
	 * Adds a new animation to the sprite, requires to be loaded with a Texture Atlas.
	 *
	 * @param name 			What this animation should be called (e.g. `"run"`).
	 * @param timeline 		``Timeline`` object used to add the animation from.
	 * @param frameRate 	The speed in frames per second that the animation should play at (e.g. `40` fps), leave ``null`` to use the default framerate.
	 * @param looped 		Whether or not the animation is looped or just plays once.
	 * @param flipX 		Whether the frames should be flipped horizontally.
	 * @param flipY 		Whether the frames should be flipped vertically.
	 */
	public function addByTimeline(name:String, timeline:Timeline, ?frameRate:Float, ?looped:Bool = true, ?flipX:Bool, ?flipY:Bool):Void
	{
		if (!hasAnimateAtlas)
		{
			FlxG.log.warn('Sprite is not loaded with a texture atlas.');
			return;
		}

		addByTimelineIndices(name, timeline, [for (i in 0...timeline.frameCount) i], frameRate, looped, flipX, flipY);
	}

	/**
	 * Adds a new animation to the sprite, requires to be loaded with a Texture Atlas.
	 *
	 * @param name 			What this animation should be called (e.g. `"run"`).
	 * @param timeline 		``Timeline`` object used to add the animation from.
	 * @param indices		An array of numbers indicating what frames to play in what order (e.g. `[0, 1, 2]`).
	 * @param frameRate 	The speed in frames per second that the animation should play at (e.g. `40` fps), leave ``null`` to use the default framerate.
	 * @param looped 		Whether or not the animation is looped or just plays once.
	 * @param flipX 		Whether the frames should be flipped horizontally.
	 * @param flipY 		Whether the frames should be flipped vertically.
	 */
	public function addByTimelineIndices(name:String, timeline:Timeline, indices:Array<Int>, ?frameRate:Float, ?looped:Bool = true, ?flipX:Bool,
			?flipY:Bool):Void
	{
		if (!hasAnimateAtlas)
		{
			FlxG.log.warn('Sprite is not loaded with a texture atlas.');
			return;
		}

		frameRate ??= getDefaultFramerate();
		var anim = new FlxAnimateAnimation(this, name, indices, frameRate, looped, flipX, flipY);
		anim.timeline = timeline;
		_animations.set(name, anim);
	}

	/**
	 * Adds a new animation to the sprite, requires to be loaded with a Texture Atlas.
	 *
	 * @param name 			What this animation should be called (e.g. `"run"`).
	 * @param symbolName 	Name of the symbol used to add the animation from.
	 * @param frameRate 	The speed in frames per second that the animation should play at (e.g. `40` fps), leave ``null`` to use the default framerate.
	 * @param looped 		Whether or not the animation is looped or just plays once.
	 * @param flipX 		Whether the frames should be flipped horizontally.
	 * @param flipY 		Whether the frames should be flipped vertically.
	 */
	public function addBySymbol(name:String, symbolName:String, ?frameRate:Float, ?looped:Bool = true, ?flipX:Bool, ?flipY:Bool):Void
	{
		if (!hasAnimateAtlas)
		{
			FlxG.log.warn('Sprite is not loaded with a texture atlas.');
			return;
		}

		var symbol = _animate.library.getSymbol(symbolName);
		if (symbol == null)
		{
			FlxG.log.warn('Symbol not found with name "$symbolName"');
			return;
		}

		frameRate ??= getDefaultFramerate();

		var anim = new FlxAnimateAnimation(this, name, [for (i in 0...symbol.timeline.frameCount) i], frameRate, looped, flipX, flipY);
		anim.timeline = symbol.timeline;
		_animations.set(name, anim);
	}

	/**
	 * Adds a new animation to the sprite, requires to be loaded with a Texture Atlas.
	 *
	 * @param name 			What this animation should be called (e.g. `"run"`).
	 * @param symbolName 	Name of the symbol used to add the animation from.
	 * @param indices		An array of numbers indicating what frames to play in what order (e.g. `[0, 1, 2]`).
	 * @param frameRate 	The speed in frames per second that the animation should play at (e.g. `40` fps), leave ``null`` to use the default framerate.
	 * @param looped 		Whether or not the animation is looped or just plays once.
	 * @param flipX 		Whether the frames should be flipped horizontally.
	 * @param flipY 		Whether the frames should be flipped vertically.
	 */
	public function addBySymbolIndices(name:String, symbolName:String, indices:Array<Int>, ?frameRate:Float, ?looped:Bool = true, ?flipX:Bool, ?flipY:Bool):Void
	{
		if (!hasAnimateAtlas)
		{
			FlxG.log.warn('Sprite is not loaded with a texture atlas.');
			return;
		}

		var symbol = _animate.library.getSymbol(symbolName);
		if (symbol == null)
		{
			FlxG.log.warn('Symbol not found with name "$symbolName"');
			return;
		}

		frameRate ??= getDefaultFramerate();

		var anim = new FlxAnimateAnimation(this, name, indices, frameRate, looped, flipX, flipY);
		anim.timeline = symbol.timeline;
		_animations.set(name, anim);
	}

	/**
	 * Gets the list of indices of a frame label to be found from a timeline.
	 *
	 * @param label Frame label tag to find the indices of.
	 * @param timeline Optional, ``Timeline`` object used to check the labels from, defaults to the main Texture Atlas document timeline.
	 * @return Array of ``Int`` indices of the frame label, empty if none were found.
	 */
	public function findFrameLabelIndices(label:String, ?timeline:Timeline):Array<Int>
	{
		var mainTimeline = timeline ?? getDefaultTimeline();
		return mainTimeline.findFrameLabelIndices(label);
	}

	override function set_frameIndex(frame:Int):Int
	{
		if (!isAnimate)
			return super.set_frameIndex(frame);

		var curAnim:Null<FlxAnimateAnimation> = cast _curAnim;
		if (curAnim != null)
		{
			final numFrames = #if (flixel >= "5.4.0") numFrames #else curAnim.timeline.frameCount #end;
			if (numFrames > 0)
			{
				frame = frame % numFrames;

				_animate.timeline = curAnim.timeline;
				_animate.timeline.currentFrame = frame;
				_animate.timeline.signalFrameChange(frame, this);
				if (_animate.useRenderTexture)
					_animate._renderTextureDirty = true;
				frameIndex = frame;
				fireCallback();

				updateTimelineBounds();
			}
		}

		return frameIndex;
	}

	/**
	 * Internal FlxFrame used to fake out current frame data for FlxSprite
	 * functions that are unavailable to override for FlxAnimate.
	 */
	var animateFrame:FlxFrame;

	@:allow(animate.FlxAnimate)
	function updateTimelineBounds():Void
	{
		if (animateFrame == null)
		{
			@:privateAccess // FlxFrame constructor used to be private
			animateFrame = new FlxFrame(_animate.graphic);
			animateFrame.frame = FlxRect.get();
		}

		@:privateAccess
		var bounds = _animate.timeline._bounds;
		animateFrame.parent = _animate.graphic;
		animateFrame.sourceSize.set(bounds.width, bounds.height);

		if (_animate.applyStageMatrix)
		{
			animateFrame.sourceSize.x *= _animate.library.matrix.a;
			animateFrame.sourceSize.y *= _animate.library.matrix.d;
		}

		animateFrame.frame.copyFrom(bounds);
		animateFrame.uv.set(0, 0, bounds.width, bounds.height);

		_animate.frame = animateFrame;
	}

	override function play(animName:String, force:Bool = false, reversed:Bool = false, frame:Int = 0)
	{
		var anim = _animations.get(animName);
		if (anim != null)
		{
			@:privateAccess
			_animate.isAnimate = anim is FlxAnimateAnimation;
		}

		super.play(animName, force, reversed, frame);
	}

	/**
	 * Wether the sprite is currently displaying a Texture Atlas animation or not.
	 */
	var isAnimate(get, never):Bool;

	/**
	 * Wether the sprite is loaded with a Texture Atlas.
	 * It's important to use this variable internally as to avoid errors, if the Texture Atlas is
	 * combined with other Flixel atlases, such as Sparrow.
	 */
	var hasAnimateAtlas(get, never):Bool;

	/**
	 * The default framerate of the Texture Atlas document.
	 * @return Float value of the framerate, ``0.0`` if the sprite isn't loaded with a Texture Atlas.
	 */
	public inline function getDefaultFramerate():Float
		return hasAnimateAtlas ? _animate.library.frameRate : 0.0;

	/**
	 * The default timeline of the Texture Atlas document.
	 * @return Default ``Timeline`` object, ``null`` if the sprite isn't loaded with a Texture Atlas.
	 */
	public inline function getDefaultTimeline():Timeline
		return hasAnimateAtlas ? _animate.library.timeline : null;

	/**
	 * The collection of extra main timelines merged to the Texture Atlas.
	 * @return An array of ``Timeline`` object, empty if the sprite isn't loaded with a Texture Atlas.
	 */
	public inline function getCollectionTimelines():Array<Timeline>
		return hasAnimateAtlas ? [for (collection in _animate.library.addedCollections) collection.timeline] : [];

	var _animate(get, never):FlxAnimate;

	inline function get__animate():FlxAnimate
		return cast _sprite;

	inline function get_isAnimate():Bool
		return _animate.isAnimate;

	inline function get_hasAnimateAtlas():Bool
		return _animate.library != null;

	override function destroy()
	{
		super.destroy();
		animateFrame = FlxDestroyUtil.destroy(animateFrame);
		FlxDestroyUtil.destroy(onFrameLabel);
	}
}

class FlxAnimateAnimation extends FlxAnimation
{
	public var timeline:Timeline;

	#if (flixel >= "5.3.0")
	override function getCurrentFrameDuration():Float
	{
		return frameDuration;
	}
	#end

	override function destroy()
	{
		super.destroy();
		timeline = null;
	}
}
