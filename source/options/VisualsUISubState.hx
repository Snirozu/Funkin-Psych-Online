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

	function openNotes() {
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

		var option:Option = new Option('Note Colors',
			'Set the colors for your notes!',
			null,
			'button');
		option.onChange = () -> {
			openSubState(new options.NotesSubState());
		};
		addOption(option);

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

		var option:Option = new Option('Note Underlay Opacity', 'If higher than 0%, an underlay will be displayed behind player notes.', 'noteUnderlayOpacity', 'percent');
		addOption(option);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.05;
		option.decimals = 2;

		var option:Option = new Option('Note Underlay Type:',
			"How should the game render note underlays.",
			'noteUnderlayType',
			'string',
			['All-In-One', 'By Note']);
		addOption(option);
	}

	function openAccessibility() {
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

		var option:Option = new Option('Camera Shakes',
			"If unchecked, camera will be allowed to shake.",
			'camShakes',
			'bool');
		addOption(option);

		var option:Option = new Option('Camera Tilt',
			"If unchecked, camera will be allowed to tilt.",
			'camAngles',
			'bool');
		addOption(option);

		var option:Option = new Option('Camera Movement',
			"If unchecked, camera will move instead of being locked still on girlfriend.",
			'camMovement',
			'bool');
		addOption(option);

		var option:Option = new Option('Score Text Zoom on Hit',
			"If unchecked, disables the Score text zooming\neverytime you hit a note.",
			'scoreZoom',
			'bool');
		addOption(option);
	}

	function openComboAndRating() {
		var option:Option = new Option('Adjust Positions',
			'Customize the offsets for combo and rating sprites here!',
			null,
			'button');
		option.onChange = () -> {
			FlxG.switchState(() -> new options.NoteOffsetState());
		};
		addOption(option);

		var option:Option = new Option('Rating Color',
			'If checked, the Rating text will be colored depending on your current... well... Rating, same with Combo.',
			'colorRating',
			'bool');
		addOption(option);

		var option:Option = new Option('Disable Combo Rating',
			'If checked, the combo rating sprite will no longer show up.',
			'disableComboRating',
			'bool');
		addOption(option);

		var option:Option = new Option('Disable Combo Counter',
			'If checked, the combo counter sprite will no longer show up.',
			'disableComboCounter',
			'bool');
		addOption(option);

		var option:Option = new Option('Show Note Timing',
			'If checked, a timing of the hitted note will be shown on the screen (in miliseconds)',
			'showNoteTiming',
			'bool');
		addOption(option);
	}

	function openUI() {
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

		var option:Option = new Option('Nameplate Fade Time',
			'After how many seconds should player nameplates be hidden?\nSet to 0 to instantly hide them.\nSet to -1 to never hide them.',
			'nameplateFadeTime',
			'int');
		option.displayFormat = '%vs';
		option.scrollSpeed = 20;
		option.minValue = -1;
		option.maxValue = 60;
		option.changeValue = 1;
		option.decimals = 0;
		addOption(option);

		var option:Option = new Option('Show Funkin Points Counter',
			'If checked, the current FP count will be shown in the score text, can be toggled in-game with F7',
			'showFP',
			'bool');
		addOption(option);

		var option:Option = new Option('FP V5 Preview',
			'If enabled, new FP algorithm will be shown in the Counter',
			'newFPPreview',
			'bool');
		addOption(option);

		var option:Option = new Option('Disable Song Comments',
			'Disables song comments on the replay viewer and (if visible, while playing)',
			'disableSongComments',
			'bool');
		addOption(option);
		
		var option:Option = new Option('Song Comments Opacity',
			'How visible should the song comments be while you\'re playing a song',
			'midSongCommentsOpacity',
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
	}

	public function new(category:String)
	{
		title = category;
		rpcTitle = 'Visuals & UI Settings Menu'; //for Discord Rich Presence

		NoteSkinData.reloadNoteSkins();

		isOpened = true;

		switch (category) {
			case 'Notes':
				openNotes();
			case 'Combo & Rating':
				openComboAndRating();
			case 'User Interface':
				openUI();
			case 'Accessibility':
				openAccessibility();
		}

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
