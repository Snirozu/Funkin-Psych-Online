package online.substates;

import openfl.events.KeyboardEvent;
import lime.system.Clipboard;

class SoFunkinSubstate extends MusicBeatSubstate {
	public var options:Array<String> = [];
	public var callback:Int->Bool;
	public var iconCallback:(Int, FlxSprite)->FlxSprite;

	public var curGroup:Int = 0;
	public var groups:Array<String> = [];
	public var groupCallback:Int->Array<String>;

	var groupTitle:Scrollable;

	private var mapTexts:Map<String, FlxSprite> = new Map<String, FlxSprite>();
	private var mapIcons:Map<String, FlxSprite> = new Map<String, FlxSprite>();

	private var grpTexts:FlxTypedGroup<FlxSprite>;
	private var grpIcons:FlxTypedGroup<FlxSprite>;

	var lerpSelected:Float = 0;
	private var curSelected:Int = 0;

	var searchInput:FlxText;
	var searchUnderlay:FlxSprite;
	var searchInputWait(default, set):Bool = false;
	var searchString(default, set):String = '';

	public function new(options:Array<String>, ?selected:Int = 0, callback:Int->Bool, ?iconCallback:(Int, FlxSprite)->FlxSprite) {
        super();
        
		curSelected = selected;
		this.options = options;
		this.callback = callback;
		this.iconCallback = iconCallback;
    }

	override function create() {
		lerpSelected = curSelected;

		var bg:FlxSprite = new FlxSprite();
		bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.scrollFactor.set();
		bg.alpha = 0.8;
		add(bg);

		grpTexts = new FlxTypedGroup<FlxSprite>();
		add(grpTexts);

		grpIcons = new FlxTypedGroup<FlxSprite>();
		add(grpIcons);

		createTexts();

		searchUnderlay = new FlxSprite();
		searchUnderlay.makeGraphic(1, 1, FlxColor.BLACK);
		searchUnderlay.alpha = 0.6;
		add(searchUnderlay);

		searchInput = new FlxText(0, 0, "PRESS F TO SEARCH");
		searchInput.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		searchInput.scrollFactor.set();
		add(searchInput);

		// if (!ClientPrefs.data.disableFreeplayAlphabet)
		groupTitle = new Alphabet(90, 320, "DEFAULT", true);
		// else
		// 	groupTitle = new online.objects.AlphaLikeText(90, 320, "");
		groupTitle.targetY = -1;
		groupTitle.snapToPosition();
		add(cast groupTitle);

		updateGroup();
		if (groups.length == 0)
			search();

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);

		super.create();
	}
	
	override function destroy() {
		super.destroy();

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
	}

	function set_searchString(v) {
		if (searchInputWait || v.length > 0) {
			searchInput.alpha = searchInputWait ? 1.0 : 0.6;
			searchInput.text = "SEARCH: '" + v + "'";
			reposSearch();
			return searchString = v;
		}

		searchInput.alpha = 0.6;
		searchInput.text = 'PRESS F TO SEARCH';
		reposSearch();
		return searchString = v;
	}

	function set_searchInputWait(v) {
		searchInputWait = v;
		searchString = searchString;
		return searchInputWait;
	}

	function reposSearch() {
		searchInput.x = FlxG.width - searchInput.width - 5;
		searchInput.y = 5;

		searchUnderlay.setPosition(searchInput.x - 5, searchInput.y - 5);
		searchUnderlay.scale.set(searchInput.width + 10, searchInput.height + 10);
		searchUnderlay.updateHitbox();
	}

	function createTexts() {
		for (text in mapTexts) {
			text.destroy();
			remove(text);
		}
		for (icon in mapIcons) {
			icon.destroy();
			remove(icon);
		}
		mapTexts.clear();
		mapIcons.clear();

		for (i in 0...options.length) {
			var leText:Scrollable;
			if (!ClientPrefs.data.disableFreeplayAlphabet)
				leText = new Alphabet(90, 320, options[i], true);
			else
				leText = new online.objects.AlphaLikeText(90, 320, options[i]);
			leText.isMenuItem = true;
			leText.targetY = i - curSelected;
			leText.ID = i;
			mapTexts.set(options[i], cast leText);
			leText.snapToPosition();

			if (iconCallback != null) {
				var icon = iconCallback(i, cast(leText));
				if (icon != null)
					mapIcons.set(options[i], icon);
			}
		}
	}

	function updateGroup() {
		groupTitle.visible = groups.length > 0;
		if (groups.length > 0) {
			if (curGroup < 0)
				curGroup = groups.length - 1;
			if (curGroup > groups.length - 1)
				curGroup = 0;

			var textValue = groups[curGroup].substr(0, 30);

			groupTitle.visible = true;

			if (groupTitle is Alphabet)
				cast(groupTitle, Alphabet).text = "< " + textValue + " >";
			else if (groupTitle is online.objects.AlphaLikeText)
				cast(groupTitle, online.objects.AlphaLikeText).text = "< " + textValue + " >";
			groupTitle.scaleY = 0.7;
			groupTitle.scaleX = 0.7;

			if (groupCallback != null)
				options = groupCallback(curGroup);

			createTexts();
			search();
		}
	}

	function search() {
		grpTexts.clear();
		grpIcons.clear();

		for (option in options) {
			if (option.toLowerCase().contains(searchString.toLowerCase())) {
				grpTexts.add(mapTexts.get(option));
				if (mapIcons.exists(option))
					grpIcons.add(mapIcons.get(option));
			}
		}

		if (grpTexts.length == 0 && searchString.length > 0) {
			searchString = '';
			search();
			searchInput.text = "NOT FOUND!";
			return;
		}

		changeSelection();
		searchString = searchString;
	}

	var disableInputWaitNext = false;
	override function update(elapsed:Float) {
		super.update(elapsed);

		lerpSelected = FlxMath.lerp(lerpSelected, curSelected, FlxMath.bound(elapsed * 9.6, 0, 1));

		updateScrollable(groupTitle, elapsed);

		if (!searchInputWait && FlxG.keys.justPressed.F) {
			searchInputWait = true;
			searchString = searchString;
		}

		if (searchInputWait) {
			if (disableInputWaitNext) {
				disableInputWaitNext = false;
				searchInputWait = false;
			}
			return;
		}

		var shiftMult = FlxG.keys.pressed.SHIFT ? 2 : 1;
		if (controls.UI_UP_P) {
			changeSelection(-1 * shiftMult);
		}
		if (controls.UI_DOWN_P) {
			changeSelection(1 * shiftMult);
		}
		if (FlxG.mouse.wheel != 0) {
			changeSelection(-shiftMult * FlxG.mouse.wheel);
		}

		if (controls.UI_LEFT_P) {
			curGroup--;
			updateGroup();
		}
		if (controls.UI_RIGHT_P) {
			curGroup++;
			updateGroup();
		}

		if (controls.BACK) {
			close();
		}

		if (controls.ACCEPT) {
			if (callback(grpTexts.members[curSelected].ID))
				close();
		}

		var bullShit:Int = 0;
		var item:Scrollable;
		for (_item in grpTexts.members) {
			item = cast _item;
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0) {
				item.alpha = 1;
			}
		}
	}

	private function updateScrollable(obj:Scrollable, elapsed:Float = 0.0) {
		obj.x = ((obj.targetY - lerpSelected) * obj.distancePerItem.x) + obj.startPosition.x;
		obj.y = ((obj.targetY - lerpSelected) * 1.3 * obj.distancePerItem.y) + obj.startPosition.y;

		obj.alpha = FlxMath.bound(obj.alpha + elapsed * 5, 0, 0.6);
	}

	function changeSelection(change:Int = 0) {
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = grpTexts.length - 1;
		if (curSelected >= grpTexts.length)
			curSelected = 0;
	}

	function onKeyDown(e:KeyboardEvent) {
		if (!searchInputWait)
			return;

		var key = e.keyCode;

		if (e.charCode == 0) { // non-printable characters crash String.fromCharCode
			return;
		}

		if (key == 46) { // delete
			return;
		}

		if (key == 8) { // bckspc
			searchString = searchString.substring(0, searchString.length - 1);
			return;
		}
		else if (key == 13) { // enter
			disableInputWaitNext = true;
			search();
			return;
		}
		else if (key == 27) { // esc
			disableInputWaitNext = true;
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
}