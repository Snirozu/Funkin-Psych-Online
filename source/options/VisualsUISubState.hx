package options;

import states.FreeplayState;
import backend.NoteSkinData;
import online.GameClient;
import objects.Note;
import objects.StrumNote;
import objects.Alphabet;

class VisualsUISubState extends BaseOptionsMenu
{
	public static var isOpened:Bool = false;

	var noteOptionID:Int = -1;
	var notes:FlxTypedGroup<StrumNote>;
	var notesTween:Array<FlxTween> = [];
	var noteY:Float = 90;
	public function new()
	{
		title = 'Visuals and UI';
		rpcTitle = 'Visuals & UI Settings Menu'; //for Discord Rich Presence

		NoteSkinData.reloadNoteSkins();

		isOpened = true;

		// for note skins
		notes = new FlxTypedGroup<StrumNote>();
		for (i in 0...Note.colArray.length)
		{
			var note:StrumNote = new StrumNote(370 + (560 / Note.colArray.length) * i, -200, i, 0);
			note.centerOffsets();
			note.centerOrigin();
			note.playAnim('static');
			notes.add(note);
		}

		// options

		if(NoteSkinData.noteSkins.length > 0)
		{
			if(!NoteSkinData.noteSkinArray.contains(ClientPrefs.data.noteSkin))
				ClientPrefs.data.noteSkin = ClientPrefs.defaultData.noteSkin; //Reset to default if saved noteskin couldnt be found

			var option:Option = new Option('Note Skins:',
				"Select your prefered Note skin.",
				'noteSkin',
				'string',
				NoteSkinData.noteSkinArray);
			addOption(option);
			option.onChange = onChangeNoteSkin;
			noteOptionID = optionsArray.length - 1;
		}
		
		var noteSplashes:Array<String> = Mods.mergeAllTextsNamed('images/noteSplashes/list.txt', 'shared');
		if(noteSplashes.length > 0)
		{
			if(!noteSplashes.contains(ClientPrefs.data.splashSkin))
				ClientPrefs.data.splashSkin = ClientPrefs.defaultData.splashSkin; //Reset to default if saved splashskin couldnt be found

			noteSplashes.insert(0, ClientPrefs.defaultData.splashSkin); //Default skin always comes first
			var option:Option = new Option('Note Splashes:',
				"Select your prefered Note Splash variation or turn it off.",
				'splashSkin',
				'string',
				noteSplashes);
			addOption(option);
		}

		var option:Option = new Option('Note Splash Opacity',
			'How much transparent should the Note Splashes be.\n0% disables it.',
			'splashAlpha',
			'percent');
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);

		var option:Option = new Option('Note Hold Splash Opacity',
			'How much transparent should the Note Hold Splash be.\n0% disables it.',
			'holdSplashAlpha',
			'percent');
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);

		var option:Option = new Option('Trail Note Opacity',
			'How much transparent should the Note Trail be.',
			'holdAlpha',
			'percent');
		option.scrollSpeed = 1.3;
		option.minValue = 0.5;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);

		var option:Option = new Option('Hide HUD',
			'If checked, hides most HUD elements.',
			'hideHud',
			'bool');
		addOption(option);
		
		var option:Option = new Option('Time Bar:',
			"What should the Time Bar display?",
			'timeBarType',
			'string',
			['Time Left', 'Time Elapsed', 'Song Name', 'Disabled']);
		addOption(option);

		var option:Option = new Option('Flashing Lights',
			"Uncheck this if you're sensitive to flashing lights!",
			'flashing',
			'bool');
		addOption(option);

		var option:Option = new Option('Camera Zooms',
			"If unchecked, the camera won't zoom in on a beat hit.",
			'camZooms',
			'bool');
		addOption(option);

		var option:Option = new Option('Score Text Zoom on Hit',
			"If unchecked, disables the Score text zooming\neverytime you hit a note.",
			'scoreZoom',
			'bool');
		addOption(option);

		var option:Option = new Option('Health Bar Opacity',
			'How much transparent should the health bar and icons be.',
			'healthBarAlpha',
			'percent');
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);
		
		#if !mobile
		var option:Option = new Option('FPS Counter',
			'If unchecked, hides FPS Counter.',
			'showFPS',
			'bool');
		addOption(option);
		option.onChange = onChangeFPSCounter;
		#end
		
		var option:Option = new Option('Pause Screen Song:',
			"What song do you prefer for the Pause Screen?",
			'pauseMusic',
			'string',
			['None', 'Breakfast', 'Tea Time']);
		addOption(option);
		option.onChange = onChangePauseMusic;
		
		#if CHECK_FOR_UPDATES
		var option:Option = new Option('Check for Updates',
			'On Release builds, turn this on to check for updates when you start the game.',
			'checkForUpdates',
			'bool');
		addOption(option);
		#end

		#if DISCORD_ALLOWED
		var option:Option = new Option('Discord Rich Presence',
			"Uncheck this to prevent accidental leaks, it will hide the Application from your \"Playing\" box on Discord",
			'discordRPC',
			'bool');
		addOption(option);
		#end

		var option:Option = new Option('Debug Mode',
			"If checked, enables debug warnings etc.",
			'debugMode',
			'bool');
		addOption(option);

		var option:Option = new Option('Show Note timing',
			'If checked, a timing of the hitted note will be shown on the screen (in miliseconds)',
			'showNoteTiming',
			'bool');
		addOption(option);

		var option:Option = new Option('Disable Automatic Downloads',
			'Disables automatic downloads of Mods and Skins from the opponent',
			'disableAutoDownloads',
			'bool');
		addOption(option);

		var option:Option = new Option('Disable Song Comments',
			'Disables song comments on the replay viewer',
			'disableSongComments',
			'bool');
		addOption(option);

		var option:Option = new Option('Show Funkin Points Counter',
			'If checked, the current FP count will be shown in the score text, can be toggled in-game with F7',
			'showFP',
			'bool');
		addOption(option);

		var option:Option = new Option('Group Songs:',
			"How should songs on Freeplay menu be group by?",
			'groupSongsBy',
			'string',
			FreeplayState.GROUPS);
		addOption(option);

		var option:Option = new Option('Rating Color',
			'If checked, the Rating text will be colored depending on your current... well... Rating, same with Combo.',
			'colorRating',
			'bool');
		addOption(option);

		super();
		add(notes);
	}

	override function changeSelection(change:Int = 0)
	{
		super.changeSelection(change);
		
		if(noteOptionID < 0) return;

		for (i in 0...Note.colArray.length)
		{
			var note:StrumNote = notes.members[i];
			if(notesTween[i] != null) notesTween[i].cancel();
			if(curSelected == noteOptionID)
				notesTween[i] = FlxTween.tween(note, {y: noteY}, Math.abs(note.y / (200 + noteY)) / 3, {ease: FlxEase.quadInOut});
			else
				notesTween[i] = FlxTween.tween(note, {y: -200}, Math.abs(note.y / (200 + noteY)) / 3, {ease: FlxEase.quadInOut});
		}
	}

	var changedMusic:Bool = false;
	function onChangePauseMusic()
	{
		if(ClientPrefs.data.pauseMusic == 'None')
			FlxG.sound.music.volume = 0;
		else
			FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)));

		changedMusic = true;
	}

	function onChangeNoteSkin()
	{
		notes.forEachAlive(function(note:StrumNote) {
			changeNoteSkin(note);
			note.centerOffsets();
			note.centerOrigin();
		});
	}

	function changeNoteSkin(note:StrumNote)
	{
		var data:NoteSkinStructure = NoteSkinData.getCurrent();
		Mods.currentModDirectory = data.folder;

		var skin:String = Note.defaultNoteSkin;
		var customSkin:String = skin + Note.getNoteSkinPostfix();
		if(Paths.fileExists('images/$customSkin.png', IMAGE)) skin = customSkin;

		note.texture = skin; //Load texture and anims
		note.reloadNote();
		note.playAnim('static');
	}

	override function destroy()
	{
		if(changedMusic && !OptionsState.onPlayState) FlxG.sound.playMusic(Paths.music('freakyMenu'), 1, true);
		isOpened = false;
		if (GameClient.isConnected()) {
			var data:NoteSkinStructure = NoteSkinData.getCurrent(-1);
			GameClient.send('updateNoteSkinData', [data.skin, data.folder, data.url]);
		}
		Mods.currentModDirectory = '';
		super.destroy();
	}

	#if !mobile
	function onChangeFPSCounter()
	{
		if(Main.fpsVar != null)
			Main.fpsVar.visible = ClientPrefs.data.showFPS;
	}
	#end
}
