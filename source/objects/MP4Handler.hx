package objects;

import flixel.FlxG;
import flixel.FlxSprite;
import openfl.events.Event;
import openfl.display.BitmapData;
import sys.FileSystem;

#if hxcodec
import hxcodec.flixel.FlxVideoSprite;
#end

/**
 * Wrapper de compatibilidad para MP4Handler de hxcodec 2.5.1
 * Emula la API original usando FlxVideoSprite internamente
 */
class MP4Handler extends FlxSprite
{
	public var readyCallback:Void->Void;
	public var finishCallback:Void->Void;

	private var videoSprite:FlxVideoSprite;
	private var isCurrentlyPlaying:Bool = false;
	private var _volume:Float = 1.0;
	private static var instanceCounter:Int = 0;
	private var instanceId:Int;

	// Propiedades emuladas
	public var isPlaying(get, never):Bool;
	public var videoWidth(get, never):Int;
	public var videoHeight(get, never):Int;
	public var volume(get, set):Float;

	public function new(width:Int = 320, height:Int = 240, autoScale:Bool = true):Void
	{
		super();
		
		instanceId = ++instanceCounter;
		
		// Hacer invisible este sprite base
		makeGraphic(1, 1, 0x00FFFFFF);
		alpha = 0;
		visible = false;
		
		// NO añadir este sprite base al state
		
	}

	public function playVideo(path:String, repeat:Bool = false, pauseMusic:Bool = false):Void
	{
		
		if (FlxG.sound.music != null && pauseMusic)
			FlxG.sound.music.pause();

		// Determinar la ruta del video
		var videoPath = path;
		if (FileSystem.exists(Sys.getCwd() + path))
			videoPath = Sys.getCwd() + path;
		
		// Crear el FlxVideoSprite directamente
		if (videoSprite != null) {
			cleanupVideoSprite();
		}
		
		#if hxcodec
		videoSprite = new FlxVideoSprite(0, 0);
		var playResult = videoSprite.play(videoPath, repeat);
		
		if (playResult == 0) {
			// Video cargado exitosamente
			videoSprite.bitmap.onEndReached.add(onVideoFinished);
			
			// NO añadir automáticamente al state - el script maneja la visualización
			// Los scripts copian el bitmapData a su propio sprite
			
			// Centrar el video en pantalla (por si se añade manualmente)
			videoSprite.screenCenter();
			
			// Simular readyCallback
			if (readyCallback != null) {
				haxe.Timer.delay(readyCallback, 100);
			}
			
			isCurrentlyPlaying = true;
			
			// Configurar volumen inicial
			haxe.Timer.delay(updateVolumeInternal, 200);
		} else {
			trace('Error loading video: $videoPath');
			videoSprite = null;
		}
		#else
		trace('hxcodec not available');
		#end
	}

	private function onVideoFinished():Void
	{
		isCurrentlyPlaying = false;
		cleanupVideoSprite();

		if (finishCallback != null)
			finishCallback();
	}

	private function cleanupVideoSprite():Void
	{
		if (videoSprite != null) {
			// Remover callbacks
			#if hxcodec
			if (videoSprite.bitmap != null && videoSprite.bitmap.onEndReached != null) {
				videoSprite.bitmap.onEndReached.removeAll();
			}
			#end
			
			// Solo remover del state si está realmente añadido
			// (el MP4Handler no añade automáticamente, pero podría añadirse manualmente)
			if (FlxG.state.members.contains(videoSprite)) {
				FlxG.state.remove(videoSprite);
				trace('MP4Handler[${instanceId}]: Removed videoSprite from state');
			}
			
			videoSprite.destroy();
			videoSprite = null;
			trace('MP4Handler[${instanceId}]: VideoSprite cleaned up');
		}
	}

	private function updateVolumeInternal():Void
	{
		#if hxcodec
		if (videoSprite != null && videoSprite.bitmap != null) {
			var finalVolume = #if FLX_SOUND_SYSTEM 
				Std.int((FlxG.sound.muted ? 0 : 1) * (FlxG.sound.volume * _volume * 100))
			#else 
				Std.int(FlxG.sound.volume * _volume * 100)
			#end;
			
			videoSprite.bitmap.volume = finalVolume;
		}
		#end
	}

	public function finishVideo():Void 
	{
		#if hxcodec
		if (videoSprite != null) {
			videoSprite.stop();
			onVideoFinished();
		}
		#end
	}

	public function pause():Void 
	{
		#if hxcodec
		if (videoSprite != null) {
			videoSprite.pause();
		}
		#end
	}

	public function resume():Void 
	{
		#if hxcodec
		if (videoSprite != null) {
			videoSprite.resume();
		}
		#end
	}

	// Getters para propiedades emuladas
	private function get_isPlaying():Bool 
	{
		#if hxcodec
		return isCurrentlyPlaying && videoSprite != null;
		#else
		return false;
		#end
	}

	private function get_videoWidth():Int 
	{
		#if hxcodec
		if (videoSprite != null && videoSprite.bitmap != null)
			return Std.int(videoSprite.bitmap.width);
		#end
		return 0;
	}

	private function get_videoHeight():Int 
	{
		#if hxcodec
		if (videoSprite != null && videoSprite.bitmap != null)
			return Std.int(videoSprite.bitmap.height);
		#end
		return 0;
	}

	private function get_volume():Float 
	{
		return _volume;
	}

	private function set_volume(value:Float):Float 
	{
		_volume = value + 0.4; // Emular el comportamiento original
		updateVolumeInternal();
		return _volume;
	}

	// Propiedad bitmapData para compatibilidad con scripts
	public var bitmapData(get, never):openfl.display.BitmapData;
	private function get_bitmapData():openfl.display.BitmapData 
	{
		#if hxcodec
		if (videoSprite != null && videoSprite.bitmap != null)
			return videoSprite.bitmap.bitmapData;
		#end
		
		// Retornar un bitmap vacío en lugar de null para evitar errores
		if (_fallbackBitmap == null) {
			_fallbackBitmap = new openfl.display.BitmapData(1, 1, true, 0x00000000);
		}
		return _fallbackBitmap;
	}
	
	private var _fallbackBitmap:openfl.display.BitmapData;

	override function destroy():Void 
	{
		cleanupVideoSprite();
		
		if (_fallbackBitmap != null) {
			_fallbackBitmap.dispose();
			_fallbackBitmap = null;
		}
		
		super.destroy();
	}
}
