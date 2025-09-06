package objects;

import flixel.FlxG;
import flixel.FlxSprite;
import openfl.Lib;
import openfl.events.Event;
import openfl.display.BitmapData;
import sys.FileSystem;

#if hxcodec
import hxcodec.flixel.FlxVideoSprite;
#end

/**
 * Wrapper de compatibilidad para VideoHandler de hxcodec 2.6.0
 * Emula la API original usando FlxVideoSprite internamente
 */
class VideoHandler extends FlxSprite
{
	public var canSkip:Bool = true;
	public var canUseSound:Bool = true;
	public var canUseAutoResize:Bool = true;

	public var openingCallback:Void->Void = null;
	public var finishCallback:Void->Void = null;

	private var pauseMusic:Bool = false;
	private var videoSprite:FlxVideoSprite;
	private var isCurrentlyPlaying:Bool = false;
	private var updateListener:Event->Void;
	private var allowDestroy:Bool = false; // Prevenir destrucción prematura
	private var preventExternalDestroy:Bool = false; // Prevenir destrucción externa
	private static var instanceCounter:Int = 0;
	private var instanceId:Int;

	// Propiedades emuladas de VLC
	public var isPlaying(get, never):Bool;
	public var isDisplaying(get, never):Bool;
	public var videoWidth(get, never):Int;
	public var videoHeight(get, never):Int;
	public var volume(get, set):Float;

	private var _volume:Float = 1.0;

	public function new(IndexModifier:Int = 0):Void
	{
		super();
		
		instanceId = ++instanceCounter;
		
		// Hacer invisible este sprite base, el video se renderiza en videoSprite
		makeGraphic(1, 1, 0x00FFFFFF);
		alpha = 0;
		visible = false;
		
		// Marcar como persistente para evitar destrucción automática
		this.active = true;
		this.exists = true;
		
		// Setup del listener de update
		updateListener = updateVideo;
	
	}

	/**
	 * Plays a video.
	 *
	 * @param Path Example: `your/video/here.mp4`
	 * @param Loop Loop the video.
	 * @param PauseMusic Pause music until the video ends.
	 */
	public function playVideo(Path:String, Loop:Dynamic = false, PauseMusic:Dynamic = false):Void
	{
		
		var loopBool:Bool = false;
		var pauseBool:Bool = false;
		
		// Convertir los parámetros a booleanos (compatibilidad con Lua)
		if (Std.isOfType(Loop, Bool)) {
			loopBool = Loop;
		} else if (Std.isOfType(Loop, Int)) {
			loopBool = Loop != 0;
		} else if (Std.isOfType(Loop, String)) {
			loopBool = Loop == "true" || Loop == "1";
		}
		
		if (Std.isOfType(PauseMusic, Bool)) {
			pauseBool = PauseMusic;
		} else if (Std.isOfType(PauseMusic, Int)) {
			pauseBool = PauseMusic != 0;
		} else if (Std.isOfType(PauseMusic, String)) {
			pauseBool = PauseMusic == "true" || PauseMusic == "1";
		}


		pauseMusic = pauseBool;

		if (FlxG.sound.music != null && pauseBool)
			FlxG.sound.music.pause();

		FlxG.stage.addEventListener(Event.ENTER_FRAME, updateListener);

		if (FlxG.autoPause)
		{
			FlxG.signals.focusGained.add(resume);
			FlxG.signals.focusLost.add(pause);
		}

		// Determinar la ruta del video
		var videoPath = Path;
		if (FileSystem.exists(Sys.getCwd() + Path))
			videoPath = Sys.getCwd() + Path;
		
		
		// Crear el FlxVideoSprite directamente
		if (videoSprite != null) {
			cleanupVideoSprite();
		}
		
		#if hxcodec
		videoSprite = new FlxVideoSprite(0, 0);
		var playResult = videoSprite.play(videoPath, loopBool);
		
		if (playResult == 0) {
			// Video cargado exitosamente
			
			// Registrar tiempo de inicio
			videoStartTime = haxe.Timer.stamp();
			
			// NO añadir el videoSprite al state directamente
			// El script lo manejará a través del bitmapData
			
			// Centrar el video en pantalla (pero sin añadirlo al state)
			videoSprite.screenCenter();
			
			// Simular el callback de opening
			if (openingCallback != null) {
				haxe.Timer.delay(openingCallback, 100);
			}
			
			isCurrentlyPlaying = true;
			
			// Permitir destrucción después de un tiempo mínimo
			haxe.Timer.delay(function() {
				allowDestroy = true;
			}, 2000);
			
			// NO añadir el callback onEndReached automáticamente
			// Dejar que el script maneje el ciclo de vida del video
			
			// Configurar volumen inicial
			haxe.Timer.delay(updateVolumeInternal, 200);
		} else {
			trace('VideoHandler: Error loading video: $videoPath, result code: $playResult');
			videoSprite = null;
		}
		#else
		trace('VideoHandler: hxcodec not available');
		#end
	}

	private var videoStartTime:Float = 0;

	private function onVLCEndReached():Void
	{
		
		// Evitar llamadas múltiples
		if (!isCurrentlyPlaying) {
			return;
		}
		
		// Verificar que haya pasado suficiente tiempo desde que comenzó el video
		var currentTime = haxe.Timer.stamp();
		if (currentTime - videoStartTime < 1.0) { // Al menos 1 segundo
			return;
		}
		
		// Verificar que se permita la destrucción
		if (!allowDestroy) {
			return;
		}
		
		if (FlxG.sound.music != null && pauseMusic)
			FlxG.sound.music.resume();

		if (FlxG.stage.hasEventListener(Event.ENTER_FRAME))
			FlxG.stage.removeEventListener(Event.ENTER_FRAME, updateListener);

		if (FlxG.autoPause)
		{
			if (FlxG.signals.focusGained.has(resume))
				FlxG.signals.focusGained.remove(resume);

			if (FlxG.signals.focusLost.has(pause))
				FlxG.signals.focusLost.remove(pause);
		}

		isCurrentlyPlaying = false;
		cleanupVideoSprite();

		if (finishCallback != null)
			finishCallback();
	}

	private function cleanupVideoSprite():Void
	{
		trace(haxe.CallStack.toString(haxe.CallStack.callStack()));
		
		// No permitir cleanup si no se ha autorizado
		if (!allowDestroy) {
			return;
		}
		
		if (videoSprite != null) {
			// Remover callbacks
			#if hxcodec
			if (videoSprite.bitmap != null && videoSprite.bitmap.onEndReached != null) {
				videoSprite.bitmap.onEndReached.removeAll();
			}
			#end
			
			// NO intentar remover del state ya que no lo añadimos directamente
			
			videoSprite.destroy();
			videoSprite = null;
			trace('VideoHandler: Video sprite destroyed and set to null');
		} else {
			trace('VideoHandler: No video sprite to clean up');
		}
	}

	private function updateVideo(?E:Event):Void
	{
		#if FLX_KEYBOARD
		if (canSkip && (FlxG.keys.justPressed.SPACE #if android || FlxG.android.justReleased.BACK #end) && (isPlaying && isDisplaying))
			onVLCEndReached();
		#elseif android
		if (canSkip && FlxG.android.justReleased.BACK && (isPlaying && isDisplaying))
			onVLCEndReached();
		#end

		if (canUseAutoResize && videoSprite != null && videoSprite.bitmap != null)
		{
			var newWidth = calcSize(0);
			var newHeight = calcSize(1);
			
			if (newWidth > 0 && newHeight > 0) {
				videoSprite.setGraphicSize(newWidth, newHeight);
				videoSprite.updateHitbox();
				videoSprite.screenCenter();
			}
		}

		// Actualizar volumen
		updateVolumeInternal();
	}

	private function updateVolumeInternal():Void
	{
		#if hxcodec
		if (videoSprite != null && videoSprite.bitmap != null) {
			var finalVolume = #if FLX_SOUND_SYSTEM 
				Std.int(((FlxG.sound.muted || !canUseSound) ? 0 : 1) * (FlxG.sound.volume * _volume * 100))
			#else 
				Std.int(FlxG.sound.volume * _volume * 100)
			#end;
			
			videoSprite.bitmap.volume = finalVolume;
		}
		#end
	}

	public function calcSize(Ind:Int):Int
	{
		var appliedWidth:Float = Lib.current.stage.stageHeight * (FlxG.width / FlxG.height);
		var appliedHeight:Float = Lib.current.stage.stageWidth * (FlxG.height / FlxG.width);

		if (appliedHeight > Lib.current.stage.stageHeight)
			appliedHeight = Lib.current.stage.stageHeight;

		if (appliedWidth > Lib.current.stage.stageWidth)
			appliedWidth = Lib.current.stage.stageWidth;

		switch (Ind)
		{
			case 0:
				return Std.int(appliedWidth);
			case 1:
				return Std.int(appliedHeight);
		}

		return 0;
	}

	// Métodos de control de reproducción
	public function pause():Void 
	{
		#if hxcodec
		if (videoSprite != null) {
			videoSprite.pause();
		} else {
			trace('VideoHandler[${instanceId}]: Cannot pause - videoSprite is null');
		}
		#else
		trace('VideoHandler[${instanceId}]: Cannot pause - hxcodec not available');
		#end
	}

	public function resume():Void 
	{
		#if hxcodec
		if (videoSprite != null) {
			videoSprite.resume();
		} else {
			trace('VideoHandler[${instanceId}]: Cannot resume - videoSprite is null');
		}
		#else
		trace('VideoHandler[${instanceId}]: Cannot resume - hxcodec not available');
		#end
	}

	public function stop():Void 
	{
		#if hxcodec
		if (videoSprite != null) {
			videoSprite.stop();
			if (isCurrentlyPlaying) {
				onVLCEndReached();
			}
		} else {
			trace('VideoHandler[${instanceId}]: Cannot stop - videoSprite is null');
		}
		#else
		trace('VideoHandler[${instanceId}]: Cannot stop - hxcodec not available');
		#end
	}

	// Getters para propiedades emuladas
	private function get_isPlaying():Bool 
	{
		var playing = false;
		#if hxcodec
		playing = isCurrentlyPlaying && videoSprite != null;
		#else
		playing = false;
		#end
		return playing;
	}

	private function get_isDisplaying():Bool 
	{
		var displaying = isPlaying;
		return displaying;
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
		_volume = value;
		updateVolumeInternal();
		return _volume;
	}

	// Métodos para emular VLC
	public function dispose():Void 
	{
		cleanupVideoSprite();
	}

	public function finishVideo():Void 
	{
		#if hxcodec
		if (videoSprite != null) {
			videoSprite.stop();
			onVLCEndReached();
		}
		#end
	}
	
	// Método para verificar si el VideoHandler es válido
	public function isValid():Bool 
	{
		var valid = videoSprite != null && !allowDestroy;
		return valid;
	}
	
	// Método para configurar el callback de fin manualmente
	public function setupEndCallback():Void 
	{
		#if hxcodec
		if (videoSprite != null && videoSprite.bitmap != null && isCurrentlyPlaying) {
			videoSprite.bitmap.onEndReached.add(onVLCEndReached);
		}
		#end
	}
	
	// Método para permitir destrucción manual
	public function allowDestruction():Void 
	{
		allowDestroy = true;
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
		
		// Bloquear destrucción si no está permitida
		if (!allowDestroy) {
			return;
		}
		
		if (FlxG.stage.hasEventListener(Event.ENTER_FRAME))
			FlxG.stage.removeEventListener(Event.ENTER_FRAME, updateListener);

		if (FlxG.autoPause)
		{
			if (FlxG.signals.focusGained.has(resume))
				FlxG.signals.focusGained.remove(resume);

			if (FlxG.signals.focusLost.has(pause))
				FlxG.signals.focusLost.remove(pause);
		}

		cleanupVideoSprite();
		
		if (_fallbackBitmap != null) {
			_fallbackBitmap.dispose();
			_fallbackBitmap = null;
		}
		
		super.destroy();
	}
	
	// Sobrescribir update para compatibilidad con scripts antiguos
	override public function update(elapsed:Float):Void 
	{
		super.update(elapsed);
		// El script lua puede llamar FlxG.stage.removeEventListener("enterFrame", video.update)
		// pero esto no afecta nuestro funcionamiento interno ya que usamos updateListener
	}
}
