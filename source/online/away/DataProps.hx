package online.away;

import haxe.ds.Either;

typedef StageData3D = {
	var objects:Map<String, StageObject3D>;
	var cameraPoints:Map<String, Object3DPose>;
}

typedef StageObject3D = { >SpriteProps, >Object3DPose,
	var type:String;
	var scale:Null<Float>;
}

typedef Object3DPose = {
	var position:Array<Float>;
	var rotation:Array<Float>;
}

typedef SpriteProps = {
	var ?image:String;

	/**
	 * Default: `true`
	 */
	var ?completeSize:Null<Bool>;
	/**
	 * Default: `false`
	 */
	var ?bothSides:Bool;
	var ?geomWidth:Null<Float>;
	var ?geomHeight:Null<Float>;
	/**
	 * Default: `false`
	 */
	var ?repeat:Null<Bool>;
	/**
	 * Default: `1.0`
	 */
	var ?scaleUV:Null<Float>;
	/**
	 * Default: `true`
	 */
	var ?antialiasing:Null<Bool>;

	var ?frameSize:Array<Int>;
	var ?animations:Array<AnimationData>;
}

typedef AnimationDataMap = Map<String, AnimationData>;
@:publicFields class AnimationData extends AnimationProps {
	var frames:Array<FrameData> = [];

    function new() {
		super();
	}
}

@:build(online.backend.Macros.nullFallFields())
@:publicFields class AnimationProps {
	var               id:String;
	@:fall('')    var name(get, default):Null<String>;
	@:fall(0)     var offsetX(get, default):Null<Float>;
	@:fall(0)     var offsetY(get, default):Null<Float>;
	@:fall(24)    var fps(get, default):Null<Int>;
	@:fall(false) var loop(get, default):Null<Bool>;
	var               indices:Array<Int>;

	function new() {}

	function setOffset(x:Float, y:Float) {
		offsetX = x;
		offsetY = y;
		return this;
	}

	function setLoop(v:Bool) {
		loop = v;
		return this;
	}

	function setFPS(v:Int) {
		fps = v;
		return this;
	}
}

typedef AnimationFrameDataMap = Map<String, Array<FrameData>>;
// commenting so other ppl don't get confused
typedef FrameData = {
	x:Int, // the x/u coordinate of this frame on the spritesheet
	y:Int, // the y/v coordinate of this frame on the spritesheet
	width:Int, // the width of the clipping box to take for this frame
	height:Int, // the height of the clipping box to take for this frame

	rawName:String, // the whole animation name including the frame index

    //sparrow stuff
	frameX:Int, // x offset to add while rendering
	frameY:Int, // y offset to add while rendering
	// doesn't have any actual usage lol
	?frameWidth:Null<Int>, // how much pixel width this whole animation takes
	?frameHeight:Null<Int> // how much pixel height this whole animation takes
}