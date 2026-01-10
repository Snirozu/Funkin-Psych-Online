package online.backend;

import CompileTime;

class Deflection {
	//@:unreflective public static final luaClassBlacklist:Array<String> = ['cpp', 'lib', 'reflect', 'cffi', 'process', 'lua', 'http'];
    @:unreflective public static var classBlacklist(get, default):Array<Class<Dynamic>> = null;
	public static var CLASS_ALIASES:Map<String, String> = [
		"Achievements" => "backend.Achievements",
		"AchievementsMenuState" => "",
		"Alphabet" => "objects.Alphabet",
		"AttachedSprite" => "objects.AttachedSprite",
		"AttachedText" => "objects.AttachedText",
		"BGSprite" => "objects.BGSprite",
		"BackgroundDancer" => "states.stages.objects.BackgroundDancer",
		"BackgroundGirls" => "states.stages.objects.BackgroundGirls",
		"BlendModeEffect" => "shaders.BlendModeEffect",
		"Boyfriend" => "objects.Character",
		"ButtonRemapSubstate" => "",
		"Character" => "objects.Character",
		// "ChartParser" => "", // removed?
		"CheckboxThingie" => "objects.CheckboxThingie",
		"ClientPrefs" => "backend.ClientPrefs",
		"ColorSwap" => "shaders.ColorSwap",
		"Conductor" => "backend.Conductor",
		"Controls" => "backend.Controls",
		"CoolUtil" => "backend.CoolUtil",
		"CreditsState" => "states.CreditsState",
		"CustomFadeTransition" => "backend.CustomFadeTransition",
		"CutsceneHandler" => "cutscenes.CutsceneHandler",
		"DialogueBox" => "cutscenes.DialogueBox",
		"DialogueBoxPsych" => "cutscenes.DialogueBoxPsych",
		"Discord" => "backend.Discord",
		"FlashingState" => "states.FlashingState",
		"FlxUIDropDownMenuCustom" => "objects.FlxScrollableDropDownMenu",
		"FreeplayState" => "states.FreeplayState",
		"FunkinLua" => "psychlua.FunkinLua",
		"GameOverSubstate" => "substates.GameOverSubstate",
		"GameplayChangersSubstate" => "substates.GameplayChangersSubstate",
		// "GitarooPause" => "", // removed
		"HealthIcon" => "objects.HealthIcon",
		"Highscore" => "backend.Highscore",
		"InputFormatter" => "backend.InputFormatter",
		// "LatencyState" => "", // removed
		"LoadingState" => "states.LoadingState",
		"MainMenuState" => "states.MainMenuState",
		"MenuCharacter" => "objects.MenuCharacter",
		"MenuItem" => "objects.MenuItem",
		"ModsMenuState" => "states.ModsMenuState",
		"MusicBeatState" => "backend.MusicBeatState",
		"MusicBeatSubstate" => "backend.MusicBeatSubstate",
		"Note" => "objects.Note",
		"NoteSplash" => "objects.NoteSplash",
		"OutdatedState" => "states.OutdatedState",
		"OverlayShader" => "shaders.OverlayShader",
		"Paths" => "backend.Paths",
		"PauseSubState" => "substates.PauseSubState",
		"PhillyGlowParticle" => "states.stages.objects.PhillyGlowParticle",
		"PhillyGlowGradient" => "states.stages.objects.PhillyGlowGradient",
		"PlayState" => "states.PlayState",
		// "PlayerSettings" => "", // whatever this is
		"Prompt" => "substates.Prompt",
		"ResetScoreSubState" => "substates.ResetScoreSubState",
		"Section" => "backend.Section",
		// "Snd" => "", // unused
		// "SndTV" => "",
		"Song" => "backend.Song",
		"StageData" => "backend.StageData",
		"StoryMenuState" => "states.StoryMenuState",
		"StrumNote" => "objects.StrumNote",
		"TankmenBG" => "states.stages.objects.TankmenBG",
		"TitleState" => "states.TitleState",
		"TypedAlphabet" => "objects.TypedAlphabet",
		"WeekData" => "backend.WeekData",
		"WiggleEffect" => "shaders.WiggleEffect",
	];

    public static function resolveClass(clsName:String):Class<Dynamic> {
		var aliasFound = CLASS_ALIASES.get(clsName);
		if (aliasFound != null) {
			clsName = aliasFound;
		}

		var cls = Type.resolveClass(clsName);

		// if (clsName == 'hxcodec.flixel.FlxVideo' || clsName == 'vlc.MP4Handler') {
		// 	return online.backend.wrapper.FlxVideoWrapper;
		// }

		if (classBlacklist.contains(cls)) {
			PlayState.instance.addTextToDebug(clsName + ' is not accessible!', FlxColor.RED);
            return null;
		}

		return cls;
    }

	private static function get_classBlacklist() {
		if (classBlacklist == null)
			initClassBlacklist();
		return classBlacklist;
	}

    private static function initClassBlacklist() {
		var blacklist:Array<Class<Dynamic>> = [];

		// Add blacklisting for prohibited classes and packages.

		// `Sys`
		// Sys.command() can run malicious processes
		blacklist.push(Sys);

		// `Reflect`
		// Reflect.callMethod() can access blacklisted packages
		blacklist.push(Reflect);

		// `Type`
		// Type.createInstance(Type.resolveClass()) can access blacklisted packages
		blacklist.push(Type);

		// `cpp.Lib`
		// Lib.load() can load malicious DLLs
		blacklist.push(cpp.Lib);

		// `haxe.Unserializer`
		// Unserializerr.DEFAULT_RESOLVER.resolveClass() can access blacklisted packages
		blacklist.push(haxe.Unserializer);

		// `lime.system.CFFI`
		// Can load and execute compiled binaries.
		blacklist.push(lime.system.CFFI);

		// `lime.system.JNI`
		// Can load and execute compiled binaries.
		blacklist.push(lime.system.JNI);

		// `lime.system.System`
		// System.load() can load malicious DLLs
		blacklist.push(lime.system.System);

		// `openfl.desktop.NativeProcess`
		// Can load native processes on the host operating system.
		blacklist.push(openfl.desktop.NativeProcess);

		// `online.net` classes can access the network without player knowing
		blacklist.push(online.network.Auth);
		blacklist.push(online.network.FunkinNetwork);
		blacklist.push(online.network.Leaderboard);

		// FileUtils accesses files duh
		blacklist.push(online.util.FileUtils);
		blacklist.push(online.http.HTTPClient);

		// SyncScript can load malicious scripts
		blacklist.push(online.backend.SyncScript);

		// `polymod.*`
		// Contains functions which may allow for un-blacklisting other modules.
		for (cls in CompileTime.getAllClasses('polymod')) {
			if (cls == null)
				continue;
			blacklist.push(cls);
		}

		// `sys.*`
		// Access to system utilities such as the file system.
		for (cls in CompileTime.getAllClasses('sys')) {
			if (cls == null)
				continue;
			blacklist.push(cls);
		}

		for (cls in CompileTime.getAllClasses('tea')) {
			if (cls == null)
				continue;
			blacklist.push(cls);
		}

		for (cls in CompileTime.getAllClasses('teaBase')) {
			if (cls == null)
				continue;
			blacklist.push(cls);
		}

		for (cls in CompileTime.getAllClasses('lumod')) {
			if (cls == null)
				continue;
			blacklist.push(cls);
		}

		blacklist.push(CompileTime);

		#if (extension_androidtools)
		// `android.jni.JNICache`
		// Same as `lime.system.JNI`
		blacklist.push(android.jni.JNICache);
		#end

		classBlacklist = blacklist;

        if (ClientPrefs.isDebug())
			trace(classBlacklist);
    }
}