package substates;

import online.GameClient;
import online.util.ShitUtil;
import online.substates.PostTextSubstate;
import sys.io.File;
import online.network.Leaderboard;
import haxe.Json;
import backend.WeekData;
import backend.Highscore;
import backend.Song;

import flixel.addons.transition.FlxTransitionableState;

import flixel.util.FlxStringUtil;

import states.StoryMenuState;
import states.FreeplayState;
import options.OptionsState;
import online.gui.Alert;
import online.util.FileUtils;

@:access(states.PlayState)
class PauseSubState extends MusicBeatSubstate
{
	var grpMenuShit:FlxTypedGroup<Alphabet>;

	var menuItems:Array<String> = [];
	var menuItemsOG:Array<String> = [];
	var difficultyChoices = [];
	var curSelected:Int = 0;

	var pauseMusic:FlxSound;
	var practiceText:FlxText;
	var skipTimeText:FlxText;
	var skipTimeTracker:Alphabet;
	var curTime:Float = Math.max(0, Conductor.songPosition);

	var missingTextBG:FlxSprite;
	var missingText:FlxText;

	public static var songName:String = '';

	public function new(x:Float, y:Float)
	{
		super();

		if (!GameClient.isConnected()) {
			menuItemsOG = ['Resume', 'Restart Song', 'Change Difficulty', 'Options', 'Exit to menu'];

			if(Difficulty.list.length < 2) menuItemsOG.remove('Change Difficulty'); //No need to change difficulty if there is only one!

			if(PlayState.chartingMode)
			{
				menuItemsOG.insert(2, 'Leave Charting Mode');
				
				var num:Int = 0;
				if(!PlayState.instance.startingSong)
				{
					num = 1;
					menuItemsOG.insert(3, 'Skip Time');
				}
				menuItemsOG.insert(3 + num, 'End Song');
				menuItemsOG.insert(4 + num, 'Toggle Practice Mode');
				menuItemsOG.insert(5 + num, 'Toggle Botplay');
			}

			var oof = 0;
			if (!ClientPrefs.data.disableSongComments && PlayState.instance.songId != null) {
				menuItemsOG.insert(3, 'Post a Comment Now');
				oof++;
			}

			if (ClientPrefs.isDebug()) {
				menuItemsOG.insert(3, 'Debug Tools');
				oof++;
			}

			if (PlayState.replayData != null) {
				menuItemsOG.remove('Change Difficulty');
				menuItemsOG.insert(2 + oof, 'Skip Time');
				menuItemsOG.insert(3 + oof, 'Save Replay');
				if (PlayState.replayID != null) {
					menuItemsOG.insert(4 + oof, 'Report Replay');
				}
			}
		}
		else {
			menuItemsOG = ['Resume', 'Exit to lobby'];
		}

		menuItems = menuItemsOG;

		for (i in 0...Difficulty.list.length) {
			var diff:String = Difficulty.getString(i);
			difficultyChoices.push(diff);
		}
		difficultyChoices.push('BACK');

		if (!FlxG.sound.music.playing) {
			pauseMusic = new FlxSound();
			if(songName != null) {
				pauseMusic.loadEmbedded(Paths.music(songName), true, true);
			} else if (songName != 'None') {
				var msc = null;
				if (ClientPrefs.data.currentSkin != null) {
					ShitUtil.tempSwitchMod(ClientPrefs.data.currentSkin[3], () -> {
						msc = Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic + '-' + ClientPrefs.data.currentSkin[0]));
					});
				}
				msc ??= Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic));
				pauseMusic.loadEmbedded(msc, true, true);
			}
			pauseMusic.volume = 0;
			pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));

			FlxG.sound.list.add(pauseMusic);
		}

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		var levelInfo:FlxText = new FlxText(20, 15, 0, PlayState.SONG.song, 32);
		levelInfo.scrollFactor.set();
		levelInfo.setFormat(Paths.font("vcr.ttf"), 32);
		levelInfo.updateHitbox();
		add(levelInfo);

		var levelDifficulty:FlxText = new FlxText(20, 15 + 32, 0, Difficulty.getString().toUpperCase(), 32);
		levelDifficulty.scrollFactor.set();
		levelDifficulty.setFormat(Paths.font('vcr.ttf'), 32);
		levelDifficulty.updateHitbox();
		add(levelDifficulty);

		var blueballedTxt:FlxText = new FlxText(20, 15 + 64, 0, "Retry No. " + PlayState.deathCounter, 32);
		blueballedTxt.scrollFactor.set();
		blueballedTxt.setFormat(Paths.font('vcr.ttf'), 32);
		blueballedTxt.updateHitbox();
		add(blueballedTxt);

		practiceText = new FlxText(20, 15 + 101, 0, "PRACTICE MODE", 32);
		practiceText.scrollFactor.set();
		practiceText.setFormat(Paths.font('vcr.ttf'), 32);
		practiceText.x = FlxG.width - (practiceText.width + 20);
		practiceText.updateHitbox();
		practiceText.visible = PlayState.instance.practiceMode;
		add(practiceText);

		var chartingText:FlxText = new FlxText(20, 15 + 101, 0, "CHARTING MODE", 32);
		chartingText.scrollFactor.set();
		chartingText.setFormat(Paths.font('vcr.ttf'), 32);
		chartingText.x = FlxG.width - (chartingText.width + 20);
		chartingText.y = FlxG.height - (chartingText.height + 20);
		chartingText.updateHitbox();
		chartingText.visible = PlayState.chartingMode;
		add(chartingText);

		blueballedTxt.alpha = 0;
		levelDifficulty.alpha = 0;
		levelInfo.alpha = 0;

		levelInfo.x = FlxG.width - (levelInfo.width + 20);
		levelDifficulty.x = FlxG.width - (levelDifficulty.width + 20);
		blueballedTxt.x = FlxG.width - (blueballedTxt.width + 20);

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
		FlxTween.tween(levelInfo, {alpha: 1, y: 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
		FlxTween.tween(levelDifficulty, {alpha: 1, y: levelDifficulty.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});
		FlxTween.tween(blueballedTxt, {alpha: 1, y: blueballedTxt.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.7});

		grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);

		missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
		add(missingTextBG);
		
		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);

		skipTimeText = new FlxText(0, 0, 0, '', 64);
		skipTimeText.setFormat(Paths.font("vcr.ttf"), 64, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		skipTimeText.scrollFactor.set();
		skipTimeText.borderSize = 2;
		add(skipTimeText);

		regenMenu();
		//cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		cameras = [PlayState.instance.camOther];
	}

	var holdTime:Float = 0;
	var cantUnpause:Float = 0.1;
	override function update(elapsed:Float)
	{
		cantUnpause -= elapsed;
		if (pauseMusic != null && pauseMusic.volume < 0.5)
			pauseMusic.volume += 0.01 * elapsed;

		super.update(elapsed);
		updateSkipTextStuff();

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var accepted = controls.ACCEPT;

		if (upP)
		{
			changeSelection(-1);
		}
		if (downP)
		{
			changeSelection(1);
		}

		var daSelected:String = menuItems[curSelected];
		switch (daSelected)
		{
			case 'Skip Time':
				if (controls.UI_LEFT_P)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
					curTime -= 1000;
					holdTime = 0;
				}
				if (controls.UI_RIGHT_P)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
					curTime += 1000;
					holdTime = 0;
				}

				if(controls.UI_LEFT || controls.UI_RIGHT)
				{
					holdTime += elapsed;
					if(holdTime > 0.5)
					{
						curTime += 45000 * elapsed * (controls.UI_LEFT ? -1 : 1);
					}

					if(curTime >= FlxG.sound.music.length) curTime -= FlxG.sound.music.length;
					else if(curTime < 0) curTime += FlxG.sound.music.length;
					updateSkipTimeText();
				}
			case 'Playback Rate':
				if (controls.UI_LEFT_P) {
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
					PlayState.instance.playbackRate -= 0.01;
					holdTime = 0;
				}
				if (controls.UI_RIGHT_P) {
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
					PlayState.instance.playbackRate += 0.01;
					holdTime = 0;
				}

				if (controls.UI_LEFT || controls.UI_RIGHT) {
					holdTime += elapsed;
					if (holdTime > 0.5) {
						PlayState.instance.playbackRate += elapsed * (controls.UI_LEFT ? -1 : 1);
					}

					if (PlayState.instance.playbackRate >= 3)
						PlayState.instance.playbackRate = 3;
					else if (PlayState.instance.playbackRate < 0.001)
						PlayState.instance.playbackRate = 0.001;
					updatePlaybackRateText();
				}
				
		}

		if (accepted && cantUnpause <= 0)
		{
			if (menuItems == difficultyChoices)
			{
				try{
					if(menuItems.length - 1 != curSelected && difficultyChoices.contains(daSelected)) {
						PlayState.replayData = null;
						var name:String = PlayState.SONG.song;
						var poop = Highscore.formatSong(name, curSelected);
						PlayState.loadSong(poop, name);
						PlayState.storyDifficulty = curSelected;
						FlxG.switchState(new PlayState());
						FlxG.sound.music.volume = 0;
						PlayState.changedDifficulty = true;
						PlayState.chartingMode = false;
						return;
					}					
				}catch(e:Dynamic){
					trace('ERROR! $e');

					var errorStr:String = e.toString();
					if(errorStr.startsWith('[file_contents,assets/data/')) errorStr = 'Missing file: ' + errorStr.substring(27, errorStr.length-1); //Missing chart
					missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
					missingText.screenCenter(Y);
					missingText.visible = true;
					missingTextBG.visible = true;
					FlxG.sound.play(Paths.sound('cancelMenu'));

					super.update(elapsed);
					return;
				}


				menuItems = menuItemsOG;
				regenMenu();
			}

			switch (daSelected)
			{
				case "Resume":
					close();
				case 'Change Difficulty':
					menuItems = difficultyChoices;
					//deleteSkipTimeText();
					regenMenu();
				case 'Toggle Practice Mode':
					PlayState.instance.practiceMode = !PlayState.instance.practiceMode;
					PlayState.changedDifficulty = true;
					practiceText.visible = PlayState.instance.practiceMode;
				case "Restart Song":
					PlayState.deathCounter++;
					restartSong();
				case "Leave Charting Mode":
					PlayState.deathCounter = 0;
					restartSong();
					PlayState.chartingMode = false;
				case 'Skip Time':
					if(curTime < Conductor.songPosition)
					{
						PlayState.startOnTime = curTime;
						restartSong(true);
					}
					else
					{
						if (curTime != Conductor.songPosition)
						{
							PlayState.instance.clearNotesBefore(curTime);
							PlayState.instance.setSongTime(curTime);
						}
						close();
					}
				case 'End Song':
					close();
					PlayState.instance.notes.clear();
					PlayState.instance.unspawnNotes = [];
					PlayState.instance.finishSong(true);
				case 'Toggle Botplay':
					PlayState.instance.cpuControlled = !PlayState.instance.cpuControlled;
					PlayState.changedDifficulty = true;
					PlayState.instance.botplayTxt.visible = PlayState.instance.cpuControlled;
					PlayState.instance.botplayTxt.alpha = 1;
					PlayState.instance.botplaySine = 0;
				case 'Post a Comment Now':
					close();
					persistentUpdate = false;
					persistentDraw = true;
					PlayState.instance.paused = true;
					PlayState.instance.openSubState(new PostTextSubstate('Post a comment at the current timestamp.\n(It will be displayed on every replay of this song.)', text -> {
						online.network.FunkinNetwork.postSongComment(PlayState.instance.songId, text, Conductor.songPosition);
					}));
				case 'Options':
					PlayState.instance.paused = true; // For lua
					PlayState.instance.vocals.volume = 0;
					FlxG.switchState(() -> new OptionsState());
					if (pauseMusic != null && ClientPrefs.data.pauseMusic != 'None')
					{
						FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)), pauseMusic.volume);
						FlxTween.tween(FlxG.sound.music, {volume: 1}, 0.8);
						FlxG.sound.music.time = pauseMusic.time;
					}
					OptionsState.onPlayState = true;
					OptionsState.onOnlineRoom = false;
				case "Exit to menu":
					#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
					PlayState.deathCounter = 0;
					PlayState.seenCutscene = false;
					PlayState.replayData = null;

					Mods.loadTopMod();
					if(PlayState.isStoryMode) {
						FlxG.switchState(() -> new StoryMenuState());
					} else {
						FlxG.switchState(() -> new FreeplayState());
					}
					PlayState.cancelMusicFadeTween();
					states.TitleState.playFreakyMusic();
					PlayState.changedDifficulty = false;
					PlayState.chartingMode = false;
					FlxG.camera.followLerp = 0;
				case "Report Replay":
					PlayState.instance.openSubState(new PostTextSubstate('What is the issue with this replay?', text -> {
						if (Leaderboard.reportScore(PlayState.replayID, text) != null)
							Alert.alert("Replay Reported");
					}));
					close();
				case "Save Replay":
					var replayData = Json.stringify(PlayState.replayData);
					var path = FileUtils.joinFiles([
						"replays", 
						PlayState.replayData.player + "Replay-" + PlayState.SONG.song + "-" + Difficulty.getString().toUpperCase() + ".funkinreplay"
					]);
					File.saveContent(path, replayData);
					Alert.alert("Replay Saved!", path);
					close();
				case "Debug Tools":
					menuItems = [
						'Playback Rate',
						'Run Script',
						'Swap Sides',
						'Chart Edtor',
						'Character Editor',
						'Position Debug',
						'Swing Mode'
					];
					if (PlayState.instance.stage3D != null)
						menuItems.insert(1, 'Stage 3D Debug');
					if (!PlayState.chartingMode)
						menuItems.insert(2, 'Charting Mode');
					menuItems.push('Back');
					//deleteSkipTimeText();
					regenMenu();
				case 'Swap Sides':
					PlayState.instance.toggleOpponentMode();
					close();
				case 'Stage 3D Debug': 
					close();
					Main.view3D.debugMode = !Main.view3D.debugMode;
				case 'Position Debug': 
					PlayState.instance.debugPoser.editMode = !PlayState.instance.debugPoser.editMode;
					close();
				case 'Chart Edtor':
					PlayState.instance.openChartEditor();
					close();
				case 'Character Editor':
					PlayState.instance.openCharacterEditor();
					close();
				case 'Swing Mode':
					PlayState.swingMode = !PlayState.swingMode;
					close();
				case 'Charting Mode':
					PlayState.chartingMode = true;
					close();
					PlayState.instance.openPauseMenu();
				case 'Run Script':
					close();
					persistentUpdate = false;
					persistentDraw = true;
					PlayState.instance.paused = true;
					PlayState.instance.openSubState(new PostTextSubstate('Input Haxe code here:', text -> {
						var hs = new psychlua.HScript(null, text);
						Alert.alert(hs.returnValue);
					}));
				case 'Back':
					menuItems = menuItemsOG;
					regenMenu();
				case 'Exit to lobby':
					GameClient.send("requestEndSong");
				default:
					close();
			}
		}
	}

	// function deleteSkipTimeText()
	// {
	// 	if(skipTimeText != null)
	// 	{
	// 		skipTimeText.kill();
	// 		remove(skipTimeText);
	// 		skipTimeText.destroy();
	// 	}
	// 	skipTimeText = null;
	// 	skipTimeTracker = null;
	// }

	public static function restartSong(noTrans:Bool = false)
	{
		PlayState.instance.paused = true; // For lua
		FlxG.sound.music.volume = 0;
		PlayState.instance.vocals.volume = 0;

		if(noTrans)
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
		}
		// FlxG.resetState(); // yeah baby!!! more haxeflixel bugs!
		FlxG.switchState(new PlayState());
	}

	override function destroy()
	{
		if (pauseMusic != null)
			pauseMusic.destroy();

		super.destroy();
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected += change;

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		if (curSelected < 0)
			curSelected = menuItems.length - 1;
		if (curSelected >= menuItems.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpMenuShit.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));

				if(item == skipTimeTracker && item.text == 'Skip Time')
				{
					curTime = Math.max(0, Conductor.songPosition);
					updateSkipTimeText();
				}
			}
		}
		missingText.visible = false;
		missingTextBG.visible = false;
	}

	function regenMenu():Void {
		for (i in 0...grpMenuShit.members.length) {
			var obj = grpMenuShit.members[0];
			obj.kill();
			grpMenuShit.remove(obj, true);
			obj.destroy();
		}

		skipTimeText.visible = false;
		skipTimeTracker = null;

		for (i in 0...menuItems.length) {
			var item = new Alphabet(90, 320, menuItems[i], true);
			item.isMenuItem = true;
			item.targetY = i;
			grpMenuShit.add(item);

			switch (menuItems[i]) {
				case 'Skip Time':
					skipTimeTracker = item;
					updateSkipTextStuff();
					updateSkipTimeText();
				case 'Playback Rate':
					skipTimeTracker = item;
					updateSkipTextStuff();
					updatePlaybackRateText();
			}
		}
		curSelected = 0;
		changeSelection();
	}
	
	function updateSkipTextStuff()
	{
		if(skipTimeText == null || skipTimeTracker == null) return;

		skipTimeText.x = skipTimeTracker.x + skipTimeTracker.width + 60;
		skipTimeText.y = skipTimeTracker.y;
		skipTimeText.visible = (skipTimeTracker.alpha >= 1);
	}

	function updateSkipTimeText()
	{
		skipTimeText.text = FlxStringUtil.formatTime(Math.max(0, Math.floor(curTime / 1000)), false) + ' / ' + FlxStringUtil.formatTime(Math.max(0, Math.floor(FlxG.sound.music.length / 1000)), false);
	}

	function updatePlaybackRateText() {
		skipTimeText.text = FlxMath.roundDecimal(PlayState.instance.playbackRate, 2) + 'x';
	}
}
