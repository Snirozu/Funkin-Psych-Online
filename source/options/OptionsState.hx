package options;

import states.ModsMenuState;
import online.states.RoomState;
import states.MainMenuState;
import backend.StageData;

// call it optionsmenustate? naahh
class OptionsState extends MusicBeatState
{
	var optionsMap:Map<String, Array<String>> = [
		'main' => ['Controls', 'Performance', 'Visuals & UI', 'Game'],
		'visuals' => ['Notes', 'Combo & Rating', 'User Interface', 'Accessibility'],
		'game' => ['Gameplay', 'Preferences', 'Adjust Audio Delay'],
	];
	private var grpOptionsMap:Map<String, FlxTypedGroup<Alphabet>> = new Map();
	static var optionsCategory(default, set):String = 'main';
	static function set_optionsCategory(v) {
		optionsCategory = v;
		if (FlxG.state is OptionsState)
			(cast (FlxG.state, OptionsState)).updateCategory();
		return optionsCategory;
	}

	function updateCategory() {
		if (_addedGrpOptions != null)
			remove(_addedGrpOptions);
		add(_addedGrpOptions = grpOptions);
		changeSelection();
		titleText.visible = optionsCategory != 'main';
		titleText.text = optionsCategory;
		titleText.screenCenter(X);
		if (FlxG.mouse.justPressed)
			forceUpdateNext = true;
	}

	private var options(get, never):Array<String>;
	function get_options() {
		return optionsMap.get(optionsCategory);
	}
	var _addedGrpOptions:FlxTypedGroup<Alphabet>;
	private var grpOptions(get, never):FlxTypedGroup<Alphabet>;
	function get_grpOptions() {
		return grpOptionsMap.get(optionsCategory);
	}

	private static var curSelectedMap:Map<String, Int> = new Map();
	private static var curSelected(get, set):Int;
	static function get_curSelected() {
		if (!curSelectedMap.exists(optionsCategory))
			curSelectedMap.set(optionsCategory, 0);

		return curSelectedMap.get(optionsCategory);
	}
	static function set_curSelected(v) {
		curSelectedMap.set(optionsCategory, v);
		return v;
	}

	public static var menuBG:FlxSprite;
	public static var onPlayState:Bool = false;
	public static var onOnlineRoom:Bool = false;
	public static var hadMouseVisible:Bool = false;
	public static var loadedMod:String = '';

	function openSelectedSubstate(label:String) {
		if (optionsCategory == 'visuals') {
			openSubState(new options.VisualsUISubState(label));
			return;
		}

		if (optionsCategory == 'game') {
			if (label == 'Adjust Audio Delay') {
				FlxG.switchState(() -> new options.NoteOffsetState('delay'));
				return;
			}
			openSubState(new options.GameplaySettingsSubState(label));
			return;
		}

		switch(label) {
			case 'Controls':
				openSubState(new options.ControlsSubState());
			case 'Performance':
				openSubState(new options.GraphicsSettingsSubState());
			case 'Visuals & UI':
				optionsCategory = 'visuals';
			case 'Game':
				optionsCategory = 'game';
			case 'Mods':
				FlxG.switchState(() -> new ModsMenuState());
		}
	}

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;
	var titleText:Alphabet;
	var back:FlxSprite;

	override function create() {
		hadMouseVisible = FlxG.mouse.visible;
		FlxG.mouse.visible = true;

		OptionsState.loadedMod = Mods.currentModDirectory;
		
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Menus", "Options");
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.color = 0xFFea71fd;
		bg.updateHitbox();

		bg.screenCenter();
		add(bg);

		back = new FlxSprite();
		back.antialiasing = ClientPrefs.data.antialiasing;
		back.frames = Paths.getSparrowAtlas('backspace');
		back.animation.addByPrefix('idle', "backspace to exit white", 1);
		back.animation.addByPrefix('black', "backspace to exit0", 1);
		back.animation.addByPrefix('press', "backspace PRESSED", 12, false);
		back.animation.play('black');
		back.scale.set(0.5, 0.5);
		back.updateHitbox();
		back.x = 30;
		back.y = FlxG.height - back.height - 30;
		var ogOff = [back.offset.x, back.offset.y];
		back.animation.finishCallback = n -> {
			back.offset.set(ogOff[0], ogOff[1]);
			back.animation.play('black', true);
		};
		add(back);

		titleText = new Alphabet(75, 45, '', true);
		titleText.setScale(0.6);
		titleText.alpha = 0.4;
		add(titleText);

		#if MODS_ALLOWED
		if (!onPlayState)
			optionsMap.get('main').push('Mods');
		#end

		for (category => items in optionsMap) {
			var group = new FlxTypedGroup<Alphabet>();

			for (i in 0...items.length) {
				var optionText:Alphabet = new Alphabet(0, 0, items[i], true);
				optionText.screenCenter();
				optionText.y += (100 * (i - (items.length / 2))) + 50;
				group.add(optionText);
			}

			grpOptionsMap.set(category, group);
		}

		selectorLeft = new Alphabet(0, 0, '>', true);
		add(selectorLeft);
		selectorRight = new Alphabet(0, 0, '<', true);
		add(selectorRight);

		updateCategory();
		ClientPrefs.saveSettings();

		super.create();

		online.GameClient.send("status", "In the Game Options");
	}

	override function closeSubState() {
		super.closeSubState();
		FlxG.mouse.visible = true;
		ClientPrefs.saveSettings();
	}

	var forceUpdateNext:Bool = true;
	override function update(elapsed:Float) {
		super.update(elapsed);

		if (controls.UI_UP_P) {
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P) {
			changeSelection(1);
		}
		
		if (FlxG.mouse.deltaScreenY != 0 || forceUpdateNext) {
			for (i => spr in grpOptions) {
				if (FlxG.mouse.overlaps(spr, spr.camera) && i - curSelected != 0) {
					changeSelection(i - curSelected);
				}
			}
			forceUpdateNext = false;
		}

		if (FlxG.mouse.wheel != 0) {
			changeSelection(-FlxG.mouse.wheel);
		}

		if (controls.BACK || FlxG.keys.justPressed.BACKSPACE) {
			// back.offset.set(80, 50);
			// back.animation.play('press', true);

			if (optionsCategory == 'main') {
				FlxG.mouse.visible = hadMouseVisible;
				Mods.currentModDirectory = OptionsState.loadedMod;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				if(onPlayState)
				{
					StageData.loadDirectory(PlayState.SONG);
					LoadingState.loadAndSwitchState(new PlayState());
					FlxG.sound.music.volume = 0;
				}
				else if (onOnlineRoom) {
					LoadingState.loadAndSwitchState(new RoomState());
				}
				else FlxG.switchState(() -> new MainMenuState());
			}
			else {
				optionsCategory = 'main';
			}
		}
		else if (controls.ACCEPT || FlxG.mouse.justPressed) openSelectedSubstate(options[curSelected]);
	}
	
	function changeSelection(change:Int = 0) {
		curSelected += change;
		if (curSelected < 0)
			curSelected = options.length - 1;
		if (curSelected >= options.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpOptions.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			if (item.targetY == 0) {
				item.alpha = 1;
				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;
				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	override function destroy()
	{
		ClientPrefs.loadPrefs();
		super.destroy();
	}
}