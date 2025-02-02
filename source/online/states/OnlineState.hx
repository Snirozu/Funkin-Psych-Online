package online.states;

import backend.WeekData;
import backend.Highscore;
import backend.Song;
import haxe.io.Path;
import shaders.WarpShader;
import online.network.FunkinNetwork;
import states.FreeplayState;
import lime.system.Clipboard;
import haxe.Json;
import states.MainMenuState;
import openfl.events.KeyboardEvent;
import flixel.addons.text.FlxTextField;

@:build(lumod.LuaScriptClass.build())
class OnlineState extends MusicBeatState {
	var items:FlxTypedSpriteGroup<FlxText>;

	var itms:Array<String> = [
        "JOIN",
        "HOST",
        "FIND",
		"OPTIONS",
		"LEADERBOARD",
		"MOD DOWNLOADER"
    ];

	// var networkPlayer:FlxText;
	// var networkBg:FlxSprite;
	var itemDesc:FlxText;
	var playersOnline:FlxText;

	public static var twitterIsDead:Bool = false;
	static var curSelected = 0;

	var inputWait = false;
	var inputString(get, set):String;
	function get_inputString():String {
		switch (curSelected) {
			case 0:
				return daCoomCode;
		}
		return null;
	}
	function set_inputString(v) {
		switch (curSelected) {
			case 0:
				return daCoomCode = v;
		}
		return null;
	}

	var daCoomCode:String = "";
	var disableInput = false;

	var selectLine:FlxSprite;
	var descBox:FlxSprite;
	
	var discord:FlxSprite;
	var github:FlxSprite;
	var bsky:FlxSprite;
	var twitter:FlxSprite;

    function onRoomJoin(err:Dynamic) {
		if (err != null) {
			disableInput = false;
			return;
		}

		Waiter.put(() -> {
			FlxG.switchState(() -> new RoomState());
		});
    }

	function getItemName(item:String) {
		if (curSelected == 0 && item == "JOIN" && inputWait)
		{
			return "JOIN CODE: " + inputString;
		}
		return item;
	}

    override function create() {
        super.create();

		if (FlxG.sound.music == null || !FlxG.sound.music.playing)
			FlxG.sound.playMusic(Paths.music('freakyMenu'));

		OnlineMods.checkMods();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Menus", "Online Menu");
		#end

        var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xff2b2b2b;
        bg.updateHitbox();
        bg.screenCenter();
        bg.antialiasing = ClientPrefs.data.antialiasing;
        add(bg);
		
		var warp:FlxSprite = new FlxSprite();
		warp.makeGraphic(FlxG.width, FlxG.height, FlxColor.TRANSPARENT);
		warp.updateHitbox();
		warp.screenCenter();
		add(new WarpEffect(warp));
		warp.antialiasing = ClientPrefs.data.antialiasing;
		add(warp);

		var lines:FlxSprite = new FlxSprite().loadGraphic(Paths.image('coolLines'));
		lines.updateHitbox();
		lines.screenCenter();
		lines.antialiasing = ClientPrefs.data.antialiasing;
		add(lines);

		selectLine = new FlxSprite();
		selectLine.makeGraphic(1, 1, FlxColor.BLACK);
		selectLine.alpha = 0.3;
		add(selectLine);

		descBox = new FlxSprite(0, FlxG.height - 125);
		descBox.makeGraphic(1, 1, FlxColor.BLACK);
		descBox.alpha = 0.4;
		add(descBox);

        items = new FlxTypedSpriteGroup<FlxText>();
		var prevText:FlxText = null;
        var i = 0;
        for (itm in itms) {
			var text = new FlxText(0, 0, 0, getItemName(itm));
			if (prevText != null) {
				text.y += prevText.height * i;
			}
            text.ID = i;
			text.setFormat("VCR OSD Mono", 40, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			text.alpha = inputWait ? 0.5 : 0.8;
			if (text.ID == curSelected) {
				text.text = "> " + text.text + " <";
				text.alpha = 1;
			}
			items.add(prevText = text);
			i++;
        }
		items.screenCenter(Y);
        add(items);

		discord = new FlxSprite();
		discord.antialiasing = ClientPrefs.data.antialiasing;
		discord.frames = Paths.getSparrowAtlas('online_discord');
		discord.animation.addByPrefix('idle', "idle", 24);
		discord.animation.addByPrefix('active', "active", 24);
		discord.animation.play('idle');
		//discord.scale.set(0.5, 0.5);
		discord.updateHitbox();
		discord.x = 30;
		discord.y = FlxG.height - discord.height - 30;
		discord.alpha = 0.8;
		add(discord);

		github = new FlxSprite();
		github.antialiasing = ClientPrefs.data.antialiasing;
		github.frames = Paths.getSparrowAtlas('online_github');
		github.animation.addByPrefix('idle', "idle", 24);
		github.animation.addByPrefix('active', "active", 24);
		github.animation.play('idle');
		// github.scale.set(0.5, 0.5);
		github.updateHitbox();
		github.x = discord.x + discord.width + 20;
		github.y = FlxG.height - github.height - 28;
		github.alpha = 0.8;
		add(github);

		if (twitterIsDead) {
			bsky = new FlxSprite();
			bsky.antialiasing = ClientPrefs.data.antialiasing;
			bsky.frames = Paths.getSparrowAtlas('online_bsky');
			bsky.animation.addByPrefix('idle', "idle", 24);
			bsky.animation.addByPrefix('active', "active", 24);
			bsky.animation.play('idle');
			bsky.updateHitbox();
			bsky.x = github.x + github.width + 20;
			bsky.y = FlxG.height - bsky.height - 28;
			bsky.alpha = 0.8;
			add(bsky);
		}
		else {
			twitter = new FlxSprite();
			twitter.antialiasing = ClientPrefs.data.antialiasing;
			twitter.frames = Paths.getSparrowAtlas('online_twitter');
			twitter.animation.addByPrefix('idle', "idle", 24);
			twitter.animation.addByPrefix('active', "active", 24);
			twitter.animation.play('idle');
			twitter.updateHitbox();
			twitter.x = github.x + github.width + 20;
			twitter.y = FlxG.height - twitter.height - 28;
			twitter.alpha = 0.8;
			add(twitter);
		}
		

		itemDesc = new FlxText(0, FlxG.height - 170);
		itemDesc.setFormat("VCR OSD Mono", 25, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		itemDesc.screenCenter(X);
		add(itemDesc);

		playersOnline = new FlxText(0, 100);
		playersOnline.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		playersOnline.alpha = 0.7;
		playersOnline.text = "Fetching...";
		playersOnline.screenCenter(X);
		add(playersOnline);

		var availableRooms = new FlxText(0, 130);
		availableRooms.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		availableRooms.alpha = 0.6;
		availableRooms.screenCenter(X);
		add(availableRooms);

		// networkBg = new FlxSprite(20, 20);
		// networkBg.makeGraphic(1, 1, FlxColor.BLACK);
		// networkBg.alpha = 0.6;
		// add(networkBg);

		// networkPlayer = new FlxText(30, 30);
		// networkPlayer.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		// networkPlayer.alpha = 0.5;
		// networkPlayer.text = FunkinNetwork.loggedIn ? "Logged in as " + FunkinNetwork.nickname : "Not logged in";
		// if (FunkinNetwork.loggedIn) {
		// 	networkPlayer.text += "\nPoints:" + FunkinNetwork.points;
		// }
		// add(networkPlayer);

		// networkBg.scale.set(networkPlayer.width + 20, networkPlayer.height + 20);
		// networkBg.updateHitbox();

		// // slide to the right
		// networkBg.x = FlxG.width - networkBg.width - 20;
		// networkPlayer.x = networkBg.x + 10;

		var frontMessage = new FlxText(0, 0, 500);
		frontMessage.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		frontMessage.alpha = 0.5;
		frontMessage.x = FlxG.width - frontMessage.fieldWidth - 50;
		add(frontMessage);

		FunkinNetwork.ping();
		var profileBox = new ProfileBox(FunkinNetwork.nickname, true);
		profileBox.setPosition(FlxG.width - profileBox.width - 20, 20);
		add(profileBox);
		
		changeSelection(0);

		Thread.run(() -> {
			var data = FunkinNetwork.fetchFront();
			Waiter.put(() -> {
				if (data == null) {
					playersOnline.text = "NETWORK OFFLINE";
					profileBox.visible = false;
					// networkPlayer.visible = false;
					// networkBg.visible = false;
				}
				else {
					playersOnline.text = 'Players Online: ' + data.online;
					availableRooms.text = 'Available Rooms: ' + data.rooms;
					frontMessage.text = data.sez;
					frontMessage.y = FlxG.height - frontMessage.height - 20;
				}

				playersOnline.screenCenter(X);
				availableRooms.screenCenter(X);
			});
		});

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);

		FlxG.mouse.visible = true;
    }

	override function destroy() {
		super.destroy();

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
	}

    override function update(elapsed) {
        super.update(elapsed);

        if (disableInput) return;

		for (item in items) {
			item.text = getItemName(itms[item.ID]);
			item.alpha = inputWait ? 0.5 : 0.8;
			if (item.ID == curSelected) {
				item.text = "> " + item.text + " <";
				item.alpha = 1;
			}
			item.screenCenter(X);
		}

		var mouseInItems = FlxG.mouse.y > items.y && FlxG.mouse.y < items.y + items.members.length * 40;

		if (FlxG.mouse.justPressed && inputWait) {
			if (!FlxG.mouse.overlaps(items.members[curSelected])) {
				inputWait = false;
				return;
			}
			enterInput();
			return;
		}

		if (FlxG.mouse.justPressedRight && inputWait && Clipboard.text != null) {
			inputString += Clipboard.text;
		}

		if (FlxG.mouse.justMoved && !inputWait && mouseInItems) {
			curSelected = Std.int((FlxG.mouse.y - (items.y)) / 40);
			changeSelection(0);
		}

		if (!inputWait) {
			if (controls.UI_UP_P)
				changeSelection(-1);
			else if (controls.UI_DOWN_P)
				changeSelection(1);

			if (controls.ACCEPT || (FlxG.mouse.justPressed && mouseInItems)) {
				switch (itms[curSelected].toLowerCase()) {
					case "join":
						inputWait = true;
					case "find":
						disableInput = true;
						// FlxG.openURL(GameClient.serverAddress + "/rooms");
						FlxG.switchState(() -> new FindRoomState());
					case "host":
						var count:Float = 0;
						for (mod in Mods.getModDirectories()) {
							var url = OnlineMods.getModURL(mod);
							if (url == null || !(url.startsWith('https://') || url.startsWith('http://')))
								count++;
						}

						if (count > 0) {
							Alert.alert('WARNING', count + ' of your mods do not have a valid URL set!');
						}

						disableInput = true;
						GameClient.createRoom(GameClient.serverAddress, onRoomJoin);
					case "options":
						disableInput = true;
						FlxG.switchState(() -> new OnlineOptionsState());
					case "leaderboard":
						openSubState(new TopPlayerSubstate());
					case "mod downloader":
						disableInput = true;
						FlxG.switchState(() -> new DownloaderState());
				}
			}

			if (controls.BACK) {
				disableInput = true;

				FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
				FlxG.mouse.visible = false;

				FlxG.sound.play(Paths.sound('cancelMenu'));
				FlxG.switchState(() -> new MainMenuState());
			}
			
			if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.V) {
				disableInput = true;
				GameClient.joinRoom(Clipboard.text, onRoomJoin);
			}

			if (FlxG.mouse.justPressed || FlxG.mouse.justMoved) {
				if (FlxG.mouse.overlaps(discord)) {
					discord.alpha = 1;
					discord.animation.play("active");
					discord.offset.set(2, 2);

					itemDesc.text = "Join Psych Online Discord Server!";
					itemDesc.screenCenter(X);

					if (FlxG.mouse.justPressed) {
						RequestSubstate.requestURL("https://discord.gg/juHypjWuNc", true);
					}
				}
				else {
					discord.alpha = 0.8;
					discord.animation.play("idle");
					discord.offset.set(0, 0);
				}

				if (FlxG.mouse.overlaps(github)) {
					github.alpha = 1;
					github.animation.play("active");

					itemDesc.text = "Documentation, FAQ and the Source Code!";
					itemDesc.screenCenter(X);

					if (FlxG.mouse.justPressed) {
						RequestSubstate.requestURL("https://github.com/Snirozu/Funkin-Psych-Online/wiki", true);
					}
				}
				else {
					github.alpha = 0.8;
					github.animation.play("idle");
				}

				if (twitterIsDead) {
					if (FlxG.mouse.overlaps(bsky)) {
						bsky.alpha = 1;
						bsky.animation.play("active");

						itemDesc.text = "Follow the official Psych Online Bluesky account!";
						itemDesc.screenCenter(X);

						if (FlxG.mouse.justPressed) {
							RequestSubstate.requestURL("https://bsky.app/profile/funkin.sniro.boo", true);
						}
					}
					else {
						bsky.alpha = 0.8;
						bsky.animation.play("idle");
					}
				}
				else {
					if (FlxG.mouse.overlaps(twitter)) {
						twitter.alpha = 1;
						twitter.animation.play("active");
						twitter.offset.set(5, 5);

						itemDesc.text = "Follow the official Psych Online Twitter account!";
						itemDesc.screenCenter(X);

						if (FlxG.mouse.justPressed) {
							RequestSubstate.requestURL("https://twitter.com/PsychOnlineFNF", true);
						}
					}
					else {
						twitter.alpha = 0.8;
						twitter.animation.play("idle");
						twitter.offset.set(0, 0);
					}
				}
			}
		}
    }
	
	function changeSelection(diffe:Int) {
		curSelected += diffe;

		if (curSelected >= items.length) {
			curSelected = 0;
		}
		else if (curSelected < 0) {
			curSelected = items.length - 1;
		}

		switch (curSelected) {
			case 0:
				itemDesc.text = "Join a room using a room code";
			case 1:
				itemDesc.text = "Creates a room";
			case 2:
				itemDesc.text = "Opens a list of all available public rooms";
			case 3:
				itemDesc.text = "Psych Online options, configure stuff here!";
			case 4:
				itemDesc.text = "The Funkin Points Leaderboard!";
			case 5:
				itemDesc.text = "Download mods from Gamebanana here!";
		}
		itemDesc.screenCenter(X);

		descBox.scale.set(FlxG.width - 500, (itemDesc.text.split("\n").length + 2) * (itemDesc.size));
		descBox.y = itemDesc.y + descBox.scale.y * 0.5 - itemDesc.size;
		descBox.screenCenter(X);
		
		selectLine.y = (items.y + 20) + (curSelected) * 40;
		selectLine.scale.set(FlxG.width, 40);
		selectLine.screenCenter(X);

		for (item in items) {
			item.text = getItemName(itms[item.ID]);
			item.alpha = inputWait ? 0.5 : 0.8;
			if (item.ID == curSelected) {
				item.text = "> " + item.text + " <";
				item.alpha = 1;
			}
			item.screenCenter(X);
		}
	}

    // some code from FlxInputText
	function onKeyDown(e:KeyboardEvent) {
		if (!inputWait) return;

		var key = e.keyCode;

		if (e.charCode == 0) { // non-printable characters crash String.fromCharCode
			return;
		}

		if (key == 46) { //delete
            return;
        }

		if (key == 8) { //bckspc
			inputString = inputString.substring(0, inputString.length - 1);
            return;
        }
		else if (key == 13) { //enter
			enterInput();
            return;
        }
		else if (key == 27) { //esc
			inputWait = false;
			tempDisableInput();
            return;
        }

		var newText:String = String.fromCharCode(e.charCode);
		if ((curSelected == 0 && !e.shiftKey) || (curSelected != 0 && e.shiftKey)) {
			newText = newText.toUpperCase();
        }
        else {
			newText = newText.toLowerCase();
        }

		if (key == 86 && e.ctrlKey) {
			newText = Clipboard.text;
		}

		if (newText.length > 0) {
			inputString += newText;
		}
    }

	function enterInput() {
		inputWait = false;

		if (inputString.length >= 0) {
			switch (itms[curSelected].toLowerCase()) {
				case "join":
					disableInput = true;
					if (daCoomCode.toLowerCase() == "adachi") {
						var image = new FlxSprite().loadGraphic(Paths.image('unnamed_file_from_google'));
						image.setGraphicSize(FlxG.width, FlxG.height);
						image.updateHitbox();
						add(image);
						FreeplayState.destroyFreeplayVocals();
						FlxG.sound.playMusic(Paths.sound('cabbage'));
						return;
					}
					#if VIDEOS_ALLOWED
					else if (daCoomCode.toLowerCase() == "reddit") {
						FreeplayState.destroyFreeplayVocals();
						FlxG.sound.music.stop();

						var ass = new FlxSprite();
						ass.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
						add(ass);
						
						
						var video = new hxcodec.flixel.FlxVideo();
						video.play(Paths.video('enables'));
						video.onEndReached.add(function() {
							video.dispose();

							PlayState.redditMod = true;
							online.mods.OnlineMods.installMod(Path.join([Sys.getCwd(), "/assets/images/reddit.zip"]));

							WeekData.reloadWeekFiles(false);
							Mods.currentModDirectory = "reddit";
							Difficulty.list = ['Normal'];
							PlayState.storyDifficulty = 0;

							var songLowercase:String = Paths.formatToSongPath("Gold");
							PlayState.SONG = Song.loadFromJson(Highscore.formatSong(songLowercase, PlayState.storyDifficulty), songLowercase);
							PlayState.isStoryMode = false;

							LoadingState.loadAndSwitchState(new PlayState());

							#if (MODS_ALLOWED && DISCORD_ALLOWED)
							DiscordClient.loadModRPC();
							#end
						}, true);
						return;
					}
					#end
					GameClient.joinRoom(daCoomCode, onRoomJoin);
			}
		}

		tempDisableInput();
	}

    function tempDisableInput() {
		disableInput = true;
        new FlxTimer().start(0.1, (t) -> disableInput = false);
    }
}