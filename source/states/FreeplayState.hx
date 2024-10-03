package states;

import online.replay.ReplayPlayer;
import online.replay.ReplayRecorder.ReplayData;
import json2object.JsonParser;
import flixel.effects.FlxFlicker;
import online.Scoreboard;
import online.net.Leaderboard;
import flixel.FlxObject;
import flixel.math.FlxPoint;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.group.FlxGroup;
import flixel.addons.effects.chainable.FlxOutlineEffect;
import flixel.util.FlxStringUtil;
import haxe.io.Path;
import haxe.Json;
import haxe.io.Bytes;
import lime.ui.FileDialog;
import online.ChatBox;
import online.Alert;
import online.Waiter;
import haxe.crypto.Md5;
import online.states.RoomState;
import online.GameClient;
import backend.WeekData;
import backend.Highscore;
import backend.Song;
import openfl.media.Sound;

import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;

import objects.HealthIcon;
import states.editors.ChartingState;

import substates.GameplayChangersSubstate;
import substates.ResetScoreSubState;

#if MODS_ALLOWED
import sys.FileSystem;
#end

class FreeplayState extends MusicBeatState
{
	public var songs:Array<SongMetadata> = [];

	var selector:FlxText;
	public static var curSelected:Int = 0;
	var lerpSelected:Float = 0;
	var curDifficulty:Int = -1;
	private static var lastDifficultyName:String = Difficulty.getDefault();

	public static var gainedPoints:Float = 0;
	var gainedText:FlxText;

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;
	var infoText:FlxText;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	var bg:FlxSprite;
	var intendedColor:Int;
	var colorTween:FlxTween;

	var missingTextBG:FlxSprite;
	var missingText:FlxText;

	var prevPauseGame = false;

	var chatBox:ChatBox;

	var listening:Bool = false;
	var selected:Bool = false;
	var selectedItem:Int = 0;
	var selectedScore:Int = 0;

	// var dTime:Alphabet = new Alphabet(0, 0, "0:00", false);
	// var dShots:FlxTypedGroup<FlxEffectSprite> = new FlxTypedGroup<FlxEffectSprite>();
	var diffSelect:Alphabet = new Alphabet(0, 0, "< ? >", true);
	var modifiersSelect:Alphabet = new Alphabet(0, 0, !GameClient.isConnected() ? "GAMEPLAY MODIFIERS" : "MODIFIERS UNAVAILABLE HERE", true);
	var replaysSelect:Alphabet = new Alphabet(0, 0, !GameClient.isConnected() ? "LOAD REPLAY" : "REPLAYS UNAVAILABLE", true);
	var resetSelect:Alphabet = new Alphabet(0, 0, "RESET SCORE", true);

	var topTitle:Alphabet = new Alphabet(0, 0, "LEADERBOARD", true);
	var topLoading:Alphabet = new Alphabet(0, 0, "LOADING", true);
	var topShit:Scoreboard = new Scoreboard(FlxG.width - 200, 32, 15, ["PLAYER", "SCORE", "ACCURACY"]);

	// var sickScore:FlxSprite;
	// var sickSparkle:FlxSprite;

	var _substateIsModifiers = false;

	override function create()
	{
		prevPauseGame = FlxG.autoPause;

		FlxG.autoPause = false;

		//Paths.clearStoredMemory();
		//Paths.clearUnusedMemory();
		
		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", "Freeplay");
		#end

		for (i in 0...WeekData.weeksList.length) {
			if(weekIsLocked(WeekData.weeksList[i])) continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var leSongs:Array<String> = [];
			var leChars:Array<String> = [];

			for (j in 0...leWeek.songs.length)
			{
				leSongs.push(leWeek.songs[j][0]);
				leChars.push(leWeek.songs[j][1]);
			}

			WeekData.setDirectoryFromWeek(leWeek);
			for (song in leWeek.songs)
			{
				var colors:Array<Int> = song[2];
				if(colors == null || colors.length < 3)
				{
					colors = [146, 113, 253];
				}
				addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]), song[3], song[4]);
			}
		}
		Mods.loadTopMod();

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.scrollFactor.set();
		add(bg);
		bg.screenCenter();

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(90, 320, songs[i].songName, true);
			songText.targetY = i;
			grpSongs.add(songText);

			songText.scaleX = Math.min(1, 980 / songText.width);
			songText.snapToPosition();

			Mods.currentModDirectory = songs[i].folder;
			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			
			// too laggy with a lot of songs, so i had to recode the logic for it
			songText.visible = songText.active = songText.isMenuItem = false;
			icon.visible = icon.active = false;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			icon.scrollFactor.set(1, 1);
			add(icon);

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}
		WeekData.setDirectoryFromWeek();

		// sickScore = new FlxSprite(Paths.image('sickScore'));
		// sickScore.antialiasing = ClientPrefs.data.antialiasing;
		// sickScore.visible = false;
		// sickScore.scale.set(0.7, 0.7);
		// sickScore.updateHitbox();
		// add(sickScore);

		// sickSparkle = new FlxSprite();
		// sickSparkle.frames = Paths.getSparrowAtlas('sparkle');
		// sickSparkle.antialiasing = ClientPrefs.data.antialiasing;
		// sickSparkle.animation.addByPrefix('sparkle', 'sick animation', 24, false);
		// sickSparkle.visible = false;
		// sickSparkle.animation.finishCallback = _ -> {
		// 	sickSparkle.visible = false;
		// };
		// add(sickSparkle);

		// dTime.visible = false;
		// dTime.setScale(0.5);
		// add(dTime);
		// add(dShots);
		diffSelect.setScale(0.5);
		diffSelect.visible = false;
		add(diffSelect);

		modifiersSelect.setScale(0.6);
		modifiersSelect.visible = false;
		add(modifiersSelect);

		replaysSelect.setScale(0.6);
		replaysSelect.visible = false;
		add(replaysSelect);

		resetSelect.setScale(0.6);
		resetSelect.visible = false;
		add(resetSelect);

		topTitle.setScale(0.8);
		topTitle.visible = false;
		add(topTitle);

		topLoading.setScale(0.5);
		topLoading.visible = false;
		add(topLoading);

		topShit.visible = false;
		add(topShit);

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		scoreText.scrollFactor.set();

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		scoreBG.scrollFactor.set();
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		diffText.scrollFactor.set();
		add(diffText);
		add(scoreText);

		setDiffVisibility(true);

		gainedText = new FlxText(0, 0, 0, '+ ${gainedPoints}FP');
		if (gainedPoints < 0) {
			var aasss = '${gainedPoints}'.split('');
			aasss.insert(1, ' ');
			gainedText.text = aasss.join('') + "FP";
		}
		gainedText.setFormat(null, 40, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		gainedText.setPosition(FlxG.width - gainedText.width - 50, FlxG.height - gainedText.height - 50);
		gainedText.visible = false;
		gainedText.scrollFactor.set();
		add(gainedText);

		if (gainedPoints != 0) {
			gainedText.visible = true;
			if (gainedPoints > 0) {
				FlxG.sound.play(Paths.sound('fap'));
				if (ClientPrefs.data.flashing)
					FlxFlicker.flicker(gainedText, 1, 0.03, true);
			}

			var prevGained = gainedPoints; 

			new FlxTimer().start(5, (t) -> {
				FlxTween.tween(gainedText, {x: gainedText.x, y: FlxG.height, alpha: 0, angle: prevGained < 0 ? 90 : 0}, 1, {ease: FlxEase.quartOut});
			});
		}

		gainedPoints = 0;

		missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
		missingTextBG.scrollFactor.set();
		add(missingTextBG);
		
		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);

		if(curSelected >= songs.length) curSelected = 0;
		bg.color = songs[curSelected].color;
		intendedColor = bg.color;
		lerpSelected = curSelected;

		curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));

		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		textBG.alpha = 0.6;
		textBG.scrollFactor.set();
		add(textBG);

		infoText = new FlxText(textBG.x, textBG.y + 4, FlxG.width, "???");
		infoText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
		infoText.scrollFactor.set();
		add(infoText);

		if (GameClient.isConnected()) {
			add(chatBox = new ChatBox(camera));
			GameClient.send("status", "Choosing a Song");
		}
		
		changeSelection();
		updateSelectSelection();
		updateTexts();

		super.create();
	}

	override function destroy() {
		super.destroy();

		if (leaderboardTimer != null)
			leaderboardTimer.cancel();
	}

	override function closeSubState() {
		curPage = 0;
		changeSelection(0, false);
		if (_substateIsModifiers) {
			topLoading.visible = true;
			topShit.visible = false;
			if (leaderboardTimer != null)
				leaderboardTimer.cancel();
			leaderboardTimer = new FlxTimer().start(0.5, t -> { generateLeaderboard(); });
			
			_substateIsModifiers = false;
		}
		persistentUpdate = true;
		super.closeSubState();
	}

	function setDiffVisibility(value:Bool) {
		diffText.visible = value;
		scoreBG.scale.y = 1;
		scoreBG.y = 0;
		if (!value) {
			scoreBG.scale.y = 0.7;
			scoreBG.y -= (scoreBG.height - scoreBG.height * scoreBG.scale.y) / 2;
		}
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int, hasErect:Bool, hasNightmare:Bool)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter, color, hasErect, hasNightmare));
	}

	function weekIsLocked(name:String):Bool {
		return false; // always unlocked in online
		// if (GameClient.isConnected())
		// 	return false;
		// var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		//return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	/*public function addWeek(songs:Array<String>, weekNum:Int, weekColor:Int, ?songCharacters:Array<String>)
	{
		if (songCharacters == null)
			songCharacters = ['bf'];

		var num:Int = 0;
		for (song in songs)
		{
			addSong(song, weekNum, songCharacters[num]);
			this.songs[this.songs.length-1].color = weekColor;

			if (songCharacters.length != 1)
				num++;
		}
	}*/

	var instPlaying:Int = -1;
	var trackPlaying:String = null;
	public static var vocals:FlxSound = null;
	public static var opponentVocals:FlxSound = null;
	var holdTime:Float = 0;
	override function update(elapsed:Float)
	{
		Conductor.songPosition = FlxG.sound.music.time;

		for (v in [vocals, opponentVocals]) {
			if (v == null) continue;
			if (v.playing && Math.abs(v.time - (Conductor.songPosition - Conductor.offset)) > 200)
				v.time = FlxG.sound.music.time;
		}

		if (instPlaying != -1) {
			var mult:Float = FlxMath.lerp(1, iconArray[instPlaying].scale.x, FlxMath.bound(1 - (elapsed * 9), 0, 1));
			iconArray[instPlaying].scale.set(mult, mult);
		}

		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, FlxMath.bound(elapsed * 24, 0, 1)));
		lerpRating = FlxMath.lerp(lerpRating, intendedRating, FlxMath.bound(elapsed * 12, 0, 1));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01)
			lerpRating = intendedRating;

		var ratingSplit:Array<String> = Std.string(CoolUtil.floorDecimal(lerpRating * 100, 2)).split('.');
		if(ratingSplit.length < 2) { //No decimals, add an empty space
			ratingSplit.push('');
		}
		
		while(ratingSplit[1].length < 2) { //Less than 2 decimals in it, add decimals then
			ratingSplit[1] += '0';
		}

		scoreText.text = 'PERSONAL BEST: ' + lerpScore + ' (' + ratingSplit.join('.') + '%)';
		positionHighscore();

		if (chatBox != null && chatBox.focused) {
			updateTexts(elapsed);
			super.update(elapsed);
			return;
		}

		var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

		if (!selected) {
			if(songs.length > 1)
			{
				if(FlxG.keys.justPressed.HOME)
				{
					curSelected = 0;
					changeSelection();
					holdTime = 0;	
				}
				else if(FlxG.keys.justPressed.END)
				{
					curSelected = songs.length - 1;
					changeSelection();
					holdTime = 0;	
				}
				if (controls.UI_UP_P)
				{
					changeSelection(-shiftMult);
					holdTime = 0;
				}
				if (controls.UI_DOWN_P)
				{
					changeSelection(shiftMult);
					holdTime = 0;
				}

				if(controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
				}

				if(FlxG.mouse.wheel != 0)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
					changeSelection(-shiftMult * FlxG.mouse.wheel, false);
				}
			}

			if (controls.BACK)
			{
				persistentUpdate = false;
				if(colorTween != null) {
					colorTween.cancel();
				}
				FlxG.sound.play(Paths.sound('cancelMenu'));
				if (GameClient.isConnected()) {
					destroyFreeplayVocals();
					GameClient.clearOnMessage();
					FlxG.switchState(() -> new RoomState());
				}
				else {
					FlxG.switchState(() -> new MainMenuState());
				}
				FlxG.autoPause = prevPauseGame;
			}

			if(FlxG.keys.justPressed.SPACE)
			{
				listenToSong();
			}
			else if (controls.UI_LEFT_P) {
				changeDiff(-1);
				_updateSongLastDifficulty();
			}
			else if (controls.UI_RIGHT_P) {
				changeDiff(1);
				_updateSongLastDifficulty();
			}
			else if (controls.ACCEPT)
			{
				curPage = 0;
				listenToSong();
				selected = true;
				setDiffVisibility(false);
				updateSelectSelection();

				topLoading.visible = true;
				topShit.visible = false;
				if (leaderboardTimer != null)
					leaderboardTimer.cancel();
				leaderboardTimer = new FlxTimer().start(0.5, t -> { generateLeaderboard(); });
			}

			if (chatBox == null && FlxG.keys.justPressed.TAB) {
				persistentUpdate = false;
				FlxG.switchState(() -> new online.states.SkinsState());
			}
		}
		else {
			if (controls.BACK) {
				selected = false;
				selectedItem = 0;
				setDiffVisibility(true);
				updateSelectSelection();
			}
			else if (controls.ACCEPT) {
				switch (selectedItem) {
					case 0:
						if (GameClient.isConnected()) {
							var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
							var poop:String = Highscore.formatSong(songLowercase, curDifficulty);

							persistentUpdate = false;
							// weird ass
							GameClient.room.onMessage("checkChart", function(message) {
								Waiter.put(() -> {
									try {
										var hash = Md5.encode(Song.loadRawSong(GameClient.room.state.song, GameClient.room.state.folder));
										trace("verifying song: " + GameClient.room.state.song + " | " + GameClient.room.state.folder + " : " + hash);
										GameClient.send("verifyChart", hash);
										destroyFreeplayVocals();
										GameClient.clearOnMessage();
										FlxG.switchState(() -> new RoomState());
										FlxG.autoPause = prevPauseGame;
									}
									catch (exc:Dynamic) {
										Sys.println(exc);
									}
								});
							});
							Mods.currentModDirectory = songs[curSelected].folder;
							trace('Song mod directory: "${Mods.currentModDirectory}"');
							try {
								GameClient.send("setFSD", [
									songLowercase,
									poop,
									curDifficulty,
									Md5.encode(Song.loadRawSong(poop, songLowercase)),
									Mods.currentModDirectory,
									online.OnlineMods.getModURL(Mods.currentModDirectory),
									Difficulty.list
								]);
							}
							catch (e:Dynamic) {
								trace('ERROR! $e');

								var errorStr:String = e.toString();
								if (errorStr.startsWith('[file_contents,assets/data/'))
									errorStr = 'Missing file: ' + errorStr.substring(27, errorStr.length - 1); // Missing chart
								missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
								missingText.screenCenter(Y);
								missingText.visible = true;
								missingTextBG.visible = true;
								FlxG.sound.play(Paths.sound('cancelMenu'));

								updateTexts(elapsed);
							}
						}
						else {
							enterSong();
						}
					case 1:
						if (!GameClient.isConnected()) {
							persistentUpdate = false;
							_substateIsModifiers = true;
							openSubState(new GameplayChangersSubstate());
						}
					case 2:
						if (!GameClient.isConnected()) {
							if (!FileSystem.exists("replays/"))
								FileSystem.createDirectory("replays/");

							var fileDialog = new FileDialog();
							fileDialog.onOpen.add(res -> {
								playReplay(cast(res, Bytes).toString());
							});
							fileDialog.open('funkinreplay', Sys.getCwd() + Paths.PATH_SLASH + "replay", "Load Replay File");
						}
					case 3:
						persistentUpdate = false;
						openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
						FlxG.sound.play(Paths.sound('scrollMenu'));
					case 4:
						if (!GameClient.isConnected()) {
							if (top[selectedScore] != null)
								playReplay(Leaderboard.fetchReplay(top[selectedScore].id), top[selectedScore].id);
						}
				}
			}

			if (controls.UI_UP_P) {
				if (selectedItem == 4 && selectedScore != 0) {
					selectedScore--;
				}
				else {
					selectedItem--;

					if (selectedItem < 0) {
						selectedItem = 4;
						selectedScore = 14;
					}
				}

				topShit.selectRow(selectedItem != 4 ? -1 : selectedScore);
				updateSelectSelection();

				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			}
			else if (controls.UI_DOWN_P) {
				if (selectedItem == 4 && selectedScore != 14) {
					selectedScore++;
				}
				else {
					selectedItem++;

					if (selectedItem > 4)
						selectedItem = 0;

					if (selectedItem == 4) {
						selectedScore = 0;
					}
				}

				topShit.selectRow(selectedItem != 4 ? -1 : selectedScore);
				updateSelectSelection();

				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			}

			if (selectedItem == 0) {
				if (controls.UI_LEFT_P) {
					curPage = 0;
					changeDiff(-1);
					_updateSongLastDifficulty();

					topLoading.visible = true;
					topShit.visible = false;
					if (leaderboardTimer != null)
						leaderboardTimer.cancel();
					leaderboardTimer = new FlxTimer().start(0.5, t -> { generateLeaderboard(); });
				}
				else if (controls.UI_RIGHT_P) {
					curPage = 0;
					changeDiff(1);
					_updateSongLastDifficulty();

					topLoading.visible = true;
					topShit.visible = false;
					if (leaderboardTimer != null)
						leaderboardTimer.cancel();
					leaderboardTimer = new FlxTimer().start(0.5, t -> { generateLeaderboard(); });
				}
			}
			else if (selectedItem == 4) {
				if (controls.UI_LEFT_P && curPage != 0) {
					curPage--;
					if (curPage < 0)
						curPage = 0;
					
					topLoading.visible = true;
					topShit.visible = false;
					if (leaderboardTimer != null)
						leaderboardTimer.cancel();
					leaderboardTimer = new FlxTimer().start(0.5, t -> { generateLeaderboard(); });
				}
				else if (controls.UI_RIGHT_P) {
					curPage++;

					topLoading.visible = true;
					topShit.visible = false;
					if (leaderboardTimer != null)
						leaderboardTimer.cancel();
					leaderboardTimer = new FlxTimer().start(0.5, t -> {
						generateLeaderboard();
					});
				}
			}
		}

		updateTexts(elapsed);
		camera.scroll.x = 0;
		super.update(elapsed);
	}

	function playReplay(replayData:String, ?replayID:String) {
		var shit = Json.parse(replayData);
		PlayState.replayData = cast shit;
		PlayState.replayData.gameplay_modifiers = ReplayPlayer.objToMap(shit.gameplay_modifiers);
		PlayState.replayID = replayID;

		var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
		var poop:String = Highscore.formatSong(songLowercase, curDifficulty);

		if (PlayState.replayData.chart_hash == Md5.encode(Song.loadRawSong(poop, songLowercase))) {
			enterSong();
		}
		else {
			PlayState.replayData = null;

			missingText.text = 'OUTDATED REPLAY OR INVALID FOR THIS SONG';
			missingText.screenCenter(Y);
			missingText.visible = true;
			missingTextBG.visible = true;
			FlxG.sound.play(Paths.sound('cancelMenu'));

			updateTexts(FlxG.elapsed);
		}
	}

	var curPage:Int = 0;
	var top:Array<TopScore> = [];
	var leaderboardTimer:FlxTimer;
	function generateLeaderboard() {
		topShit.clearRows();

		if (!selected)
			return;

		try {
			var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
			PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
			
			var uhhPage = curPage;
			Leaderboard.fetchLeaderboard(curPage, filterCharacters(PlayState.SONG.song) + "-" + filterCharacters(Difficulty.getString(curDifficulty)) + "-" + filterCharacters(Md5.encode(Song.loadRawSong(poop, songs[curSelected].songName.toLowerCase()))), top -> {
				if (uhhPage != curPage || !topShit.exists)
					return;

				this.top = top;

				if (top == null) {
					topLoading.visible = false;
					return;
				}

				var coolColor:Null<FlxColor> = null;
				for (i in 0...top.length) {
					if (curPage == 0) {
						switch (i) {
							case 0:
								coolColor = FlxColor.ORANGE;
							default:
								coolColor = null;
						}
					}
					
					topShit.setRow(i, [
						(i + 1 + curPage * 15) + ". " + top[i].player,
						FlxStringUtil.formatMoney(top[i].score, false) + " - " + top[i].points + "FP",
						top[i].accuracy + "%" + (top[i].misses == 0 ? " - FC" : "")
					], coolColor);
				}

				if (selected) {
					topLoading.visible = false;
					topShit.visible = true;
				}
			});
		}
		catch (e:Dynamic) {
			topLoading.visible = false;
		}
	}

	public static function filterCharacters(str:String) {
		var re = ~/[A-Z]|[a-z]|[0-9]/g;
		var finalStr = "";
		for (i in 0...str.length) {
			if (re.match(str.charAt(i)))
				finalStr += str.charAt(i);
		}
		return finalStr;
	}

	var centerPoint:FlxObject;
	function updateSelectSelection() {
		missingText.visible = false;
		missingTextBG.visible = false;

		scoreText.visible = true;
		scoreBG.visible = true;

		camera.targetOffset.set(0, 0);

		switch (selectedItem) {
			case 0:
				if (selected) {
					infoText.text = "Press ACCEPT to enter the Song / Use your Arrow Keys to change the Difficulty";
					camera.targetOffset.y += 200;
				}
				else {
					infoText.text = "Press ACCEPT to select the current Song / Press SPACE to listen to the Song";
					if (chatBox == null)
						infoText.text += ' / Press TAB to select your character!';	
				}

				if (centerPoint == null)
					centerPoint = new FlxObject(FlxG.width / 2, FlxG.height / 2);
				camera.follow(centerPoint, null, 0.15);

				grpSongs.members[curSelected].alpha = 1;
				diffSelect.alpha = 1;
				modifiersSelect.alpha = 0.6;
				resetSelect.alpha = 0.6;
				replaysSelect.alpha = 0.6;
				topTitle.alpha = 0.6;
				topLoading.alpha = 0.6;
			case 1:
				infoText.text = "Press ACCEPT to open Gameplay Modifers Menu";

				camera.follow(modifiersSelect, null, 0.15);
				camera.targetOffset.y += 200;

				grpSongs.members[curSelected].alpha = 0.6;
				diffSelect.alpha = 0.6;
				modifiersSelect.alpha = 1;
				replaysSelect.alpha = 0.6;
				resetSelect.alpha = 0.6;
				topTitle.alpha = 0.6;
				topLoading.alpha = 0.6;
			case 2:
				infoText.text = "Press ACCEPT to load a Replay data file";
				
				camera.follow(replaysSelect, null, 0.15);
				camera.targetOffset.y += 200;

				grpSongs.members[curSelected].alpha = 0.6;
				diffSelect.alpha = 0.6;
				modifiersSelect.alpha = 0.6;
				replaysSelect.alpha = 1;
				resetSelect.alpha = 0.6;
				topTitle.alpha = 0.6;
				topLoading.alpha = 0.6;
			case 3:
				infoText.text = "Press ACCEPT to reset Score and Accuracy of this Song";

				camera.follow(resetSelect, null, 0.15);
				camera.targetOffset.y += 200;

				grpSongs.members[curSelected].alpha = 0.6;
				diffSelect.alpha = 0.6;
				modifiersSelect.alpha = 0.6;
				replaysSelect.alpha = 0.6;
				resetSelect.alpha = 1;
				topTitle.alpha = 0.6;
				topLoading.alpha = 0.6;
			case 4:
				infoText.text = "LEFT or RIGHT to Flip Pages / ACCEPT to view Player's replay of this song";

				camera.follow(topShit.background, null, 0.15);
				camera.targetOffset.y -= 100 + topTitle.height;

				grpSongs.members[curSelected].alpha = 0.6;
				diffSelect.alpha = 0.6;
				modifiersSelect.alpha = 0.6;
				replaysSelect.alpha = 0.6;
				resetSelect.alpha = 0.6;
				topTitle.alpha = 1;
				topLoading.alpha = 1;

				scoreText.visible = false;
				scoreBG.visible = false;
		}

		if (selected)
			infoText.text += " / Press BACK to return to Songs";

		if (GameClient.isConnected()) {
			replaysSelect.alpha -= 0.4;
			modifiersSelect.alpha -= 0.4;
		}
	}

	function listenToSong() {
		var diff = Difficulty.getString(curDifficulty);
		var trackSuffix = diff == "Erect" || diff == "Nightmare" ? "-erect" : "";
		var track = songs[curSelected].songName.toLowerCase() + trackSuffix;

		if (track != trackPlaying) {
			try {
				#if PRELOAD_ALL
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;
				Mods.currentModDirectory = songs[curSelected].folder;
				var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
				PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
				Conductor.bpm = PlayState.SONG.bpm;
				Conductor.mapBPMChanges(PlayState.SONG);

				vocals = new FlxSound();
				opponentVocals = new FlxSound();

				if (PlayState.SONG.needsVoices) {
					try {
						var playerVocals = Paths.voices(PlayState.SONG.song, 'Player', trackSuffix);
						vocals.loadEmbedded(playerVocals != null ? playerVocals : Paths.voices(PlayState.SONG.song, null, trackSuffix));
						
						var oppVocals = Paths.voices(PlayState.SONG.song, 'Opponent', trackSuffix);
						if(oppVocals != null) opponentVocals.loadEmbedded(oppVocals);
					}
					catch (exc:Dynamic) {
						var file:Dynamic = Paths.voices(PlayState.SONG.song, null, trackSuffix);
						if (Std.isOfType(file, Sound) || OpenFlAssets.exists(file)) {
							vocals.loadEmbedded(file);
						}
					}
				}

				FlxG.sound.list.add(vocals);
				FlxG.sound.list.add(opponentVocals);
				FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song, trackSuffix), 0.7);
				for (v in [vocals, opponentVocals]) {
					if (v == null) continue;
					v.play();
					v.persist = true;
					v.looped = true;
					v.volume = 0.7;
				}
				instPlaying = curSelected;
				trackPlaying = track;
				listening = true;
				#end
			}
			catch (e:Dynamic) {
				trace('ERROR! $e');

				var errorStr:String = e.toString();
				if (errorStr.startsWith('[file_contents,assets/data/'))
					errorStr = 'Missing file: ' + errorStr.substring(27, errorStr.length - 1); // Missing chart
				missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
				missingText.screenCenter(Y);
				missingText.visible = true;
				missingTextBG.visible = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));

				playFreakyMusic();

				updateTexts(FlxG.elapsed);
			}
		}
	}

	public function playFreakyMusic() {
		FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
		FlxG.sound.music.fadeIn(3, 0, 0.7);
		listening = false;
		instPlaying = -1;
		trackPlaying = null;
		destroyFreeplayVocals();
	}

	public static function destroyFreeplayVocals() {
		for (v in [vocals, opponentVocals]) {
			if (v == null) continue;
			v.stop();
			v.destroy();
		}
		vocals = null;
		opponentVocals = null;
	}

	function changeDiff(change:Int = 0)
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = Difficulty.list.length-1;
		if (curDifficulty >= Difficulty.list.length)
			curDifficulty = 0;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

		lastDifficultyName = Difficulty.getString(curDifficulty);
		if (Difficulty.list.length > 1) {
			diffSelect.text = diffText.text = '< ' + lastDifficultyName.toUpperCase() + ' >'; 
		}
		else {
			diffSelect.text = diffText.text = lastDifficultyName.toUpperCase();
		}

		positionHighscore();
		missingText.visible = false;
		missingTextBG.visible = false;

		if (selected)
			listenToSong();
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if (selected)
			return;

		_updateSongLastDifficulty();
		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		var lastList:Array<String> = Difficulty.list;
		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;
			
		var newColor:Int = songs[curSelected].color;
		if(newColor != intendedColor) {
			if(colorTween != null) {
				colorTween.cancel();
			}
			intendedColor = newColor;
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
				onComplete: function(twn:FlxTween) {
					colorTween = null;
				}
			});
		}

		// selector.y = (70 * curSelected) + 30;

		var bullShit:Int = 0;

		for (i in 0...iconArray.length)
		{
			iconArray[i].alpha = 0.6;
			if (i != instPlaying)
				iconArray[i].scale.set(1, 1);
		}

		iconArray[curSelected].alpha = 1;

		for (item in grpSongs.members)
		{
			bullShit++;
			item.alpha = 0.6;
			if (item.targetY == curSelected)
				item.alpha = 1;
		}
		
		Mods.currentModDirectory = songs[curSelected].folder;
		PlayState.storyWeek = songs[curSelected].week;
		Difficulty.loadFromWeek();
		
		var savedDiff:String = songs[curSelected].lastDifficulty;
		var lastDiff:Int = Difficulty.list.indexOf(lastDifficultyName);
		if(savedDiff != null && !lastList.contains(savedDiff) && Difficulty.list.contains(savedDiff))
			curDifficulty = Math.round(Math.max(0, Difficulty.list.indexOf(savedDiff)));
		else if(lastDiff > -1)
			curDifficulty = lastDiff;
		else if(Difficulty.list.contains(Difficulty.getDefault()))
			curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(Difficulty.getDefault())));
		else
			curDifficulty = 0;

		changeDiff();
		_updateSongLastDifficulty();
	}

	inline private function _updateSongLastDifficulty()
	{
		songs[curSelected].lastDifficulty = Difficulty.getString(curDifficulty);
	}

	private function positionHighscore() {
		scoreText.x = FlxG.width - scoreText.width - 6;
		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);
		diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		diffText.x -= diffText.width / 2;
	}

	var _drawDistance:Int = 4;
	var _lastVisibles:Array<Int> = [];
	var _lastSelected:Bool = false;
	public function updateTexts(elapsed:Float = 0.0)
	{
		lerpSelected = FlxMath.lerp(lerpSelected, curSelected, FlxMath.bound(elapsed * 9.6, 0, 1));
		for (i in _lastVisibles)
		{
			grpSongs.members[i].visible = grpSongs.members[i].active = false;
			iconArray[i].visible = iconArray[i].active = false;
		}
		_lastVisibles = [];

		var min:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected - _drawDistance)));
		var max:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected + _drawDistance)));
		for (i in min...max)
		{
			var item:Alphabet = grpSongs.members[i];
			item.visible = item.active = true;
			if (!selected)
				item.x = ((item.targetY - lerpSelected) * item.distancePerItem.x) + item.startPosition.x;
			item.y = ((item.targetY - lerpSelected) * 1.3 * item.distancePerItem.y) + item.startPosition.y;

			var icon:HealthIcon = iconArray[i];
			icon.visible = icon.active = true;
			_lastVisibles.push(i);

			if (selected) {
				if (i == curSelected) {
					item.x = FlxMath.lerp(item.x, FlxG.width / 2 - item.width / 2, FlxG.elapsed * 5);

					var daCenter = item.x + item.width / 2;

					diffSelect.x = daCenter - diffSelect.width / 2;
					diffSelect.y = item.y + 70;

					modifiersSelect.x = daCenter - modifiersSelect.width / 2;
					modifiersSelect.y = item.y + item.height + 50;

					replaysSelect.x = daCenter - replaysSelect.width / 2;
					replaysSelect.y = modifiersSelect.y + modifiersSelect.height;

					resetSelect.x = daCenter - resetSelect.width / 2;
					resetSelect.y = replaysSelect.y + replaysSelect.height;

					topTitle.x = daCenter - topTitle.width / 2;
					topTitle.y = resetSelect.y + resetSelect.height + 50;

					topShit.x = daCenter - topShit.width / 2;
					topShit.y = topTitle.y + topTitle.height + 30;

					topLoading.x = daCenter - topLoading.width / 2;
					topLoading.y = topTitle.y + 50;
				}
				else
					item.alpha -= elapsed * 4;
			}
			else if (i != curSelected) {
				item.alpha = FlxMath.bound(item.alpha + elapsed * 5, 0, 0.6);
			}

			// if (i == curSelected) {
			// 	sickScore.visible = selected && intendedRating > 0.9;
			// 	sickScore.setPosition(item.x - sickScore.width - 50, item.y + item.height / 2 - sickScore.height / 2);

			// 	if (sickScore.visible && (sickSparkle.animation.curAnim == null || sickSparkle.animation.curAnim.finished) && FlxG.random.bool(0.5)) {
			// 		sickSparkle.setPosition(
			// 			FlxG.random.float(sickScore.x - 20, sickScore.x + sickScore.width - 20),
			// 			FlxG.random.float(sickScore.y - 20, sickScore.y + sickScore.height - 20)
			// 		);
			// 		sickSparkle.visible = true;
			// 		sickSparkle.animation.play('sparkle');
			// 		sickSparkle.animation.curAnim.frameRate = FlxG.random.int(16, 30);
			// 	}
			// }

			icon.alpha = item.alpha;
		}

		if (_lastSelected != selected) {
			if (selected) {
				diffSelect.visible = true;
				resetSelect.visible = true;
				replaysSelect.visible = true;
				modifiersSelect.visible = true;
				topTitle.visible = true;
			}
			else {
				diffSelect.visible = false;
				resetSelect.visible = false;
				replaysSelect.visible = false;
				modifiersSelect.visible = false;
				topTitle.visible = false;
				topLoading.visible = false;
				topShit.visible = false;
			}
		}

		_lastSelected = selected;
	}

	override function beatHit() {
		if (instPlaying != -1 && listening)
			iconArray[instPlaying].scale.set(1.2, 1.2);
	}

	function enterSong() {
		var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
		var poop:String = Highscore.formatSong(songLowercase, curDifficulty);

		try {
			PlayState.SONG = Song.loadFromJson(poop, songLowercase);
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = curDifficulty;
			var diff = Difficulty.getString(curDifficulty);
			//PlayState.isErect = diff == "Erect" || diff == "Nightmare";

			trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
			if (colorTween != null) {
				colorTween.cancel();
			}
		}
		catch (e:Dynamic) {
			trace('ERROR! $e');

			PlayState.replayData = null;

			var errorStr:String = e.toString();
			if (errorStr.startsWith('[file_contents,assets/data/'))
				errorStr = 'Missing file: ' + errorStr.substring(27, errorStr.length - 1); // Missing chart
			missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
			missingText.screenCenter(Y);
			missingText.visible = true;
			missingTextBG.visible = true;
			FlxG.sound.play(Paths.sound('cancelMenu'));
			
			return;
		}
		LoadingState.loadAndSwitchState(new PlayState());
		FlxG.autoPause = prevPauseGame;

		FlxG.sound.music.volume = 0;

		destroyFreeplayVocals();
		#if (MODS_ALLOWED && DISCORD_ALLOWED)
		DiscordClient.loadModRPC();
		#end
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:Int = -7179779;
	public var folder:String = "";
	public var lastDifficulty:String = null;
	public var hasErect:Bool = false;
	public var hasNightmare:Bool = false;

	public function new(song:String, week:Int, songCharacter:String, color:Int, hasErect:Bool, hasNightmare:Bool)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		this.folder = Mods.currentModDirectory;
		if(this.folder == null) this.folder = '';
		this.hasErect = hasErect;
		this.hasNightmare = hasNightmare;
	}
}