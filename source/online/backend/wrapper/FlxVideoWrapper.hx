package online.backend.wrapper;

import openfl.display.DisplayObject;
import flixel.util.FlxAxes;
import openfl.display.BitmapData;
import cpp.UInt32;
import haxe.Int64;
import hxvlc.flixel.FlxVideo;
import lime.app.Event;

@:publicFields
@:access(hxvlc.flixel.FlxVideo)
@:build(online.backend.Macros.getSetForwarder())
class FlxVideoWrapper extends DisplayObject { // as DisplayObject so scripts think it's actual FlxVideo
	var _video:FlxVideo;

	override function get_visible() return _video.visible;
	override function set_visible(v) return _video.visible = v;
	override function get_alpha() return _video.alpha;
	override function set_alpha(v) return _video.alpha = v;
	// @:forwardField(_video.visible) var visible(get, set):Bool;
	// @:forwardField(_video.alpha) var alpha(get, set):Float;
	@:forwardField(_video.bitmapData) var bitmapData(get, set):BitmapData;

	@:forwardField(_video.textureWidth) var videoWidth(get, set):UInt32;
	@:forwardField(_video.textureHeight) var videoHeight(get, set):UInt32;
	@:forwardField(_video.time) var time(get, set):Int64;
	@:forwardGetter(_video.length) var length(get, never):Int64;
	@:forwardGetter(_video.duration) var duration(get, never):Int64;
	@:forwardField(_video.position) var position(get, set):Single;
	@:forwardGetter(_video.mrl) var mrl(get, never):Null<String>;
	@:forwardField(_video.volume) var volume(get, set):Int;
	@:forwardField(_video.channel) var channel(get, set):Int;
	@:forwardField(_video.delay) var delay(get, set):Int64;
	@:forwardField(_video.rate) var rate(get, set):Single;
	@:forwardGetter(_video.isPlaying) var isPlaying(get, never):Bool;
	@:forwardGetter(_video.isSeekable) var isSeekable(get, never):Bool;
	@:forwardGetter(_video.canPause) var canPause(get, never):Bool;
	@:forwardGetter(mute) var hasVolume(get, never):Bool;

	@:forwardGetter(_video.onOpening) var onOpening(get, never):Event<Void->Void>;
	@:forwardGetter(_video.onPlaying) var onPlaying(get, never):Event<Void->Void>;
	@:forwardGetter(_video.onStopped) var onStopped(get, never):Event<Void->Void>;
	@:forwardGetter(_video.onPaused) var onPaused(get, never):Event<Void->Void>;
	@:forwardGetter(_video.onEndReached) var onEndReached(get, never):Event<Void->Void>;
	@:forwardGetter(_video.onEncounteredError) var onEncounteredError(get, never):Event<String->Void>;
	@:forwardGetter(_video.onTimeChanged) var onForward(get, never):Event<Int64->Void>;
	@:forwardGetter(_video.onTimeChanged) var onBackward(get, never):Event<Int64->Void>;
	@:forwardGetter(_video.onMediaChanged) var onMediaChanged(get, never):Event<Void->Void>;
	@:forwardGetter(_video.onFormatSetup) var onTextureSetup(get, never):Event<Void->Void>;
	
	var mute(get, set):Bool;
	function get_mute() {
		return volume > 0;
	}
	function set_mute(v) {
		if (v)
			volume = 0;
		return v;
	}

	var autoResize(get, set):Bool;
	function get_autoResize() {
		return (_video.resizeMode.x || _video.resizeMode.y);
	}
	function set_autoResize(v) {
		if (v)
			_video.resizeMode = FlxAxes.XY;
		else
			_video.resizeMode = FlxAxes.NONE;

		return v;
	}

	var finishCallback(default, set):Void->Void = null;
	function set_finishCallback(v) {
		if (finishCallback != null) {
			_video.onEndReached.remove(finishCallback);	
		}
		finishCallback = v;
		if (finishCallback == null)
			return finishCallback;
		_video.onEndReached.add(v);
		return finishCallback;
	}

	var readyCallback(default, set):Void->Void = null;
	function set_readyCallback(v) {
		if (readyCallback != null) {
			_video.onOpening.remove(readyCallback);	
		}
		readyCallback = v;
		if (readyCallback == null)
			return readyCallback;
		_video.onOpening.add(v);
		return readyCallback;
	}

	function new() {
		super();

		_video = new FlxVideo();

		addEventListener(openfl.events.Event.ADDED, function(e) {
			parent.addChild(_video);
		});
		addEventListener(openfl.events.Event.REMOVED, function(e) {
			parent.removeChild(_video);
		});
	}

	function play(location:String, ?shouldLoop:Bool = false):Bool {
		_video.load(location, shouldLoop ? ["input-repeat=65535"] : []);
		if (parent == null)
			FlxG.stage.addChild(this);
		return _video.play();
	}

	public function dispose():Void {
		_video.dispose();
	}

	public function stop():Void {
		_video.stop();
	}

	public function pause():Void {
		_video.pause();
	}

	public function resume():Void {
		_video.resume();
	}

	public function togglePaused():Void {
		_video.togglePaused();
	}

	function playVideo(location:String):Bool {
		return play(location);
	}

	public function finishVideo():Void {
		_video.time = _video.length;
		// _video.stop();
	}
}