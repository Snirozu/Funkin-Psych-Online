package states;

import flixel.FlxBasic;
import flixel.FlxSubState;
import backend.ClientPrefs;
import objects.Character;
import objects.Character.CharacterFile;
import openfl.events.KeyboardEvent;
import lime.system.Clipboard;
import flixel.tweens.misc.ShakeTween;
import online.replay.ReplayPlayer;
import online.replay.ReplayRecorder.ReplayData;
import json2object.JsonParser;
import flixel.effects.FlxFlicker;
import online.objects.Scoreboard;
import online.network.Leaderboard;
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
import online.objects.ChatBox;
import online.gui.Alert;
import online.backend.Waiter;
import haxe.crypto.Md5;
import online.states.RoomState;
import online.GameClient;
import backend.WeekData;
import backend.Highscore;
import backend.Song;
import openfl.media.Sound;
import flixel.system.FlxAssets.FlxGraphicAsset;

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
	public static var instance:FreeplayState;
	public var songs:Array<SongMetadata> = [];

	var selector:FlxText;
	public static var curSelected:Int = 0; 
	public var lerpSelected:Float = 0;
	var curDifficulty:Int = -1;
	private static var lastDifficultyName:String = Difficulty.getDefault();

	public static var gainedPoints:Float = 0;
	var gainedText:FlxText;

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var searchInput:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;
	var infoText:FlxText;
	
	var randomText:Scrollable;
	var randomIcon:HealthIcon;

	var groupTitle:Scrollable;

	private var grpSongs:FlxTypedGroup<FlxSprite>;
	private var grpIcons:FlxTypedGroup<HealthIcon>;
	private var grpHearts:FlxTypedGroup<Heart>;
	private var curPlaying:Bool = false;

	private var initSongs:Array<SongMetadata> = [];
	private var initSongItems:Array<Dynamic> = [];

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

	static var bustSound:FlxSound;
	static var favSound:FlxSound;
	static var unfavSound:FlxSound;
	var explods:FlxTypedGroup<Explod>;

	// var dTime:Alphabet = new Alphabet(0, 0, "0:00", false);
	// var dShots:FlxTypedGroup<FlxEffectSprite> = new FlxTypedGroup<FlxEffectSprite>();
	var diffSelect:Alphabet = new Alphabet(0, 0, "< ? >", true);
	var modifiersSelect:Alphabet = new Alphabet(0, 0, !GameClient.isConnected() ? "GAMEPLAY MODIFIERS" : "MODIFIERS UNAVAILABLE HERE", true);
	var replaysSelect:Alphabet = new Alphabet(0, 0, !GameClient.isConnected() ? "LOAD REPLAY" : "REPLAYS UNAVAILABLE", true);
	var resetSelect:Alphabet = new Alphabet(0, 0, "RESET SCORE", true);

	var topTitle:Alphabet = new Alphabet(0, 0, "LEADERBOARD", true);
	var topLoading:Alphabet = new Alphabet(0, 0, "LOADING", true);
	var topShit:Scoreboard = new Scoreboard(FlxG.width - 200, 32, 15, ["PLAYER", "SCORE", "ACCURACY"]);

	var touchingAndEmotionalQuotes:Array<Dynamic> = [
		[80, [
			"PROTECT YO NUTS BOYFRIEND",
			"DON'T STOP BOYFRIEND",
			"FUNK 'EM UP BOYFRIEND",
		]],
		[18, [
			"GO FOR A 100% BOYFRIEND",
			"GO WITH THE RHYTHM BOYFRIEND",
			"STAY FUNKY BOYFRIEND",
		]],
		[1.99, [
			"GET LAID BOYFRIEND",
			"DON'T KNOCK UP BOYFRIEND",
			"BEHIND YOU BOYFRIEND",
		]],
		[0.01, [
			"DRINK PISS BOYFRIEND",
			"COME TO BRAZIL BOYFRIEND",
			"FUNK THEIR BRAINS OUT BOYFRIEND",
		]]
	];
	var randomMessage(get, default):String = null;
	function get_randomMessage():String {
		if (randomMessage != null)
			return randomMessage;
		
		var chances:Array<Float> = [];
		for (group in touchingAndEmotionalQuotes)
			chances.push(Std.parseFloat(group[0]));
		var quotes = touchingAndEmotionalQuotes[FlxG.random.weightedPick(chances)][1];
		return randomMessage = StringTools.replace(quotes[FlxG.random.int(0, quotes.length - 1)], 'BOYFRIEND', ClientPrefs.getNickname().toUpperCase());
	}

	// weightedPick

	// var sickScore:FlxSprite;
	// var sickSparkle:FlxSprite;

	var _substateIsModifiers = false;

	var itemsCamera:FlxCamera;
	var hudCamera:FlxCamera;

	override function create()
	{
		instance = this;

		prevPauseGame = FlxG.autoPause;

		FlxG.mouse.visible = false;
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

		itemsCamera = new FlxCamera();
		itemsCamera.bgColor.alpha = 0;
		hudCamera = new FlxCamera();
		hudCamera.bgColor.alpha = 0;
		FlxG.cameras.add(itemsCamera, false);
		FlxG.cameras.add(hudCamera, false);
		
		CustomFadeTransition.nextCamera = hudCamera;

		grpSongs = new FlxTypedGroup<FlxSprite>();
		grpSongs.cameras = [itemsCamera];
		add(grpSongs);

		grpIcons = new FlxTypedGroup<HealthIcon>();
		grpIcons.cameras = [itemsCamera];
		add(grpIcons);

		grpHearts = new FlxTypedGroup<Heart>();
		grpHearts.cameras = [itemsCamera];
		grpHearts.recycle(Heart);
		add(grpHearts);

		// if (!ClientPrefs.data.disableFreeplayAlphabet)
			randomText = new Alphabet(90, 320, "RANDOM", true);
		// else
		// 	randomText = new online.objects.AlphaLikeText(90, 320, "RANDOM");
		randomText.scaleX = Math.min(1, 980 / randomText.width);
		randomText.targetY = -1;
		randomText.snapToPosition();
		randomText.cameras = [itemsCamera];
		add(cast randomText);

		// if (!ClientPrefs.data.disableFreeplayAlphabet)
			groupTitle = new Alphabet(90, 320, "DEFAULT", true);
		// else
		// 	groupTitle = new online.objects.AlphaLikeText(90, 320, "");
		groupTitle.targetY = -2;
		groupTitle.snapToPosition();
		groupTitle.cameras = [itemsCamera];
		add(cast groupTitle);

		var curSkin = ClientPrefs.data.modSkin ?? [null, null];

		Mods.currentModDirectory = curSkin[0];
		var charaData:CharacterFile = Character.getCharacterFile(curSkin[1]);
		randomIcon = new HealthIcon(charaData.healthicon);
		randomIcon.sprTracker = cast randomText;
		randomIcon.scrollFactor.set(1, 1);
		randomIcon.cameras = [itemsCamera];
		add(randomIcon);

		if (bustSound == null) {
			bustSound = new FlxSound();
			bustSound.loadEmbedded(Paths.sound('badexplosion'));
			bustSound.persist = true;
		}

		if (favSound == null) {
			favSound = new FlxSound();
			favSound.loadEmbedded(Paths.sound('fav'));
			favSound.persist = true;
		}
		
		if (unfavSound == null) {
			unfavSound = new FlxSound();
			unfavSound.loadEmbedded(Paths.sound('unfav'));
			unfavSound.persist = true;
		}

		explods = new FlxTypedGroup<Explod>();
		explods.cameras = [itemsCamera];
		explods.add(new Explod());
		add(explods);

		// preload random music
		Paths.music('freeplayRandom');

		Mods.loadTopMod();

		trace("drawing songs");
		var drawTime = Sys.time();

		var modList:Array<String> = [];

		for (i in 0...initSongs.length) {
			var songText:Scrollable;
			if (!ClientPrefs.data.disableFreeplayAlphabet)
				songText = new Alphabet(90, 320, initSongs[i].songName, true);
			else
				songText = new online.objects.AlphaLikeText(90, 320, initSongs[i].songName);
			songText.scaleX = Math.min(1, 980 / songText.width);
			songText.targetY = i;
			songText.snapToPosition();
			songText.visible = songText.active = songText.isMenuItem = false;

			Mods.currentModDirectory = initSongs[i].folder;
			var icon = ClientPrefs.data.disableFreeplayIcons ? null : new HealthIcon(initSongs[i].songCharacter);
			if (icon != null) {
				icon.sprTracker = cast(songText);
				icon.visible = icon.active = false;
				icon.scrollFactor.set(1, 1);
			}
			if (!modList.contains(Mods.currentModDirectory)) {
				modList.push(Mods.currentModDirectory);
			}
			initSongItems.push([songText, icon]);
		}
		WeekData.setDirectoryFromWeek();

		trace("finished drawing songs (" + FlxMath.roundDecimal(Sys.time() - drawTime, 2) + "s)"
		+ (ClientPrefs.data.disableFreeplayAlphabet ? ' (fast render)' : '')
		+ (ClientPrefs.data.disableFreeplayIcons ? ' (no icons)' : '')
		);

		var newGroup:GroupType = null;
		switch (ClientPrefs.data.groupSongsBy) {
			case 'Alphabetically':
				newGroup = ALPHABET;
			case 'Modpack':
				newGroup = MOD;
			case 'Character Mix':
				newGroup = MIX;
			case 'Hidden':
				newGroup = HIDDEN;
			case 'Favorites':
				newGroup = FAV;
			default:
				newGroup = NONE;
		}
		if (newGroup != searchGroup) {
			searchGroup = newGroup;
			searchGroupValue = 0;
		}

		switch (searchGroup) {
			case ALPHABET:
				searchGroupVList = ['ab', 'cd', 'ef', 'gh', 'ij', 'kl', 'mn', 'op', 'qr', 'st', 'uv', 'wx', 'yz'];
			case MOD:
				searchGroupVList = modList;
			case MIX:
				searchGroupVList = [];
			case HIDDEN:
				searchGroupVList = ['Hidden', 'Visible'];
			case FAV:
				searchGroupVList = ['Favorites', 'Not Favorited'];
			default:
				searchGroupVList = [];
		}

		if (searchGroupValue < 0)
			searchGroupValue = 0;
		if (searchGroupValue > searchGroupVList.length - 1)
			searchGroupValue = searchGroupVList.length - 1;

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		scoreText.scrollFactor.set();

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		scoreBG.scrollFactor.set();
		scoreBG.cameras = [hudCamera];

		searchInput = new FlxText(scoreText.x, scoreText.y + 36, 0, "PRESS F TO SEARCH", 24);
		searchInput.font = scoreText.font;
		searchInput.scrollFactor.set();

		searchInput.cameras = [hudCamera];
		scoreText.cameras = [hudCamera];

		search(true);
		updateGroupTitle();

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
		diffSelect.cameras = [itemsCamera];
		add(diffSelect);

		modifiersSelect.setScale(0.6);
		modifiersSelect.visible = false;
		modifiersSelect.cameras = [itemsCamera];
		add(modifiersSelect);

		replaysSelect.setScale(0.6);
		replaysSelect.visible = false;
		replaysSelect.cameras = [itemsCamera];
		add(replaysSelect);

		resetSelect.setScale(0.6);
		resetSelect.visible = false;
		resetSelect.cameras = [itemsCamera];
		add(resetSelect);

		topTitle.setScale(0.8);
		topTitle.visible = false;
		topTitle.cameras = [itemsCamera];
		add(topTitle);

		topLoading.setScale(0.5);
		topLoading.visible = false;
		topLoading.cameras = [itemsCamera];
		add(topLoading);

		topShit.visible = false;
		topShit.cameras = [itemsCamera];
		add(topShit);

		add(scoreBG);
		add(searchInput);
		add(scoreText);

		setDiffVisibility(true);

		gainedText = new FlxText(0, 0, 0, '+ 0FP');
		// dead ass forgot about abs lmao
		// if (gainedPoints < 0) {
		// 	var aasss = '${gainedPoints}'.split(''); 
		// 	aasss.insert(1, ' ');
		// 	gainedText.text = aasss.join('') + "FP";
		// }
		var shakeTimer:ShakeTween = null;
		var swagFP = null;
		var endFP = gainedPoints;
		if (gainedPoints != 0) {
			FlxG.sound.music.fadeOut(0.5, 0.2);

			FlxTween.num(0, endFP, 1 + (Math.abs(endFP) * 0.02), {
				onComplete: (_) -> {
					if (endFP > 0) {
						FlxG.sound.play(Paths.sound('fap'));

						if (ClientPrefs.data.flashing)
							FlxFlicker.flicker(gainedText, 1, 0.03, true);
					}

					if (shakeTimer != null)
						shakeTimer.cancel();

					new FlxTimer().start(5, (t) -> {
						FlxTween.tween(gainedText, {x: gainedText.x, y: FlxG.height, alpha: 0, angle: swagFP < 0 ? 90 : 0}, 1, {ease: FlxEase.quartOut});
					});

					FlxG.sound.music.fadeIn(3, 0.2, 1);
				},
				startDelay: 1,
				ease: FlxEase.quadOut
			}, (v) -> {
				if (swagFP == Math.floor(v))
					return;

				swagFP = Math.floor(v);

				if (swagFP < 0) {
					gainedText.text = '- ${Math.abs(swagFP)}FP';
					var sound = FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
					sound.pitch = 1 - Math.abs(swagFP) * 0.01;
				}
				else {
					gainedText.text = '+ ${swagFP}FP';
					var sound = FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
					sound.pitch = 1 + Math.abs(swagFP) * 0.01;
				}

				if (shakeTimer != null)
					shakeTimer.cancel();
				shakeTimer = FlxTween.shake(gainedText, FlxMath.bound(swagFP * 0.002, 0, 0.05), 1);
				
				gainedText.setPosition(FlxG.width - gainedText.width - 50, FlxG.height - gainedText.height - 50);
			});
		}
		gainedText.setFormat(null, 40, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		gainedText.setPosition(FlxG.width - gainedText.width - 50, FlxG.height - gainedText.height - 50);
		gainedText.visible = gainedPoints != 0;
		gainedText.scrollFactor.set();
		gainedText.cameras = [hudCamera];
		add(gainedText);

		gainedPoints = 0;

		missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
		missingTextBG.scrollFactor.set();
		missingTextBG.cameras = [hudCamera];
		add(missingTextBG);
		
		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		missingText.cameras = [hudCamera];
		add(missingText);

		if(curSelected >= songs.length) curSelected = -1;
		intendedColor = bg.color;
		lerpSelected = -1;

		curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));

		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		textBG.alpha = 0.6;
		textBG.scrollFactor.set();
		textBG.cameras = [hudCamera];
		add(textBG);

		infoText = new FlxText(textBG.x, textBG.y + 4, FlxG.width, "???");
		infoText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
		infoText.scrollFactor.set();
		infoText.cameras = [hudCamera];
		add(infoText);

		if (GameClient.isConnected()) {
			add(chatBox = new ChatBox(camera));
			chatBox.cameras = [hudCamera];
			GameClient.send("status", "Choosing a Song");
		}
		
		changeSelection();
		updateTexts();
		searchString = searchString;

		super.create();

		CustomFadeTransition.nextCamera = hudCamera;

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
	}

	override function destroy() {
		super.destroy();

		FlxG.cameras.remove(itemsCamera);
		FlxG.cameras.remove(hudCamera);

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);

		if (leaderboardTimer != null)
			leaderboardTimer.cancel();
	}

	override function openSubState(SubState:FlxSubState) {
		if (!(SubState is CustomFadeTransition)) {
			hudCamera.visible = false;
			itemsCamera.visible = false;
		}

		super.openSubState(SubState);
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

		if (!(subState is CustomFadeTransition)) {
			hudCamera.visible = true;
			itemsCamera.visible = true;
		}

		super.closeSubState();
	}

	function setDiffVisibility(value:Bool) {
		searchInput.visible = value;
		scoreBG.scale.y = 1;
		scoreBG.y = 0;
		if (!value) {
			scoreBG.scale.y = 0.7;
			scoreBG.y -= (scoreBG.height - scoreBG.height * scoreBG.scale.y) / 2;
		}
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int, hasErect:Bool, hasNightmare:Bool)
	{
		initSongs.push(new SongMetadata(songName, weekNum, songCharacter, color, hasErect, hasNightmare));
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

		if (instPlaying != -1 && grpIcons.members[instPlaying] != null) {
			var mult:Float = FlxMath.lerp(1, grpIcons.members[instPlaying].scale.x, FlxMath.bound(1 - (elapsed * 9), 0, 1));
			grpIcons.members[instPlaying].scale.set(mult, mult);
		}
		else {
			var mult:Float = FlxMath.lerp(1, randomIcon.scale.x, FlxMath.bound(1 - (elapsed * 9), 0, 1));
			randomIcon.scale.set(mult, mult);
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

		if (curSelected == -1)
			scoreText.text = randomMessage;
		else
			scoreText.text = 'PERSONAL BEST: ' + lerpScore + ' (' + ratingSplit.join('.') + '%)';
		positionHighscore();

		if ((chatBox != null && chatBox.focused) || searchInputWait) {
			updateTexts(elapsed);
			super.update(elapsed);
			return;
		}

		if (!searchInputWait && FlxG.keys.justPressed.F) {
			searchInputWait = true;
			searchString = searchString;
		}

		var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

		if (!selected) {
			if(songs.length > 0)
			{
				if(FlxG.keys.justPressed.HOME)
				{
					curSelected = -1;
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

				if (controls.FAV && curSelected != -1) {
					var songId = songs[curSelected].songName + '-' + songs[curSelected].folder;
					if (ClientPrefs.data.favSongs.contains(songId)) {
						ClientPrefs.data.favSongs.remove(songId);

						unfavSound.volume = 1;
						unfavSound.play(true);
					}
					else {
						ClientPrefs.data.favSongs.push(songId);

						favSound.volume = 1;
						favSound.play(true);
					}
					ClientPrefs.saveSettings();
					search();
				}

				if (controls.RESET && curSelected != -1 && !FlxG.keys.pressed.ALT) {
					var songId = songs[curSelected].songName + '-' + songs[curSelected].folder;
					if (ClientPrefs.data.hiddenSongs.contains(songId)) {
						ClientPrefs.data.hiddenSongs.remove(songId);
					}
					else {
						ClientPrefs.data.hiddenSongs.push(songId);
						destroyFreeplayVocals();
						playFreakyMusic();
						FlxG.sound.music.fadeIn(bustSound.length / 1000 + 1, 0, 0.7);

						bustSound.volume = 1;
						bustSound.play(true);

						var exploAmount:Int = Std.int((grpSongs.members[curSelected].width + grpIcons.members[curSelected].width) / 80) + 1;
						for (i in 0...exploAmount) {
							var explood = explods.recycle(Explod);
							explood.boom(cast grpSongs.members[curSelected], i);
						}
					}
					ClientPrefs.saveSettings();
					search();
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

			if (controls.RESET && FlxG.keys.pressed.ALT) {
				ClientPrefs.data.hiddenSongs = [];
				ClientPrefs.saveSettings();
				search();
			}

			if (searchGroupVList.length > 0) {
				if (controls.UI_LEFT_P) {
					searchGroupValue--;
					search();
					updateGroupTitle();
				}
				if (controls.UI_RIGHT_P) {
					searchGroupValue++;
					search();
					updateGroupTitle();
				}

				if (FlxG.keys.justPressed.CONTROL) {
					persistentUpdate = false;
					var daCopy = searchGroupVList.copy();
					if (daCopy[0] == null || daCopy[0].trim().length < 1)
						daCopy[0] = "Default";
					openSubState(new online.substates.SoFunkinSubstate(daCopy, searchGroupValue, i -> {
						searchGroupValue = i;
						search();
						updateGroupTitle();
						return true;
					}));
				}
			}

			if (controls.BACK)
			{
				if (searchString.length > 0) {
					searchString = '';
					search();
				}
				else {
					persistentUpdate = false;
					if (colorTween != null) {
						colorTween.cancel();
					}
					if (curSelected == -1)
						playFreakyMusic();
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
			}

			if(FlxG.keys.justPressed.SPACE)
			{
				if (curSelected == -1) {
					var newSel = FlxG.random.int(0, songs.length - 1);
					if (newSel == -1)
						newSel = 0;
					curSelected = newSel;
					changeSelection();
					return;
				}

				listenToSong();
			}
			else if (controls.ACCEPT && songs.length > 0)
			{
				if (curSelected == -1) {
					var newSel = FlxG.random.int(0, songs.length - 1);
					if (newSel == -1)
						newSel = 0;
					curSelected = newSel;
					changeSelection();
					lerpSelected = curSelected;
				}

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
									online.mods.OnlineMods.getModURL(Mods.currentModDirectory),
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
							fileDialog.open('funkinreplay', online.util.FileUtils.joinNativePath([Sys.getCwd(), "replays", "_"]), "Load Replay File");
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
		if (FlxG.keys.pressed.SHIFT && !selected) {
			itemsCameraZoom = FlxMath.lerp(itemsCameraZoom, 0.65, elapsed * 10);
			itemsCameraScrollX = FlxMath.lerp(itemsCameraScrollX, 300, elapsed * 10);
		}
		else {
			itemsCameraZoom = FlxMath.lerp(itemsCameraZoom, 1, elapsed * 10);
			itemsCameraScrollX = FlxMath.lerp(itemsCameraScrollX, 0, elapsed * 10);
		}
		itemsCamera.zoom = itemsCameraZoom;
		itemsCamera.scroll.x = itemsCameraScrollX;
		super.update(elapsed);
	}

	var itemsCameraZoom:Float = 1;
	var itemsCameraScrollX:Float = 0;

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

					var ratingFC = 'Clear';
					if(top[i].misses < 1) {
						if (top[i].shits > 0) ratingFC = 'NM';
						else if (top[i].bads > 0) ratingFC = 'FC';
						else if (top[i].goods > 0) ratingFC = 'GFC';
						else if (top[i].sicks > 0) ratingFC = 'SFC';
					}
					else if (top[i].misses < 10)
						ratingFC = 'SDCB';

					var fpRating = '';
					if (top[i].playbackRate != 0.0) {
						if (top[i].playbackRate > 1.0)
							fpRating = "+";
						else if (top[i].playbackRate < 1.0)
							fpRating = "-";
					}
					
					topShit.setRow(i, [
						(i + 1 + curPage * 15) + ". " + top[i].player,
						FlxStringUtil.formatMoney(top[i].score, false) + " - " + top[i].points + "FP" + fpRating,
						top[i].accuracy + "% - " + ratingFC
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

		itemsCamera.targetOffset.set(0, 0);

		if (curSelected == -1) {
			infoText.text = "ACCEPT to select a random song / SPACE to select without loading";
			if (chatBox == null)
				infoText.text += ' / TAB to select your character!';	
			return;
		}

		switch (selectedItem) {
			case 0:
				if (selected) {
					infoText.text = "ACCEPT to enter the Song / Use your Arrow Keys to change the Difficulty";
					itemsCamera.targetOffset.y += 200;
				}
				else {
					infoText.text = "ACCEPT to select the Song / SPACE to listen to the Song / RESET to " + (searchGroup == HIDDEN && searchGroupValue == 0 ? 'show' : 'hide') + " the Song";
					if (chatBox == null)
						infoText.text += ' / TAB to select your character!';
				}

				if (centerPoint == null)
					centerPoint = new FlxObject(FlxG.width / 2, FlxG.height / 2);
				itemsCamera.follow(centerPoint, null, 0.15);

				grpSongs.members[curSelected].alpha = 1;
				diffSelect.alpha = 1;
				modifiersSelect.alpha = 0.6;
				resetSelect.alpha = 0.6;
				replaysSelect.alpha = 0.6;
				topTitle.alpha = 0.6;
				topLoading.alpha = 0.6;
			case 1:
				infoText.text = "ACCEPT to open Gameplay Modifers Menu";

				itemsCamera.follow(modifiersSelect, null, 0.15);
				itemsCamera.targetOffset.y += 200;

				grpSongs.members[curSelected].alpha = 0.6;
				diffSelect.alpha = 0.6;
				modifiersSelect.alpha = 1;
				replaysSelect.alpha = 0.6;
				resetSelect.alpha = 0.6;
				topTitle.alpha = 0.6;
				topLoading.alpha = 0.6;
			case 2:
				infoText.text = "ACCEPT to load a Replay data file";
				
				itemsCamera.follow(replaysSelect, null, 0.15);
				itemsCamera.targetOffset.y += 200;

				grpSongs.members[curSelected].alpha = 0.6;
				diffSelect.alpha = 0.6;
				modifiersSelect.alpha = 0.6;
				replaysSelect.alpha = 1;
				resetSelect.alpha = 0.6;
				topTitle.alpha = 0.6;
				topLoading.alpha = 0.6;
			case 3:
				infoText.text = "ACCEPT to reset Score and Accuracy of this Song";

				itemsCamera.follow(resetSelect, null, 0.15);
				itemsCamera.targetOffset.y += 200;

				grpSongs.members[curSelected].alpha = 0.6;
				diffSelect.alpha = 0.6;
				modifiersSelect.alpha = 0.6;
				replaysSelect.alpha = 0.6;
				resetSelect.alpha = 1;
				topTitle.alpha = 0.6;
				topLoading.alpha = 0.6;
			case 4:
				infoText.text = "LEFT or RIGHT to Flip Pages / ACCEPT to view Player's replay of this song";

				itemsCamera.follow(topShit.background, null, 0.15);
				itemsCamera.targetOffset.y -= 100 + topTitle.height;

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
			infoText.text += " / BACK to return to Songs";

		if (GameClient.isConnected()) {
			replaysSelect.alpha -= 0.4;
			modifiersSelect.alpha -= 0.4;
		}
	}

	function listenToSong() {
		if (curSelected == -1)
			return;

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
				updateFreeplayMusicPitch();
				instPlaying = curSelected;
				trackPlaying = track;
				listening = true;
				bustSound.onComplete = null;
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

	public function playFreakyMusic(?musName:String = 'freakyMenu', ?bpm:Float = 102) {
		if (trackPlaying == musName)
			return;

		FlxG.sound.playMusic(Paths.music(musName), 0);
		FlxG.sound.music.fadeIn(3, 0, 0.7);
		Conductor.bpm = bpm;
		listening = false;
		instPlaying = -1;
		trackPlaying = musName;
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

	public static function updateFreeplayMusicPitch() {
		for (v in [FlxG.sound.music, vocals, opponentVocals]) {
			if (v == null) continue;
			v.pitch = ClientPrefs.getGameplaySetting('songspeed');
		}
	}

	function changeDiff(change:Int = 0)
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = Difficulty.list.length-1;
		if (curDifficulty >= Difficulty.list.length)
			curDifficulty = 0;

		if (songs[curSelected] == null)
			return;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

		lastDifficultyName = Difficulty.getString(curDifficulty);
		if (Difficulty.list.length > 1) {
			diffSelect.text = '< ' + lastDifficultyName.toUpperCase() + ' >'; 
		}
		else {
			diffSelect.text = lastDifficultyName.toUpperCase();
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

		if (curSelected < -1)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = -1;

		if (curSelected > -1 && trackPlaying == 'freeplayRandom') {
			playFreakyMusic();
			randomMessage = null;
		}
		
		var newColor:Int = curSelected != -1 ? songs[curSelected].color : FlxColor.fromString('#FD719B');
		if (newColor != intendedColor) {
			if (colorTween != null) {
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

		for (i in 0...grpIcons.members.length)
		{
			grpIcons.members[i].alpha = 0.6;
			if (i != instPlaying)
				grpIcons.members[i].scale.set(1, 1);
		}
		
		if (curSelected != -1) {
			if (grpIcons.members[curSelected] != null)
				grpIcons.members[curSelected].alpha = 1;

			for (item in grpSongs.members)
			{
				bullShit++;
				item.alpha = 0.6;

				if (item is Scrollable) {
					if (cast(item, Scrollable).targetY == curSelected)
						item.alpha = 1;
				}
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
		else {
			Mods.loadTopMod();
			playFreakyMusic('freeplayRandom', 145);
		}

		updateSelectSelection();
	}

	inline private function _updateSongLastDifficulty()
	{
		if (songs[curSelected] != null)
			songs[curSelected].lastDifficulty = Difficulty.getString(curDifficulty);
	}

	private function positionHighscore() {
		scoreText.x = FlxG.width - scoreText.width - 6;
		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);
		searchInput.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		searchInput.x -= searchInput.width / 2;
	}

	private function updateGroupTitle() {
		var textValue = '';
		switch (searchGroup) {
			case MOD, HIDDEN, FAV:
				textValue = searchGroupVList[searchGroupValue] ?? '';
			case ALPHABET:
				textValue = searchGroupVList[searchGroupValue].charAt(0).toUpperCase() + '-' + searchGroupVList[searchGroupValue].charAt(1).toUpperCase();
			default:
				groupTitle.visible = false;
				return;
		}

		groupTitle.visible = true;
		if (textValue == '') {
			textValue = 'Default';
		}

		if (groupTitle is Alphabet)
			cast(groupTitle, Alphabet).text = "< " + textValue.substr(0, 30) + " >";
		else if (groupTitle is online.objects.AlphaLikeText)
			cast(groupTitle, online.objects.AlphaLikeText).text = "< " + textValue.substr(0, 30) + " >";
		groupTitle.scaleY = 0.7;
		groupTitle.scaleX = 0.7;
	}

	private function updateScrollable(obj:Scrollable, elapsed:Float = 0.0) {
		obj.x = ((obj.targetY - lerpSelected) * obj.distancePerItem.x) + obj.startPosition.x;
		obj.y = ((obj.targetY - lerpSelected) * 1.3 * obj.distancePerItem.y) + obj.startPosition.y;

		if (selected)
			obj.alpha -= elapsed * 4;
		else
			obj.alpha = FlxMath.bound(obj.alpha + elapsed * 5, 0, 0.6);
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
			if (grpIcons.members[i] != null)
				grpIcons.members[i].visible = grpIcons.members[i].active = false;
		}
		_lastVisibles = [];

		updateScrollable(groupTitle, elapsed);
		updateScrollable(randomText, elapsed);
		if (curSelected == -1)
			randomText.alpha = 1;
		randomIcon.alpha = randomText.alpha;

		var min:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected - _drawDistance)));
		var max:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected + _drawDistance)));
		for (i in min...max)
		{
			if (!(grpSongs.members[i] is Scrollable)) {
				continue;
			}

			var item:Scrollable = cast(grpSongs.members[i], Scrollable);
			item.visible = item.active = true;
			if (!selected)
				item.x = ((item.targetY - lerpSelected) * item.distancePerItem.x) + item.startPosition.x;
			item.y = ((item.targetY - lerpSelected) * 1.3 * item.distancePerItem.y) + item.startPosition.y;

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

			var icon = grpIcons.members[i];
			if (icon != null) {
				icon.visible = icon.active = true;
				icon.alpha = item.alpha;
			}
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
		if (trackPlaying == 'freeplayRandom') {
			randomIcon.scale.set(1.2, 1.2);
			return;
		}

		if (listening && instPlaying > -1 && grpIcons.members[instPlaying] != null)
			grpIcons.members[instPlaying].scale.set(1.2, 1.2);
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

	static var searchGroup:GroupType = NONE;
	static var searchGroupValue:Int = 0;
	static var searchGroupVList:Array<String> = [];
	static var searchString(default, set):String = '';
	static function set_searchString(v) {
		if (FreeplayState.instance.searchInputWait || v.length > 0) {
			FreeplayState.instance.searchInput.alpha = FreeplayState.instance.searchInputWait ? 1.0 : 0.6;
			FreeplayState.instance.searchInput.text = "SEARCH: '" + v + "'";
			return searchString = v;
		}

		FreeplayState.instance.searchInput.alpha = 0.6;
		FreeplayState.instance.searchInput.text = 'PRESS F TO SEARCH';
		return searchString = v;
	}

	function search(?init:Bool = false) {
		grpIcons.clear();
		grpSongs.clear();
		grpHearts.killMembers();
		_lastVisibles = [];
		songs = [];

		if (!init)
			instPlaying = -1;

		if (searchGroupValue < 0)
			searchGroupValue = searchGroupVList.length - 1;
		if (searchGroupValue > searchGroupVList.length - 1)
			searchGroupValue = 0;

		var i:Int = 0;
		for (songID => arr in initSongItems) {
			var song:SongMetadata = initSongs[songID];
			if (song == null)
				continue;
			
			if (searchGroup == MOD && song.folder != searchGroupVList[searchGroupValue]) {
				continue;
			}
			if (searchGroup == ALPHABET &&
				song.songName.charAt(0).toLowerCase() != searchGroupVList[searchGroupValue].charAt(0) && 
				song.songName.charAt(0).toLowerCase() != searchGroupVList[searchGroupValue].charAt(1)
			) {
				continue;
			}

			// dumb asf idk how to shorten this
			// if song is hidden
			if (ClientPrefs.data.hiddenSongs.contains(song.songName + '-' + song.folder)) {
				// the tab is not HIDDEN
				if (!(searchGroup == HIDDEN && searchGroupValue == 0))
					continue;
			}
			else if (searchGroup == HIDDEN && searchGroupValue == 0) {
				continue;
			}

			var isFavorited = ClientPrefs.data.favSongs.contains(song.songName + '-' + song.folder);
			if (searchGroup == FAV) {
				if (isFavorited && searchGroupValue == 1)
					continue;
				if (!isFavorited && searchGroupValue == 0)
					continue;
			}

			if (
				searchString.length < 1 || 
				song.songName.toLowerCase().replace('-', ' ').contains(searchString.toLowerCase()) || 
				song.folder.toLowerCase().replace('-', ' ').contains(searchString.toLowerCase()) ||
				song.songCharacter.toLowerCase().replace('-', ' ').contains(searchString.toLowerCase())
			) {
				arr[0].targetY = i;
				arr[0].snapToPosition();

				arr[0].visible = arr[0].active = arr[0].isMenuItem = false;

				grpSongs.add(arr[0]); // song

				if (arr[1] != null) {
					arr[1].visible = arr[1].active = false;
					grpIcons.add(arr[1]); // icon
				}
				songs.push(song);

				if (isFavorited) {
					grpHearts.recycle(Heart).target = arr[1];
				}

				var diff = Difficulty.getString(curDifficulty);
				var trackSuffix = diff == "Erect" || diff == "Nightmare" ? "-erect" : "";
				var track = song.songName.toLowerCase() + trackSuffix;
				if (track == trackPlaying)
					instPlaying = i;

				i++;
			}
		}

		if (searchGroup == ALPHABET) {
			var opHistory:Array<Int> = [];
			songs.sort(function(x:SongMetadata, y:SongMetadata):Int {
				var a = x.songName.toUpperCase();
				var b = y.songName.toUpperCase();

				if (a < b) {
					opHistory.push(-1);
				}
				else if (a > b) {
					opHistory.push(1);
				}
				else {
					opHistory.push(0);
				}

				return opHistory[opHistory.length - 1];
			});

			var gsi = 0;
			grpSongs.sort(function(o:Int, x:FlxSprite, y:FlxSprite):Int {
				return opHistory[gsi++];
			});

			var gii = 0;
			grpIcons.sort(function(o:Int, x:HealthIcon, y:HealthIcon):Int {
				return opHistory[gii++];
			});

			var fgsi = 0;
			for (_ds in grpSongs) {
				var song:Dynamic = cast _ds;
				song.targetY = fgsi;
				song.snapToPosition();
				fgsi++;
			}
		}

		if (songs.length < 1) {
			curSelected = -1;
			if (searchString.length > 0) {
				searchString = '';
				search(init);
				return;
			}
		}

		if (init) {
			lerpSelected = curSelected;
			return;
		}

		changeSelection();
		updateTexts();
	}
	
	var searchInputWait:Bool = false;
	function onKeyDown(e:KeyboardEvent) {
		if (!searchInputWait) return;

		var key = e.keyCode;

		if (e.charCode == 0) { // non-printable characters crash String.fromCharCode
			return;
		}

		if (key == 46) { //delete
            return;
        }

		if (key == 8) { //bckspc
			searchString = searchString.substring(0, searchString.length - 1);
            return;
        }
		else if (key == 13) { //enter
			search();
			tempDisableInput();
            return;
        }
		else if (key == 27) { //esc
			tempDisableInput();
            return;
        }

		var newText:String = String.fromCharCode(e.charCode);
		if (key == 86 && e.ctrlKey) {
			newText = Clipboard.text;
		}

		if (newText.length > 0) {
			searchString += newText;
		}
    }

	function tempDisableInput() {
		new FlxTimer().start(0.05, (t) -> {
			searchInputWait = false;
			searchString = searchString;
		});
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

enum GroupType {
	NONE;
	ALPHABET;
	MOD;
	MIX;
	HIDDEN;
	FAV;
}

class Explod extends FlxSprite {
	public static var distancePerItem:FlxPoint = new FlxPoint(20, 120);
	var targetY:Float = 0;
	var offsetX:Float = 0;
	var startX:Float = 0;
	var startY:Float = 0;

	public function new() {
		super(-500, -500);

		var graphic = Paths.image('gm_explosion');
		loadGraphic(graphic, true, 67, 67);
		animation.add('boom', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15], 24, false);
		scale.set(2, 2);
		updateHitbox();
		targetY = -5000;
		animation.finishCallback = _ -> {
			kill();
		};
		animation.play('boom');
	}

	public function boom(of:Scrollable, ox:Float) {
		visible = true;
		setPosition(x, y);
		animation.play('boom');

		targetY = of.targetY;
		startX = of.startPosition.x;
		startY = of.startPosition.y;
		offsetX = ox;
	}

	override function update(elapsed:Float) {
		x = ((targetY - FreeplayState.instance.lerpSelected) * distancePerItem.x) + startX + offsetX * 80 - 40;
		y = ((targetY - FreeplayState.instance.lerpSelected) * 1.3 * distancePerItem.y) + startY - 40;

		super.update(elapsed);
	}
}

class Heart extends LockInSprite {
	public function new(?target:FlxSprite) {
		super(target, Paths.image('heart'));
	}
}

class LockInSprite extends FlxSprite {
	public var target(default, set):FlxSprite;

	public function new(target:FlxSprite, ?asset:FlxGraphicAsset) {
		super(0, 0, asset);

		this.target = target;
	}

	override function update(elapsed) {
		super.update(elapsed);

		if (target == null || !target.alive) {
			kill();
			return;
		}

		x = target.x;
		y = target.y;
		alpha = target.alpha;
		scale.x = target.scale.x;
		scale.y = target.scale.y;
		visible = target.active && target.visible;
	}

	function set_target(v:FlxSprite) {
		target = v;
		revive();
		return target;
	}
}