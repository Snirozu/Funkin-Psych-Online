package states;

import online.states.OnlineState;
import backend.WeekData;
import backend.Achievements;

import flixel.FlxObject;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;

import flixel.input.keyboard.FlxKey;
import lime.app.Application;

import objects.AchievementPopup;
import states.editors.MasterEditorMenu;
import options.OptionsState;

#if lumod
@:build(lumod.LuaScriptClass.build())
#end
class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.7.1h'; // This is also used for Discord RPC
	public static var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;
	private var camGame:FlxCamera;
	private var camAchievement:FlxCamera;
	
	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		'online',
		#if MODS_ALLOWED 'mods', #end
		#if ACHIEVEMENTS_ALLOWED 'awards', #end
		'credits',
		'options'
	];

	var magenta:FlxSprite;
	var camFollow:FlxObject;
	var updatEBg:FlxSprite;

	public function new() {
		super();
	}

	override function create()
	{
		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		camGame = new FlxCamera();
		camAchievement = new FlxCamera();
		camAchievement.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camAchievement, false);
		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);
		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.antialiasing = ClientPrefs.data.antialiasing;
		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.color = 0xFFfd719b;
		add(magenta);
		
		// magenta.scrollFactor.set();

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		var scale:Float = 1;
		/*if(optionShit.length > 6) {
			scale = 6 / optionShit.length;
		}*/

		for (i in 0...optionShit.length)
		{
			var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
			var menuItem:FlxSprite = new FlxSprite(0, (i * 140)  + offset);
			menuItem.antialiasing = ClientPrefs.data.antialiasing;
			menuItem.scale.x = scale;
			menuItem.scale.y = scale;
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + optionShit[i]);
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItem.screenCenter(X);
			menuItems.add(menuItem);
			var scr:Float = (optionShit.length - 4) * 0.135;
			if(optionShit.length < 6) scr = 0;
			menuItem.scrollFactor.set(0, scr);
			//menuItem.setGraphicSize(Std.int(menuItem.width * 0.58));
			menuItem.updateHitbox();
		}

		FlxG.camera.follow(camFollow, null, 0.15);

		var versionShit:FlxText = new FlxText(12, FlxG.height - 64, 0, "Psych Online v" + Main.PSYCH_ONLINE_VERSION, 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);
		var versionShit:FlxText = new FlxText(12, FlxG.height - 44, 0, !Main.UNOFFICIAL_BUILD ? "(OFFICIAL BUILD)" : "(NOT AN OFFICIAL BUILD)", 12);
		if (Main.UNOFFICIAL_BUILD)
			versionShit.color = FlxColor.RED;
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);
		var versionShit:FlxText = new FlxText(12, FlxG.height - 24, 0, "Psych Engine v" + psychEngineVersion + "*", 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);

		if (Main.wankyUpdate != null) {
			FlxG.mouse.visible = true;

			var updatE:FlxText = new FlxText(12, FlxG.height - 64, 0, Main.wankyUpdate, 12);
			updatE.scrollFactor.set();
			updatE.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			updatE.setPosition(FlxG.width - updatE.width - 40, 40);

			updatEBg = new FlxSprite();
			updatEBg.scrollFactor.set();
			updatEBg.makeGraphic(Std.int(updatE.width) + 40, Std.int(updatE.height) + 40, FlxColor.BLACK);
			updatEBg.alpha = 0.5;
			updatEBg.setPosition(updatE.x - 20, updatE.y - 20);
			add(updatEBg);
			add(updatE);
		}

		// NG.core.calls.event.logEvent('swag').send();

		changeItem();

		var leDate = Date.now();

		#if ACHIEVEMENTS_ALLOWED
		// Unlocks "Freaky on a Friday Night" achievement if it's a Friday and between 18:00 PM and 23:59 PM
		if (leDate.getDay() == 5 && leDate.getHours() >= 18)
			Achievements.unlock('friday_night_play');

		#if MODS_ALLOWED
		Achievements.reloadList();
		#end
		#end

		if (leDate.getMonth() == 9) {
			online.backend.DateEvent.isHalloween = true;
		}

		super.create();
	}

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * elapsed;

			for (v in [FreeplayState.vocals, FreeplayState.opponentVocals]) {
				if (v == null) continue;
				v.volume += 0.5 * elapsed;
			}
		}
		//FlxG.camera.followLerp = FlxMath.bound(elapsed * 9 / (FlxG.updateFramerate / 60), 0, 1);

		if (!selectedSomethin)
		{
			if (controls.UI_UP_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
			}

			if (controls.UI_DOWN_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
			}

			if (FlxG.mouse.deltaScreenY != 0) {
				menuItems.forEach(function(spr:FlxSprite) {
					if (FlxG.mouse.overlaps(spr, spr.camera) && spr.ID - curSelected != 0) {
						changeItem(spr.ID - curSelected);
						FlxG.sound.play(Paths.sound('scrollMenu'));
					}
				});
			}

			if (FlxG.mouse.wheel != 0) {
				changeItem(-FlxG.mouse.wheel);
			}

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				FlxG.switchState(() -> new TitleState());
			}

			if (controls.ACCEPT || FlxG.mouse.justPressed)
			{
				if (optionShit[curSelected] == 'donate')
				{
					CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
				}
				else
				{
					selectedSomethin = true;
					FlxG.sound.play(Paths.sound('confirmMenu'));

					if(ClientPrefs.data.flashing) FlxFlicker.flicker(magenta, 0.5, 0.15, false);

					menuItems.forEach(function(spr:FlxSprite)
					{
						if (curSelected != spr.ID)
						{
							FlxTween.tween(spr, {alpha: 0}, 0.2, {
								ease: FlxEase.quadOut,
								onComplete: function(twn:FlxTween)
								{
									spr.kill();
								}
							});
						}
						else
						{
							FlxFlicker.flicker(spr, 0.5, 0.06, false, false, function(flick:FlxFlicker)
							{
								var daChoice:String = optionShit[curSelected];

								switch (daChoice)
								{
									case 'story_mode':
										FlxG.switchState(() -> new StoryMenuState());
									case 'freeplay':
										FlxG.switchState(() -> new FreeplayState());
									#if MODS_ALLOWED
									case 'mods':
										FlxG.switchState(() -> new ModsMenuState());
									#end
									case 'awards':
										FlxG.switchState(() -> new AchievementsMenuState());
									case 'credits':
										FlxG.switchState(() -> new CreditsState());
									case 'options':
										LoadingState.loadAndSwitchState(new OptionsState());
										OptionsState.onPlayState = false;
										OptionsState.onOnlineRoom = false;
										if (PlayState.SONG != null)
										{
											PlayState.SONG.arrowSkin = null;
											PlayState.SONG.splashSkin = null;
										}
									case 'online':
										FlxG.switchState(() -> new OnlineState());
								}
							});
						}
					});
				}
			}
			#if desktop
			else if (controls.justPressed('debug_1'))
			{
				selectedSomethin = true;
				FlxG.switchState(() -> new MasterEditorMenu());
			}
			#end

			if (FlxG.mouse.justPressed && updatEBg != null && FlxG.mouse.overlaps(updatEBg)) {
				if (TitleState.mustUpdate)
					online.substates.RequestSubstate.requestURL(Main.latestRelease.html_url, true);
				else
					online.substates.RequestSubstate.requestURL('https://github.com/Snirozu/Funkin-Psych-Online/releases', true);
			}
		}

		super.update(elapsed);

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.screenCenter(X);
		});
	}

	function changeItem(huh:Int = 0)
	{
		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.animation.play('idle');
			spr.updateHitbox();

			if (spr.ID == curSelected)
			{
				spr.animation.play('selected');
				var add:Float = 0;
				if(menuItems.length > 4) {
					add = menuItems.length * 8;
				}
				camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y - add);
				spr.centerOffsets();
			}
		});
	}
}
