package online.substates;

import backend.Song;
import backend.Section;
import backend.Rating;
import objects.Note;
import objects.NoteSplash;
import objects.StrumNote;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.animation.FlxAnimationController;
import flixel.group.FlxGroup;
import flixel.input.keyboard.FlxKey;
import openfl.events.KeyboardEvent;
import openfl.media.Sound;
import openfl.utils.Assets as OpenFlAssets;
import states.editors.EditorPlayState;
import states.editors.ChartingState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import online.GameClient;
import backend.Difficulty;

class ChartPreviewSubState extends MusicBeatSubstate {
	public static var shouldSwitchToFreeplay:Bool = false;

	var isBF:Bool = true;
	var originalOpponentMode:Bool = false;
	private var chatBox:ChatBox;
	var finishTimer:FlxTimer = null;
	var noteKillOffset:Float = 350;
	var spawnTime:Float = 2000;
	var startingSong:Bool = true;
	var playbackRate:Float = 1;
	var vocals:FlxSound;
	var opponentVocals:FlxSound;
	var inst:FlxSound;
	var notes:FlxTypedGroup<Note>;
	var unspawnNotes:Array<Note> = [];
	var ratingsData:Array<Rating> = Rating.loadDefault();
	var strumLineNotes:FlxTypedGroup<StrumNote>;
	var opponentStrums:FlxTypedGroup<StrumNote>;
	var playerStrums:FlxTypedGroup<StrumNote>;
	var grpNoteSplashes:FlxTypedGroup<NoteSplash>;
	var combo:Int = 0;
	var lastRating:FlxSprite;
	var lastCombo:FlxSprite;
	var lastScore:Array<FlxSprite> = [];
	var keysArray:Array<String> = ['note_left', 'note_down', 'note_up', 'note_right'];
	var songHits:Int = 0;
	var songMisses:Int = 0;
	var songLength:Float = 0;
	var songSpeed:Float = 1;
	var totalPlayed:Int = 0;
	var totalNotesHit:Float = 0.0;
	var ratingPercent:Float;
	var ratingFC:String;
	var songSpeedType:String;
	var showCombo:Bool = false;
	var showComboNum:Bool = true;
	var showRating:Bool = true;
	var startOffset:Float = 0;
	var startPos:Float = 0;
	var timerToStart:Float = 0;
	var scoreTxt:FlxText;
	var dataTxt:FlxText;

	public function new(playbackRate:Float) {
		super();
		this.playbackRate = playbackRate;
		this.startPos = 0;
		
		if (GameClient.isConnected() && GameClient.getPlayerSelf() != null)
			isBF = GameClient.getPlayerSelf().bfSide;
		
		originalOpponentMode = PlayState.opponentMode;
		PlayState.opponentMode = !isBF;
			
		Song.updateManiaKeys(PlayState.SONG);

		Conductor.safeZoneOffset = (ClientPrefs.getSafeFrames() / 60) * 1000 * playbackRate;
		Conductor.songPosition -= startOffset;
		startOffset = Conductor.crochet;
		timerToStart = startOffset;

		if (FlxG.sound.music != null) FlxG.sound.music.stop();

		cachePopUpScore();
		if(ClientPrefs.data.hitsoundVolume > 0) Paths.sound('hitsound');

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.6;
		bg.scrollFactor.set();
		add(bg);

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		add(grpNoteSplashes);
		var splash:NoteSplash = new NoteSplash(100, 100);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.000001;

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();
		generateStaticArrows(0);
		generateStaticArrows(1);

		scoreTxt = new FlxText(10, FlxG.height - 50, FlxG.width - 20, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.data.hideHud;
		add(scoreTxt);

		var tipText:FlxText = new FlxText(10, FlxG.height - 24, 0, 'Press ESC to Exit | Press P to Change Song', 16);
		tipText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		tipText.borderSize = 2;
		tipText.scrollFactor.set();
		add(tipText);
		
		FlxG.mouse.visible = false;
		generateSong(PlayState.SONG.song);
		RecalculateRating();

		if (online.states.RoomState.instance != null && online.states.RoomState.instance.chatBox != null) {
			this.chatBox = online.states.RoomState.instance.chatBox;
			// Remove from RoomState's groupHUD and add to this substate
			if (this.chatBox.group != null) {
				(cast this.chatBox.group:FlxGroup).remove(this.chatBox, false);
			}
			this.add(this.chatBox);
		}
	}

		override function update(elapsed:Float) {
			var wasChatFocused = (this.chatBox != null && this.chatBox.focused);
			super.update(elapsed);
			var isChatFocused = (this.chatBox != null && this.chatBox.focused);
	
			if (isChatFocused) {
				return;
			}
	
			
			if(wasChatFocused && !isChatFocused) {
				return;
			}
	
			
	
			if(controls.BACK || FlxG.keys.justPressed.ESCAPE) {
				endSong();
				return;
			}
	
			if (FlxG.keys.justPressed.P) {
				shouldSwitchToFreeplay = true;
				close();
				return;
			}
	
			if (startingSong) {
				timerToStart -= elapsed * 1000;
				Conductor.songPosition = startPos - timerToStart;
				if(timerToStart < 0) startSong();
			} else {
				Conductor.songPosition += elapsed * 1000 * playbackRate;
			}
	
			if (unspawnNotes[0] != null) {
				var time:Float = spawnTime * playbackRate;
				if(songSpeed < 1) time /= songSpeed;
				if(unspawnNotes[0].multSpeed < 1) time /= unspawnNotes[0].multSpeed;
				while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time) {
					var dunceNote:Note = unspawnNotes[0];
					notes.insert(0, dunceNote);
					dunceNote.spawned = true;
					var index:Int = unspawnNotes.indexOf(dunceNote);
					unspawnNotes.splice(index, 1);
				}
			}
	
			if (!controls.controllerMode) {
				if (controls.NOTE_LEFT_P) keyPressed(0);
				if (controls.NOTE_DOWN_P) keyPressed(1);
				if (controls.NOTE_UP_P) keyPressed(2);
				if (controls.NOTE_RIGHT_P) keyPressed(3);
	
				if (controls.NOTE_LEFT_R) keyReleased(0);
				if (controls.NOTE_DOWN_R) keyReleased(1);
				if (controls.NOTE_UP_R) keyReleased(2);
				if (controls.NOTE_RIGHT_R) keyReleased(3);
			}
	
			if(notes.length > 0) {
				var fakeCrochet:Float = (60 / PlayState.SONG.bpm) * 1000;
				notes.forEachAlive(function(daNote:Note) {
					var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
					if(!daNote.mustPress) strumGroup = opponentStrums;
					var strum:StrumNote = strumGroup.members[daNote.noteData];
					daNote.followStrumNote(strum, fakeCrochet, songSpeed / playbackRate);
					
					if (daNote.mustPress != isBF && daNote.strumTime <= Conductor.songPosition) {
						if (!daNote.wasGoodHit && !daNote.wasGoodHit) opponentNoteHit(daNote);
					}
					
					if(daNote.isSustainNote && strum.sustainReduce) daNote.clipToStrumNote(strum);
					if (Conductor.songPosition - daNote.strumTime > noteKillOffset) {
						if (!daNote.ignoreNote && (daNote.tooLate || !daNote.wasGoodHit)) noteMiss(daNote);
						daNote.active = false;
						daNote.visible = false;
						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
					}
				});
			}
			
			keysCheck();
		}
	var lastStepHit:Int = -1;
	override function stepHit() {
		if (FlxG.sound.music.time >= -ClientPrefs.data.noteOffset) {
			for (v in [vocals, opponentVocals]) {
				if (v == null) continue;
				if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > (200 * playbackRate) || (PlayState.SONG.needsVoices && Math.abs(v.time - (Conductor.songPosition - Conductor.offset)) > (200 * playbackRate))) resyncVocals();
			}
		}
		super.stepHit();
		if(curStep == lastStepHit) return;
		lastStepHit = curStep;
	}

	var lastBeatHit:Int = -1;
	override function beatHit() {
		if(lastBeatHit >= curBeat) return;
		notes.sort(FlxSort.byY, ClientPrefs.data.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		super.beatHit();
		lastBeatHit = curBeat;
	}
	
	override function sectionHit() {
		if (PlayState.SONG.notes[curSection] != null) {
			if (PlayState.SONG.notes[curSection].changeBPM) Conductor.bpm = PlayState.SONG.notes[curSection].bpm;
		}
		super.sectionHit();
	}

	override function destroy() {
		
		if (this.chatBox != null) {
			this.remove(this.chatBox, false);
			if (online.states.RoomState.instance != null && online.states.RoomState.instance.groupHUD != null) {
				online.states.RoomState.instance.groupHUD.add(this.chatBox);
			}
		}

		PlayState.opponentMode = originalOpponentMode;
		FlxG.mouse.visible = true;
		super.destroy();
	}
	
	function startSong():Void {
		startingSong = false;
		@:privateAccess
		FlxG.sound.playMusic(inst._sound, 1, false);
		FlxG.sound.music.time = startPos;
		FlxG.sound.music.pitch = playbackRate;
		FlxG.sound.music.onComplete = finishSong;
		for (v in [vocals, opponentVocals]) {
			if (v == null) continue;
			v.volume = 1;
			v.time = startPos;
			v.play();
		}
		songLength = FlxG.sound.music.length;
	}

		private function getMustPressFromRaw(section:SwagSection, rawNote:Array<Dynamic>):Bool {
			var isPsychRelease:Bool = (PlayState.SONG.format == 'psych_v1' || PlayState.SONG.format == 'psych_v2');
			if(isPsychRelease) return rawNote[1] >= Note.maniaKeys;
	
			var gottaHitNote:Bool = section.mustHitSection;
			if (rawNote[1] >= Note.maniaKeys)
				gottaHitNote = !section.mustHitSection;
			return gottaHitNote;
		}
	
			function generateSong(dataPath:String) {
				var songData = PlayState.SONG;
				Conductor.bpm = songData.bpm;
		
				var diff = Difficulty.getString(PlayState.storyDifficulty);
				var trackSuffix = diff == "Erect" || diff == "Nightmare" ? "-erect" : "";
		
				vocals = new FlxSound();
				if (songData.needsVoices)
				{				var playerVocalPath = Paths.voices(songData.song, 'Player', trackSuffix);
				vocals.loadEmbedded(playerVocalPath != null ? playerVocalPath : Paths.voices(songData.song, null, trackSuffix));
			}
	
			opponentVocals = new FlxSound();
			var oppVocalPath = Paths.voices(songData.song, 'Opponent', trackSuffix);
			if (oppVocalPath != null)
				opponentVocals.loadEmbedded(oppVocalPath);
			
			for (v in [vocals, opponentVocals]) {
				v.volume = 0;
				v.pitch = playbackRate;
				FlxG.sound.list.add(v);
			}
			
			inst = new FlxSound().loadEmbedded(Paths.inst(songData.song, trackSuffix));
			FlxG.sound.list.add(inst);
			FlxG.sound.music.volume = 0;
	
			notes = new FlxTypedGroup<Note>();
			add(notes);
	
			var dataNotes:Array<Array<Dynamic>> = [];
			var dataNotesSection:Array<Int> = [];
			
			var noteData:Array<SwagSection> = songData.notes;
			for (i => section in noteData) {
				for (j => songNotes in section.sectionNotes) {
					dataNotes.push(songNotes);
					dataNotesSection.push(i);
				}
			}
			
			songSpeedType = ClientPrefs.getGameplaySetting('scrolltype');
			switch(songSpeedType) {
				case "multiplicative":
					songSpeed = songData.speed * ClientPrefs.getGameplaySetting('scrollspeed');
				case "constant":
					songSpeed = ClientPrefs.getGameplaySetting('scrollspeed');
			}
	
			for (i => songNotes in dataNotes) {
				var section = noteData[dataNotesSection[i]];
				var daStrumTime:Float = songNotes[0];
				if (daStrumTime > inst.length)
					continue;
	
				var daNoteData:Int = Std.int(songNotes[1] % Note.maniaKeys);
				if (songNotes[1] < 0 || songNotes[1] >= Note.maniaKeys * 2)
					continue;
	
				var gottaHitNote:Bool = getMustPressFromRaw(section, songNotes);
	
							var oldNote:Note;
							if (unspawnNotes.length > 0)
								oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
							else
								oldNote = null;
				
							var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote, false, false, this);
							swagNote.mustPress = gottaHitNote;				swagNote.sustainLength = songNotes[2];
				swagNote.gfNote = (section.gfSection && (songNotes[1] < Note.maniaKeys));
				swagNote.noteType = songNotes[3];
				if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = ChartingState.noteTypeList[songNotes[3]];
	
				swagNote.scrollFactor.set();
	
				var susLength:Float = swagNote.sustainLength;
				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);
	
				var floorSus:Int = Math.floor(susLength);
				if(floorSus > 0) {
									for (susNote in 0...floorSus+1)
									{
										oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
					
										var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote), daNoteData, oldNote, true, false, this);
										sustainNote.mustPress = gottaHitNote;						sustainNote.gfNote = (section.gfSection && (songNotes[1]<Note.maniaKeys));
						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();
						swagNote.tail.push(sustainNote);
						sustainNote.parent = swagNote;
						unspawnNotes.push(sustainNote);
						
						sustainNote.correctionOffset = swagNote.height / 2;
						if(!PlayState.isPixelStage)
						{
							if(oldNote.isSustainNote)
							{
								oldNote.scale.y *= Note.SUSTAIN_SIZE / oldNote.frameHeight;
								oldNote.scale.y /= playbackRate;
								oldNote.updateHitbox();
							}
							if(ClientPrefs.data.downScroll) sustainNote.correctionOffset = 0;
						}
						else if(oldNote.isSustainNote)
						{
							oldNote.scale.y /= playbackRate;
							oldNote.updateHitbox();
						}
	
						if (sustainNote.mustPress) sustainNote.followX += FlxG.width / 2;
						else if(ClientPrefs.data.middleScroll)
						{
							sustainNote.followX += 310;
							if(daNoteData > 1) sustainNote.followX += FlxG.width / 2 + 25;
						}
					}
				}
	
				if (swagNote.mustPress)
				{
					swagNote.followX += FlxG.width / 2;
				}
				else if(ClientPrefs.data.middleScroll)
				{
					swagNote.followX += 310;
					if(daNoteData > 1) swagNote.followX += FlxG.width / 2 + 25;
				}
			}
			unspawnNotes.sort(PlayState.sortByTime);
		}	
	private function generateStaticArrows(player:Int):Void {
		var strumWidth = Note.maniaKeys * Note.swagScaledWidth - (Note.getNoteOffsetX() * (Note.maniaKeys - 1));
		var strumLineX:Float = 0;

		if (ClientPrefs.data.middleScroll) {
			strumLineX = FlxG.width / 2 - strumWidth / 2;
		}
		else {
			strumLineX = (FlxG.width / 2 - strumWidth) / 2;
			strumLineX += FlxG.width / 2 * (player == 0 ? 0 : 1);
		}

		var strumLineY:Float = ClientPrefs.data.downScroll ? (FlxG.height - 150) : 50;
		for (i in 0...Note.maniaKeys) {
			var targetAlpha:Float = 1;
			var isPlayer = (player == (isBF ? 1 : 0));
			
			if (!isPlayer) {
				if(!ClientPrefs.data.opponentStrums) targetAlpha = 0;
				else if(ClientPrefs.data.middleScroll) targetAlpha = 0.35;
			}

			var babyArrow:StrumNote = new StrumNote(strumLineX, strumLineY, i, player);
			babyArrow.downScroll = ClientPrefs.data.downScroll;
			babyArrow.alpha = targetAlpha;

			if (!isPlayer && ClientPrefs.data.middleScroll) {
				babyArrow.x = strumLineX / 2 - strumWidth / 4;
				if (i > Note.maniaKeys / 2 - 1) { // half rest
					babyArrow.x += (strumLineX + strumWidth / 2);
				}
			}

			if (player == 1) playerStrums.add(babyArrow);
			else opponentStrums.add(babyArrow);
			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
		}
	}

	public function finishSong():Void {
		if(ClientPrefs.data.noteOffset <= 0) endSong();
		else {
			finishTimer = new FlxTimer().start(ClientPrefs.data.noteOffset / 1000, function(tmr:FlxTimer) {
				endSong();
			});
		}
	}

	public function endSong() {
		for (v in [vocals, opponentVocals]) {
			if (v == null) continue;
			v.pause();
			v.destroy();
		}
		if(finishTimer != null) {
			finishTimer.cancel();
			finishTimer.destroy();
		}
		close();
	}

	private function cachePopUpScore() {
		for (rating in ratingsData) Paths.image(rating.image);
		for (i in 0...10) Paths.image('num' + i);
	}

	private function popUpScore(note:Note = null):Void {
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.getRatingOffset());
		vocals.volume = 1;
		var placement:String = Std.string(combo);
		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.35;

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;
		var daRating:Rating = Conductor.judgeNote(ratingsData, noteDiff / playbackRate);

		totalNotesHit += daRating.ratingMod;
		note.ratingMod = daRating.ratingMod;
		if(!note.ratingDisabled) daRating.hits++;
		note.rating = daRating.name;
		score = daRating.score;

		if(daRating.noteSplash && !note.noteSplashData.disabled) spawnNoteSplashOnNote(note);

		if(!note.ratingDisabled) {
			songHits++;
			totalPlayed++;
			RecalculateRating(false);
		}

		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';

		rating.loadGraphic(Paths.image(pixelShitPart1 + daRating.image + pixelShitPart2));
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550 * playbackRate * playbackRate;
		rating.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
		rating.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
		rating.visible = (!ClientPrefs.data.hideHud && showRating);
		rating.x += ClientPrefs.data.comboOffset[0];
		rating.y -= ClientPrefs.data.comboOffset[1];

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2));
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
		comboSpr.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
		comboSpr.visible = (!ClientPrefs.data.hideHud && showCombo);
		comboSpr.x += ClientPrefs.data.comboOffset[0];
		comboSpr.y -= ClientPrefs.data.comboOffset[1];
		comboSpr.y += 60;
		comboSpr.velocity.x += FlxG.random.int(1, 10) * playbackRate;

		insert(members.indexOf(strumLineNotes), rating);
		if (!ClientPrefs.data.comboStacking) {
			if (lastRating != null) lastRating.kill();
			lastRating = rating;
		}

		rating.setGraphicSize(Std.int(rating.width * 0.7));
		rating.updateHitbox();
		comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
		comboSpr.updateHitbox();

		var seperatedScore:Array<Int> = [];
		if(combo >= 1000) seperatedScore.push(Math.floor(combo / 1000) % 10);
		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		var xThing:Float = 0;
		if (showCombo) insert(members.indexOf(strumLineNotes), comboSpr);
		if (!ClientPrefs.data.comboStacking) {
			if (lastCombo != null) lastCombo.kill();
			lastCombo = comboSpr;
		}
		if (lastScore != null) {
			while (lastScore.length > 0) {
				lastScore[0].kill();
				lastScore.remove(lastScore[0]);
			}
		}
		for (i in seperatedScore) {
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2));
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90 + ClientPrefs.data.comboOffset[2];
			numScore.y += 80 - ClientPrefs.data.comboOffset[3];
			
			if (!ClientPrefs.data.comboStacking) lastScore.push(numScore);

			numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			numScore.updateHitbox();
			numScore.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
			numScore.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
			numScore.velocity.x = FlxG.random.float(-5, 5) * playbackRate;
			numScore.visible = !ClientPrefs.data.hideHud;
			if(showComboNum) insert(members.indexOf(strumLineNotes), numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2 / playbackRate, {
				onComplete: function(tween:FlxTween) { numScore.destroy(); },
				startDelay: Conductor.crochet * 0.002 / playbackRate
			});

			daLoop++;
			if(numScore.x > xThing) xThing = numScore.x;
		}
		comboSpr.x = xThing + 50;
		coolText.text = Std.string(seperatedScore);
		FlxTween.tween(rating, {alpha: 0}, 0.2 / playbackRate, { startDelay: Conductor.crochet * 0.001 / playbackRate });
		FlxTween.tween(comboSpr, {alpha: 0}, 0.2 / playbackRate, {
			onComplete: function(tween:FlxTween) {
				coolText.destroy();
				comboSpr.destroy();
				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.002 / playbackRate
		});
	}

	private function keyPressed(key:Int) {
		if (key > -1 && notes.length > 0) {
			var lastTime:Float = Conductor.songPosition;
			if(Conductor.songPosition >= 0) Conductor.songPosition = FlxG.sound.music.time;
			var pressNotes:Array<Note> = [];
			var notesStopped:Bool = false;
			var sortedNotesList:Array<Note> = [];
			notes.forEachAlive(function(daNote:Note) {
				if (daNote.canBeHit && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote && !daNote.blockHit && daNote.mustPress == isBF) {
					if(daNote.noteData == key) sortedNotesList.push(daNote);
				}
			});

			if (sortedNotesList.length > 0) {
				sortedNotesList.sort(PlayState.sortHitNotes);
				for (epicNote in sortedNotesList) {
					for (doubleNote in pressNotes) {
						if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1) {
							doubleNote.kill();
							notes.remove(doubleNote, true);
							doubleNote.destroy();
						} else notesStopped = true;
					}
					if (!notesStopped) {
						goodNoteHit(epicNote);
						pressNotes.push(epicNote);
					}
				}
			}
			Conductor.songPosition = lastTime;
		}

		var spr:StrumNote = (isBF ? playerStrums : opponentStrums).members[key];
		if(spr != null && spr.animation.curAnim.name != 'confirm') {
			spr.playAnim('pressed');
			spr.resetAnim = 0;
		}
	}

	private function keyReleased(key:Int) {
		var spr:StrumNote = (isBF ? playerStrums : opponentStrums).members[key];
		if(spr != null) {
			spr.playAnim('static');
			spr.resetAnim = 0;
		}
	}
	
	private function keysCheck():Void {
		var holdArray:Array<Bool> = [];
		var pressArray:Array<Bool> = [];
		var releaseArray:Array<Bool> = [];
		for (key in keysArray) {
			holdArray.push(controls.pressed(key));
			pressArray.push(controls.justPressed(key));
			releaseArray.push(controls.justReleased(key));
		}

		if(controls.controllerMode && pressArray.contains(true)) {
			for (i in 0...pressArray.length) if(pressArray[i]) keyPressed(i);
		}

			notes.forEachAlive(function(daNote:Note)

				{

					if (daNote.isSustainNote && daNote.mustPress == isBF && holdArray[daNote.noteData] && daNote.canBeHit && !daNote.tooLate && !daNote.wasGoodHit && !daNote.blockHit)

						goodNoteHit(daNote);

				});

		if(controls.controllerMode && releaseArray.contains(true)) {
			for (i in 0...releaseArray.length) if(releaseArray[i]) keyReleased(i);
		}
	}
	
	function opponentNoteHit(note:Note):Void {
		if (PlayState.SONG.needsVoices) vocals.volume = 1;
		note.wasGoodHit = true;

		var strum:StrumNote = (note.mustPress ? playerStrums : opponentStrums).members[Std.int(Math.abs(note.noteData))];
		if(strum != null) {
			strum.playAnim('confirm', true);
			strum.resetAnim = Conductor.stepCrochet * 1.25 / 1000 / playbackRate;
		}
		note.hitByOpponent = true;
		if (!note.isSustainNote) {
			note.kill();
			notes.remove(note, true);
			note.destroy();
		}
	}

	function goodNoteHit(note:Note):Void {
		if (!note.wasGoodHit) {
			note.wasGoodHit = true;
			if (ClientPrefs.data.hitsoundVolume > 0 && !note.hitsoundDisabled) FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.data.hitsoundVolume);

			if(note.hitCausesMiss) {
				noteMiss(note);
				if(!note.noteSplashData.disabled && !note.isSustainNote) spawnNoteSplashOnNote(note);
				if (!note.isSustainNote) {
					note.kill();
					notes.remove(note, true);
					note.destroy();
				}
				return;
			}

			if (!note.isSustainNote) {
				combo++;
				if(combo > 9999) combo = 9999;
				popUpScore(note);
			}

			var spr:StrumNote = (note.mustPress ? playerStrums : opponentStrums).members[note.noteData];
			if(spr != null) spr.playAnim('confirm', true);
			vocals.volume = 1;

			if (!note.isSustainNote) {
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}
	
	function noteMiss(daNote:Note):Void {
		notes.forEachAlive(function(note:Note) {
			if (daNote != note && note.mustPress == daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1) {
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		});
		songMisses++;
		totalPlayed++;
		RecalculateRating(true);
		vocals.volume = 0;
		combo = 0;
	}

	function spawnNoteSplashOnNote(note:Note):Void {
		if(note != null) {
			var strum:StrumNote = (note.mustPress ? playerStrums : opponentStrums).members[note.noteData];
			if(strum != null) spawnNoteSplash(strum.x, strum.y, note.noteData, note);
		}
	}

	function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null) {
		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, note);
		grpNoteSplashes.add(splash);
	}
	
	function resyncVocals():Void {
		if(finishTimer != null) return;
		FlxG.sound.music.play();
		FlxG.sound.music.pitch = playbackRate;
		Conductor.songPosition = FlxG.sound.music.time;
		for (v in [vocals, opponentVocals]) {
			if (v == null) continue;
			v.pause();
			if (Conductor.songPosition <= v.length) {
				v.time = Conductor.songPosition;
				v.pitch = playbackRate;
			}
			v.play();
		}
	}

	function RecalculateRating(badHit:Bool = false) {
		if(totalPlayed != 0) ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
		fullComboUpdate();
		updateScore(badHit);
	}

	function updateScore(miss:Bool = false) {
		var str:String = '?';
		if(totalPlayed != 0) {
			var percent:Float = CoolUtil.floorDecimal(ratingPercent * 100, 2);
			str = '$percent% - $ratingFC';
		}
		scoreTxt.text = 'Hits: $songHits | Misses: $songMisses | Rating: $str';
	}
	
	function fullComboUpdate() {
		var sicks:Int = ratingsData[0].hits;
		var goods:Int = ratingsData[1].hits;
		var bads:Int = ratingsData[2].hits;
		var shits:Int = ratingsData[3].hits;
		ratingFC = 'Clear';
		if(songMisses < 1) {
			if (shits > 0) ratingFC = 'NM';
			else if (bads > 0) ratingFC = 'FC';
			else if (goods > 0) ratingFC = 'GFC';
			else if (sicks > 0) ratingFC = 'SFC';
		}
		else if (songMisses < 10) ratingFC = 'SDCB';
	}
}
