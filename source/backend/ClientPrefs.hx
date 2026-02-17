package backend;

import objects.Note;
import objects.Note;
import options.VisualsUISubState;
import options.NotesSubState;
import online.network.FunkinNetwork;
import online.GameClient;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;

import states.TitleState;

// Add a variable here and it will get automatically saved
class SaveVariables {
	public var downScroll:Bool = false;
	public var middleScroll:Bool = false;
	public var opponentStrums:Bool = true;
	public var showFPS:Bool = false;
	public var flashing:Bool = true;
	public var autoPause:Bool = true;
	public var antialiasing:Bool = true;
	public var noteSkin:String = 'Default';
	public var splashSkin:String = 'Psych';
	public var splashAlpha:Float = 0.6;
	public var holdSplashAlpha:Float = 0.6;
	public var holdAlpha:Float = 0.6;
	public var lowQuality:Bool = false;
	public var shaders:Bool = #if mobile false #else true #end;
	// public var cacheOnGPU:Bool = #if !switch false #else true #end;
	public var framerate:Int = #if mobile 60 #else 120 #end;
	public var camZooms:Bool = true;
	public var hideHud:Bool = false;
	public var noteOffset:Int = 0;

	public var arrowRGB:Array<Array<FlxColor>> = ClientPrefs.genArrowColors(4);
	public var arrowRGBMap:Map<String, Array<Array<FlxColor>>> = ClientPrefs.genArrowColorsExtraMap();

	public var arrowRGBPixel:Array<Array<FlxColor>> = ClientPrefs.genArrowColors(4, true);
	public var arrowRGBPixelMap:Map<String, Array<Array<FlxColor>>> = ClientPrefs.genArrowColorsExtraMap(true);

	public var ghostTapping:Bool = true;
	public var timeBarType:String = 'Time Left';
	public var scoreZoom:Bool = true;
	public var noReset:Bool = false;
	public var healthBarAlpha:Float = 1;
	public var hitsoundVolume:Float = 0;
	public var pauseMusic:String = 'Tea Time';
	public var checkForUpdates:Bool = true;
	public var comboStacking:Bool = true;
	public var gameplaySettings:Map<String, Dynamic> = [
		'scrollspeed' => 1.0,
		'scrolltype' => 'multiplicative',
		'songspeed' => 1.0,
		'healthgain' => 1.0,
		'healthloss' => 1.0,
		'instakill' => false,
		'practice' => false,
		'botplay' => false,
		'opponentplay' => false,
		'nobadnotes' => false,
		'mania' => '(Chart)',
		'scrollspeedbymania' => false
	];

	public var comboOffset:Array<Int> = [0, 0, 0, 0];
	public var ratingOffset:Int = 0;
	public final sickWindow:Int = 45;
	public final goodWindow:Int = 90;
	public final badWindow:Int = 135;
	public var safeFrames:Float = 10;
	public var discordRPC:Bool = true;
	// PSYCH ONLINE
	private var nickname:String = "Boyfriend";
	public var serverAddress:String = null;
	public var currentSkin:Array<String> = null;
	public var trustedSources:Array<String> = ["https://gamebanana.com/"];
	public var comboOffsetOP1:Array<Int> = [0, 0, 0, 0];
	public var comboOffsetOP2:Array<Int> = [0, 0, 0, 0];
	public var disableStrumMovement:Bool = false;
	public var unlockFramerate:Bool = false;
	public var debugMode:Bool = false;
	public var disableReplays:Bool = false;
	public var disableSubmiting:Bool = false;
	public var showNoteTiming:Bool = false;
	public var disableAutoDownloads:Bool = false;
	public var disableSongComments:Bool = false;
	public var disableFreeplayIcons:Bool = false;
	public var showFP:Bool = false;
	public var disableFreeplayAlphabet:Bool = false;
	public var disableLagDetection:Bool = false;
	public var groupSongsBy:String = 'Default';
	public var groupSongsValue:Int = 0;
	public var hiddenSongs:Array<String> = []; //format: 'songname-originfolder'
	public var favSongs:Array<String> = []; //format: 'songname-originfolder'
	public var modchartSkinChanges:Bool = false;
	public var colorRating:Bool = false;
	public var notifyOnChatMsg:Bool = false;
	public var disablePMs:Bool = false;
	public var disableRoomInvites:Bool = false;
	public var verifySSL:Bool = false;
	public var noteUnderlayOpacity:Float = 0;
	public var noteUnderlayType:String = 'All-In-One';
	public var favsAsMenuTheme:Bool = false;
	public var disableComboRating:Bool = false;
	public var disableComboCounter:Bool = false;
	public var networkServerAddress:String = null;
	public var hiddenTips:Array<String> = null;
	public var nameplateFadeTime:Float = 10;
	public var verticalRatingPos:Bool = false;
	public var midSongCommentsOpacity:Float = 0.5;
	public var friendOnlineNotification:Bool = false;
	public var newFPPreview:Bool = false;
	public var camShakes:Bool = true;
	public var camAngles:Bool = true;
	public var camMovement:Bool = true;

	public function new()
	{
		//Why does haxe needs this again?
	}
}

class ClientPrefs {
	public static var data:SaveVariables = null;
	public static var defaultData:SaveVariables = null;

	//Every key has two binds, add your key bind down here and then add your control on options/ControlsSubState.hx and Controls.hx
	public static var keyBinds:Map<String, Array<FlxKey>> = [
		//Key Bind, Name for ControlsSubState
		'note_up'		=> [W, UP],
		'note_left'		=> [A, LEFT],
		'note_down'		=> [S, DOWN],
		'note_right'	=> [D, RIGHT],

		'5k_note_1'    	=> [D],
		'5k_note_2'    	=> [F],
		'5k_note_3'    	=> [G, SPACE],
		'5k_note_4'     => [J],
		'5k_note_5'     => [K],
    
		'6k_note_1'     => [S],
		'6k_note_2'     => [D],
		'6k_note_3'     => [F],
		'6k_note_4'     => [J],
		'6k_note_5'     => [K],
		'6k_note_6'     => [L],
    
		'7k_note_1'     => [S],
		'7k_note_2'     => [D],
		'7k_note_3'     => [F],
		'7k_note_4'     => [G, SPACE],
		'7k_note_5'     => [J],
		'7k_note_6'     => [K],
		'7k_note_7'     => [L],
    
		'8k_note_1'     => [A],
		'8k_note_2'     => [S],
		'8k_note_3'     => [D],
		'8k_note_4'     => [F],
		'8k_note_5'     => [H],
		'8k_note_6'     => [J],
		'8k_note_7'     => [K],
		'8k_note_8'     => [L],

		'9k_note_1'     => [A],
		'9k_note_2'     => [S],
		'9k_note_3'     => [D],
		'9k_note_4'     => [F],
		'9k_note_5'     => [G, SPACE],
		'9k_note_6'     => [H],
		'9k_note_7'     => [J],
		'9k_note_8'     => [K],
		'9k_note_9'     => [L],
		
		'ui_up'			=> [W, UP],
		'ui_left'		=> [A, LEFT],
		'ui_down'		=> [S, DOWN],
		'ui_right'		=> [D, RIGHT],
		
		'accept'		=> [SPACE, ENTER],
		'back'			=> [BACKSPACE, ESCAPE],
		'pause'			=> [ENTER, ESCAPE],
		'reset'			=> [R],
		'taunt'			=> [SPACE, T],
		'sidebar'		=> [GRAVEACCENT],
		'fav'			=> [Q],
		
		'volume_mute'	=> [ZERO],
		'volume_up'		=> [NUMPADPLUS, PLUS],
		'volume_down'	=> [NUMPADMINUS, MINUS],
		
		'debug_1'		=> [SEVEN],
		'debug_2'		=> [EIGHT]
	];
	public static var gamepadBinds:Map<String, Array<FlxGamepadInputID>> = [
		'note_up'		=> [DPAD_UP, Y],
		'note_left'		=> [DPAD_LEFT, X],
		'note_down'		=> [DPAD_DOWN, A],
		'note_right'	=> [DPAD_RIGHT, B],

		'5k_note_1'     => [DPAD_LEFT, X],
		'5k_note_2'    	=> [DPAD_DOWN, A],
		'5k_note_3'    	=> [LEFT_SHOULDER, RIGHT_SHOULDER],
		'5k_note_4'     => [DPAD_UP, Y],
		'5k_note_5'     => [DPAD_RIGHT, B],
    
		'6k_note_1'     => [DPAD_LEFT],
		'6k_note_2'     => [DPAD_DOWN],
		'6k_note_3'     => [DPAD_RIGHT],
		'6k_note_4'     => [X],
		'6k_note_5'     => [Y],
		'6k_note_6'     => [B],
    
		'7k_note_1'     => [DPAD_LEFT],
		'7k_note_2'     => [DPAD_DOWN],
		'7k_note_3'     => [DPAD_RIGHT],
		'7k_note_4'     => [LEFT_SHOULDER, RIGHT_SHOULDER],
		'7k_note_5'     => [X],
		'7k_note_6'     => [Y],
		'7k_note_7'     => [B],
    
		'8k_note_1'     => [DPAD_LEFT],
		'8k_note_2'     => [DPAD_DOWN],
		'8k_note_3'     => [DPAD_UP],
		'8k_note_4'     => [DPAD_RIGHT],
		'8k_note_5'     => [X],
		'8k_note_6'     => [A],
		'8k_note_7'     => [Y],
		'8k_note_8'     => [B],

		'9k_note_1'     => [DPAD_LEFT],
		'9k_note_2'     => [DPAD_DOWN],
		'9k_note_3'     => [DPAD_UP],
		'9k_note_4'     => [DPAD_RIGHT],
		'9k_note_5'     => [LEFT_SHOULDER, RIGHT_SHOULDER],
		'9k_note_6'     => [X],
		'9k_note_7'     => [A],
		'9k_note_8'     => [Y],
		'9k_note_9'     => [B],
		
		'ui_up'			=> [DPAD_UP, LEFT_STICK_DIGITAL_UP],
		'ui_left'		=> [DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT],
		'ui_down'		=> [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN],
		'ui_right'		=> [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT],
		
		'accept'		=> [A, START],
		'back'			=> [B],
		'pause'			=> [START],
		'reset'			=> [BACK],
		'taunt'			=> [RIGHT_STICK_CLICK],
		'sidebar'		=> [],
		'fav'			=> [Y]
	];
	public static var defaultKeys:Map<String, Array<FlxKey>> = null;
	public static var defaultButtons:Map<String, Array<FlxGamepadInputID>> = null;

	public static function resetKeys(controller:Null<Bool> = null) //Null = both, False = Keyboard, True = Controller
	{
		if(controller != true)
		{
			for (key in keyBinds.keys())
			{
				if(defaultKeys.exists(key))
					keyBinds.set(key, defaultKeys.get(key).copy());
			}
		}
		if(controller != false)
		{
			for (button in gamepadBinds.keys())
			{
				if(defaultButtons.exists(button))
					gamepadBinds.set(button, defaultButtons.get(button).copy());
			}
		}
	}

	public static function clearInvalidKeys(key:String) {
		var keyBind:Array<FlxKey> = keyBinds.get(key);
		var gamepadBind:Array<FlxGamepadInputID> = gamepadBinds.get(key);
		while(keyBind != null && keyBind.contains(NONE)) keyBind.remove(NONE);
		while(gamepadBind != null && gamepadBind.contains(NONE)) gamepadBind.remove(NONE);
	}

	public static function loadDefaultKeys() {
		defaultKeys = keyBinds.copy();
		defaultButtons = gamepadBinds.copy();
	}

	public static function saveSettings() {
		for (key in Reflect.fields(data)) {
			//trace('saved variable: $key');
			Reflect.setField(FlxG.save.data, key, Reflect.field(data, key));
		}
		#if ACHIEVEMENTS_ALLOWED Achievements.save(); #end
		FlxG.save.flush();

		//Placing this in a separate save so that it can be manually deleted without removing your Score and stuff
		var save:FlxSave = new FlxSave();
		save.bind('controls_v3', CoolUtil.getSavePath());
		save.data.keyboard = keyBinds;
		save.data.gamepad = gamepadBinds;
		save.flush();
		FlxG.log.add("Settings saved!");
	}

	public static function loadPrefs() {
		if(data == null) data = new SaveVariables();
		if(defaultData == null) defaultData = new SaveVariables();

		function getPsycheSavePath() {
			return #if (flixel < "5.0.0") 'ShadowMario' #else 'ShadowMario/PsychEngine' #end;
		}

		if (Reflect.fields(FlxG.save.data).length == 0) {
			var psychEngineSave:FlxSave = new FlxSave();
			psychEngineSave.bind('funkin', getPsycheSavePath());
			for (key in Reflect.fields(psychEngineSave.data)) {
				Reflect.setField(FlxG.save.data, key, Reflect.field(psychEngineSave.data, key));
			}
			psychEngineSave.flush();
			FlxG.save.flush();
		}

		for (key in Reflect.fields(data)) {
			if (key != 'gameplaySettings' && Reflect.hasField(FlxG.save.data, key)) {
				//trace('loaded variable: $key');
				Reflect.setField(data, key, Reflect.field(FlxG.save.data, key));
			}
		}
		
		data.arrowRGBMap ??= new Map();
		for (key => value in defaultData.arrowRGBMap) {
			if (!data.arrowRGBMap.exists(key))
				data.arrowRGBMap.set(key, value);
		}

		data.arrowRGBPixelMap ??= new Map();
		for (key => value in defaultData.arrowRGBPixelMap) {
			if (!data.arrowRGBPixelMap.exists(key))
				data.arrowRGBPixelMap.set(key, value);
		}
		
		if(Main.fpsVar != null) {
			Main.fpsVar.visible = data.showFPS;
		}

		#if (!html5 && !switch)
		FlxG.autoPause = ClientPrefs.data.autoPause;
		#end

		FlxSprite.defaultAntialiasing = ClientPrefs.data.antialiasing;

		if (ClientPrefs.data.unlockFramerate) {
			FlxG.updateFramerate = 1000;
			FlxG.drawFramerate = 1000;
		} else if(data.framerate > FlxG.drawFramerate) {
			FlxG.updateFramerate = data.framerate;
			FlxG.drawFramerate = data.framerate;
		} else {
			FlxG.drawFramerate = data.framerate;
			FlxG.updateFramerate = data.framerate;
		}

		sys.ssl.Socket.DEFAULT_VERIFY_CERT = ClientPrefs.data.verifySSL;

		if(FlxG.save.data.gameplaySettings != null) {
			var savedMap:Map<String, Dynamic> = FlxG.save.data.gameplaySettings;
			for (name => value in savedMap)
				data.gameplaySettings.set(name, value);
		}
		
		// flixel automatically saves your volume!
		if(FlxG.save.data.volume != null)
			FlxG.sound.volume = FlxG.save.data.volume;
		if (FlxG.save.data.mute != null)
			FlxG.sound.muted = FlxG.save.data.mute;

		#if DISCORD_ALLOWED
		DiscordClient.check();
		#end

		// controls on a separate save file
		var save:FlxSave = new FlxSave();
		save.bind('controls_v3', CoolUtil.getSavePath());

		if (Reflect.fields(save).length == 0) {
			var psychEngineSaveControls:FlxSave = new FlxSave();
			psychEngineSaveControls.bind('controls_v3', getPsycheSavePath());
			for (key in Reflect.fields(psychEngineSaveControls.data)) {
				Reflect.setField(save.data, key, Reflect.field(psychEngineSaveControls.data, key));
			}
			psychEngineSaveControls.flush();
			save.flush();
		}

		if(save != null)
		{
			if(save.data.keyboard != null) {
				var loadedControls:Map<String, Array<FlxKey>> = save.data.keyboard;
				for (control => keys in loadedControls) {
					/*if(keyBinds.exists(control))*/ keyBinds.set(control, keys);
				}
			}
			if(save.data.gamepad != null) {
				var loadedControls:Map<String, Array<FlxGamepadInputID>> = save.data.gamepad;
				for (control => keys in loadedControls) {
					/*if(gamepadBinds.exists(control))*/ gamepadBinds.set(control, keys);
				}
			}
			reloadVolumeKeys();
		}

		//away3d.debug.Debug.active = ClientPrefs.isDebug();
	}

	public static function getGameplaySetting(name:String, defaultValue:Dynamic = null, ?customDefaultValue:Bool = false):Dynamic {
		if (data.gameplaySettings.get('scrollspeedbymania') && (name == 'scrollspeed' || name == 'scrolltype')) {
			var v = ClientPrefs.getGameplaySetting(name + '_' + Note.maniaKeys + 'k');
			if (v != null)
				return v;
			else {
				switch (name) {
					case 'scrollspeed':
						return 1;
					case 'scrolltype':
						return 'multiplicative';
				}
			}
		}

		if(!customDefaultValue) defaultValue = defaultData.gameplaySettings.get(name);
		var daGameplaySetting:Dynamic = GameClient.isConnected() ? GameClient.getGameplaySetting(name) : data.gameplaySettings.get(name);
		if (PlayState.replayData?.gameplay_modifiers != null) {
			daGameplaySetting = PlayState.replayData?.gameplay_modifiers?.get(name);
		}
		return /*PlayState.isStoryMode ? defaultValue : */ (daGameplaySetting != null ? daGameplaySetting : defaultValue);
	}

	public static function reloadVolumeKeys() {
		TitleState.muteKeys = keyBinds.get('volume_mute').copy();
		TitleState.volumeDownKeys = keyBinds.get('volume_down').copy();
		TitleState.volumeUpKeys = keyBinds.get('volume_up').copy();
		toggleVolumeKeys(true);
	}
	public static function toggleVolumeKeys(turnOn:Bool) {
		if(turnOn)
		{
			FlxG.sound.muteKeys = TitleState.muteKeys;
			FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
			FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;
		}
		else
		{
			FlxG.sound.muteKeys = [];
			FlxG.sound.volumeDownKeys = [];
			FlxG.sound.volumeUpKeys = [];
		}
	}
	public static function isDebug() {
		#if debug
		return true;
		#end

		if (PlayState.chartingMode)
			return true;
		
		return data?.debugMode ?? false;
	}

	public static function getNickname() {
		if (FunkinNetwork.loggedIn)
			return FunkinNetwork.nickname;

		@:privateAccess
		return data.nickname;
	}

	public static function setNickname(name) {
		if (FunkinNetwork.loggedIn)
			return FunkinNetwork.updateName(name);

		if (name == "")
			return @:privateAccess data.nickname = "Boyfriend";

		return @:privateAccess data.nickname = name;
	}

	public static function getGhostTapping() {
		return PlayState.replayData?.ghost_tapping ?? data.ghostTapping;
	}

	public static function getRatingOffset() {
		return PlayState.replayData?.rating_offset ?? data.ratingOffset;
	}

	public static function getSafeFrames() {
		return PlayState.replayData?.safe_frames ?? data.safeFrames;
	}

	public static function getRGBColor(player:Int = 0):Array<Array<FlxColor>> {
		if (!GameClient.isConnected() || NotesSubState.isOpened || player == -1)
			return (Note.maniaKeys != 4 ? data.arrowRGBMap.get(Note.maniaKeys + 'k') : data.arrowRGB);

		if (player == 0)
			return CoolUtil.to2DArrayfrom1D(CoolUtil.asta(GameClient.getPlayerSelf().arrowColors.get(Note.maniaKeys + 'k').value), 3);

		if (PlayState.instance?.opponentPlayer == null)
			return getRGBColorDefault();
		
		// TODO support seperate mania from both strums
		// var opKeys = PlayState.instance.opponentPlayer.gameplaySettings.get('mania') ?? (Note.maniaKeys + 'k');
		return CoolUtil.to2DArrayfrom1D(CoolUtil.asta(PlayState.instance.opponentPlayer.arrowColors.get(Note.maniaKeys + 'k').value), 3);
	}

	public static function getRGBColorDefault(?variant:String) {
		if (variant == 'pixel')
			return (Note.maniaKeys != 4 ? defaultData.arrowRGBPixelMap.get(Note.maniaKeys + 'k') : defaultData.arrowRGBPixel);

		return (Note.maniaKeys != 4 ? defaultData.arrowRGBMap.get(Note.maniaKeys + 'k') : defaultData.arrowRGB);
	}

	public static function getRGBPixelColor(player:Int = 0):Array<Array<FlxColor>> {
		if (!GameClient.isConnected() || NotesSubState.isOpened || player == -1)
			return (Note.maniaKeys != 4 ? data.arrowRGBPixelMap.get(Note.maniaKeys + 'k') : data.arrowRGBPixel);

		if (player == 0)
			return CoolUtil.to2DArrayfrom1D(CoolUtil.asta(GameClient.getPlayerSelf().arrowColorsPixel.get(Note.maniaKeys + 'k').value), 3);

		if (PlayState.instance?.opponentPlayer == null)
			return getRGBColorDefault('pixel');

		// var opKeys = PlayState.instance.opponentPlayer.gameplaySettings.get('mania') ?? (Note.maniaKeys + 'k');
		return CoolUtil.to2DArrayfrom1D(CoolUtil.asta(PlayState.instance.opponentPlayer.arrowColorsPixel.get(Note.maniaKeys + 'k').value), 3);
	}

	public static function getNoteSkin(player:Int = 0):String
	{
		if(!GameClient.isConnected() || NotesSubState.isOpened || VisualsUISubState.isOpened || player == -1)
			return data.noteSkin;

		if(player == 0)
			return GameClient.getPlayerSelf().noteSkin;
		else
			return PlayState.instance?.opponentPlayer?.noteSkin ?? defaultData.noteSkin;
	}

	public static function getArrowRGBCompleteMaps():Array<Map<String, Array<Array<FlxColor>>>> {
		var copyRGBMap = ClientPrefs.data.arrowRGBMap.copy();
		copyRGBMap.set('4k', ClientPrefs.data.arrowRGB);
		var copyRGBPixelMap = ClientPrefs.data.arrowRGBPixelMap.copy();
		copyRGBPixelMap.set('4k', ClientPrefs.data.arrowRGBPixel);
		return [copyRGBMap, copyRGBPixelMap];
	}

	public static inline function genArrowColors(keys:Int, ?isPixel:Bool = false):Array<Array<FlxColor>> {
		var colColors = isPixel ? [
			'purple' => [0xFFE276FF, 0xFFFFF9FF, 0xFF60008D],
			'blue' => [0xFF3DCAFF, 0xFFF4FFFF, 0xFF003060],
			'odd' => [0xFFFFE600, 0xFFFFF5F0, 0xFF754D10],
			'green' => [0xFF71E300, 0xFFF6FFE6, 0xFF003100],
			'red' => [0xFFFF884E, 0xFFFFFAF5, 0xFF6C0000]
		] : [
			'purple' => [0xFFC24B99, 0xFFFFFFFF, 0xFF3C1F56],
			'blue' => [0xFF00FFFF, 0xFFFFFFFF, 0xFF1542B7],
			'odd' => [0xFFFFE600, 0xFFFFFFFF, 0xFF754D10],
			'green' => [0xFF12FA05, 0xFFFFFFFF, 0xFF0A4447],
			'red' => [0xFFF9393F, 0xFFFFFFFF, 0xFF651038]
		];
		var arr = [];
		var colArray = Note.getColArrayFromKeys(keys);
		for (key in 0...keys) {
			arr.push(colColors.get(colArray[key]));
		}
		return arr;
	}

	public static inline function genArrowColorsExtraMap(?isPixel:Bool = false):Map<String, Array<Array<FlxColor>>> {
		var map = new Map();
		for (keys in Note.maniaKeysList) {
			if (keys == 4)
				continue;
			map.set('${keys}k', genArrowColors(keys, isPixel));
		}
		return map;
	}
}
