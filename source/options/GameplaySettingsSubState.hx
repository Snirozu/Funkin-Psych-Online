package options;

import states.FreeplayState;

class GameplaySettingsSubState extends BaseOptionsMenu
{
	function openGameOptions() {
		//I'd suggest using "Downscroll" as an example for making your own option since it is the simplest here
		var option:Option = new Option('Downscroll', //Name
			'If checked, notes go Down instead of Up, simple enough.', //Description
			'downScroll', //Save data variable name
			'bool'); //Variable type
		addOption(option);

		var option:Option = new Option('Middlescroll',
			'If checked, your notes get centered.',
			'middleScroll',
			'bool');
		addOption(option);

		var option:Option = new Option('Opponent Notes',
			'If unchecked, opponent notes get hidden.',
			'opponentStrums',
			'bool');
		addOption(option);

		var option:Option = new Option('Ghost Tapping',
			"If checked, you won't get misses from pressing keys\nwhile there are no notes able to be hit.",
			'ghostTapping',
			'bool');
		addOption(option);
		
		var option:Option = new Option('Auto Pause',
			"If checked, the game automatically pauses if the screen isn't on focus.",
			'autoPause',
			'bool');
		addOption(option);
		option.onChange = onChangeAutoPause;

		var option:Option = new Option('Disable Reset Button',
			"If checked, pressing Reset won't do anything.",
			'noReset',
			'bool');
		addOption(option);

		var option:Option = new Option('Hitsound Volume',
			'Funny notes does \"Tick!\" when you hit them."',
			'hitsoundVolume',
			'percent');
		addOption(option);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		option.onChange = onChangeHitsoundVolume;

		var option:Option = new Option('Rating Offset',
			'Changes how late/early you have to hit for a "Sick!"\nHigher values mean you have to hit later.',
			'ratingOffset',
			'int');
		option.displayFormat = '%vms';
		option.scrollSpeed = 20;
		option.minValue = -30;
		option.maxValue = 30;
		addOption(option);

		// phantom ass options

		// var option:Option = new Option('Sick! Hit Window',
		// 	'Changes the amount of time you have\nfor hitting a "Sick!" in milliseconds.',
		// 	'sickWindow',
		// 	'int');
		// option.displayFormat = '%vms';
		// option.scrollSpeed = 15;
		// option.minValue = 15;
		// option.maxValue = 45;
		// addOption(option);

		// var option:Option = new Option('Good Hit Window',
		// 	'Changes the amount of time you have\nfor hitting a "Good" in milliseconds.',
		// 	'goodWindow',
		// 	'int');
		// option.displayFormat = '%vms';
		// option.scrollSpeed = 30;
		// option.minValue = 15;
		// option.maxValue = 90;
		// addOption(option);

		// var option:Option = new Option('Bad Hit Window',
		// 	'Changes the amount of time you have\nfor hitting a "Bad" in milliseconds.',
		// 	'badWindow',
		// 	'int');
		// option.displayFormat = '%vms';
		// option.scrollSpeed = 60;
		// option.minValue = 15;
		// option.maxValue = 135;
		// addOption(option);

		var option:Option = new Option('Safe Frames',
			'Changes how many frames you have for\nhitting a note earlier or late.',
			'safeFrames',
			'float');
		option.scrollSpeed = 5;
		option.minValue = 2;
		option.maxValue = 10;
		option.changeValue = 0.1;
		addOption(option);

		var option:Option = new Option('Disable Note Modchart',
			'If checked, strum notes will no longer move or change their opacity to invisible.',
			'disableStrumMovement',
			'bool');
		addOption(option);

		var option:Option = new Option('Modchart Skin Changes',
			'If enabled, the song events will change the character of your active skin',
			'modchartSkinChanges',
			'bool');
		addOption(option);

		var option:Option = new Option('Disable Lag Detection',
			'If checked, the game will no longer rewind 3 seconds when a lag is detected',
			'disableLagDetection',
			'bool');
		addOption(option);
	}

	function openPreferences() {
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
		
		var option:Option = new Option('Disable Recording Replays',
			'If checked, the game will no longer record your gameplay, this will cause your scores to not be submitted to the leaderboard!',
			'disableReplays',
			'bool');
		addOption(option);

		var option:Option = new Option('Disable Leaderboard Submiting',
			'If checked, the game will no longer submit your replays to the leaderboard\nCan be toggled in-game with F2',
			'disableSubmiting',
			'bool');
		addOption(option);

		var option:Option = new Option('Disable Automatic Downloads',
			'Disables automatic downloads of Mods and Skins from the opponent',
			'disableAutoDownloads',
			'bool');
		addOption(option);

		var option:Option = new Option('Pause Screen Song:',
			"What song do you prefer for the Pause Screen?",
			'pauseMusic',
			'string',
			['None', 'Breakfast', 'Tea Time']);
		addOption(option);
		option.onChange = onChangePauseMusic;

		var option:Option = new Option('Group Songs:',
			"How should songs on Freeplay menu be group by?",
			'groupSongsBy',
			'string',
			FreeplayState.GROUPS);
		addOption(option);

		var option:Option = new Option('Favorite Tracks Menu Theme',
			'If checked, the game will be picking your random favorite song as the main menu theme!',
			'favsAsMenuTheme',
			'bool');
		option.onChange = () -> {
			states.TitleState.playFreakyMusic();
		};
		addOption(option);

		var option:Option = new Option('Debug Mode',
			"If checked, enables debug warnings etc.",
			'debugMode',
			'bool');
		addOption(option);
	}

	public function new(category:String)
	{
		title = category;
		rpcTitle = 'Game Settings Menu'; //for Discord Rich Presence

		switch (category) {
			case 'Gameplay':
				openGameOptions();
			case 'Preferences':
				openPreferences();
		}

		super();
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

	override function destroy() {
		if(changedMusic && !OptionsState.onPlayState) states.TitleState.playFreakyMusic();
		super.destroy();
	}

	function onChangeHitsoundVolume()
	{
		FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.data.hitsoundVolume);
	}

	function onChangeAutoPause()
	{
		FlxG.autoPause = ClientPrefs.data.autoPause;
	}
}