package online.substates;

import openfl.display.BitmapData;
import objects.HealthIcon;
import openfl.utils.Future;
import openfl.events.KeyboardEvent;
import lime.system.Clipboard;

//TODO every update fetch an icon from the queue and wait for the promise relating to it to finish, then store it in icons

class SoFunkinSubstate extends MusicBeatSubstate {
	public var options:Array<String> = [];
	public var optionsIcons:Map<Int, HealthIcon> = new Map();
	public var callback:Int->Bool;
	public var iconCallback:Int->PathInfo;

	public var curGroup:Int = 0;
	public var groups:Array<String> = [];
	public var groupCallback:Int->Array<String>;
	public var pressCallback:Controls->Void;
	public var renderCallback:(Int,Scrollable,Null<HealthIcon>)->Void;

	var groupTitle:Scrollable;

	private var grpTexts:FlxTypedGroup<FlxSprite>;
	var centerOfRenders:Int;
	private var grpIcons:FlxTypedGroup<HealthIcon>;
	public var grpIconsOverlay:FlxTypedGroup<FlxSprite>;

	var lerpSelected:Float = 0;
	public var curSelected:Int = 0;

	var searchInput:FlxText;
	var searchUnderlay:FlxSprite;
	var searchInputWait(default, set):Bool = false;
	var searchString(default, set):String = '';

	public function new(options:Array<String>, ?selected:Int = 0, ?callback:Int->Bool) {
        super();
        
		curSelected = selected;
		this.options = options;
		this.callback = callback;
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

		grpIcons = new FlxTypedGroup<HealthIcon>();
		add(grpIcons);

		grpIconsOverlay = new FlxTypedGroup<FlxSprite>();
		add(grpIconsOverlay);

		for (i in 0...15) {
			var leText:Scrollable;
			if (!ClientPrefs.data.disableFreeplayAlphabet)
				leText = new Alphabet(90, 320, '', true);
			else
				leText = new online.objects.AlphaLikeText(90, 320, '');
			// leText.isMenuItem = true;
			leText.targetY = i;
			leText.ID = i;
			leText.snapToPosition();
			grpTexts.add(cast leText);
		}
		centerOfRenders = Std.int(grpTexts.members.length / 2);

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

	public function updateGroup() {
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

			if (groupCallback != null) {
				options = groupCallback(curGroup);
				optionsIcons.clear();
			}

			search();
		}
	}

	var searchOptions:Array<Int> = [];
	function search() {
		searchOptions = [];

		for (i => option in options) {
			if (option.toLowerCase().contains(searchString.toLowerCase())) {
				searchOptions.push(i);
			}
		}

		if (searchOptions.length == 0 && searchString.length > 0) {
			searchString = '';
			search();
			searchInput.text = "NOT FOUND!";
			return;
		}

		changeSelection();
		searchString = searchString;
	}

	var disableInputWaitNext = false;
	var futureIcon:Future<BitmapData> = null;
	var futureIndex:Int = -1;
	var futureQueue:Array<Int> = [];
	var futureIconPath:String = null;
	override function update(elapsed:Float) {
		super.update(elapsed);

		if (futureIcon != null) {
			if (futureIcon.isComplete || futureIcon.isError) {
				if (!futureIcon.isError && futureIcon.value != null) {
					var icon = new HealthIcon(null, false);
					icon.loadIcon(Paths.bitmapToGraphic(futureIconPath, futureIcon.value));
					icon.scrollFactor.set(1, 1);
					optionsIcons.set(futureIndex, icon);
					changeSelection();
				}
				futureIcon = null;
			}
		}
		else if (futureQueue.length > 0) {
			futureIndex = futureQueue.shift();

			if (iconCallback != null && !ClientPrefs.data.disableFreeplayIcons) {
				var icon = iconCallback(futureIndex);
				if (icon != null) {
					futureIconPath = icon.path;
					futureIcon = Paths.asyncBitmap(icon.path, null, icon.mod);
				}
			}
		}

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

		if (FlxG.keys.justPressed.HOME) {
			curSelected = 0;
			changeSelection();
		}
		else if (FlxG.keys.justPressed.END) {
			curSelected = searchOptions.length - 1;
			changeSelection();
		}

		if (controls.BACK) {
			close();
		}

		if (controls.ACCEPT) {
			if (selectedItem != null && callback(selectedItem.ID))
				close();
		}

		if (FlxG.keys.pressed.ANY && pressCallback != null) {
			pressCallback(controls);
		}

		for (grpIndex => item in grpTexts.members) {
			var item:Scrollable = cast(item, Scrollable);
			item.x = ((item.targetY - lerpSelected) * item.distancePerItem.x) + item.startPosition.x;
			item.y = ((item.targetY - lerpSelected) * 1.3 * item.distancePerItem.y) + item.startPosition.y;
		}
	}

	private function updateScrollable(obj:Scrollable, elapsed:Float = 0.0) {
		obj.x = ((obj.targetY - lerpSelected) * obj.distancePerItem.x) + obj.startPosition.x;
		obj.y = ((obj.targetY - lerpSelected) * 1.3 * obj.distancePerItem.y) + obj.startPosition.y;

		obj.alpha = FlxMath.bound(obj.alpha + elapsed * 5, 0, 0.6);
	}

	public function getSelectedOptionIndex() {
		if (!searchOptions.contains(curSelected))
			return -1;
		return searchOptions[curSelected];
	}

	public var selectedItem:Scrollable = null;
	public function changeSelection(change:Int = 0) {
		if (change != 0)
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = searchOptions.length - 1;
		if (curSelected >= searchOptions.length)
			curSelected = 0;

		var foundTexts:Array<String> = [];

		// 50 more loops here but it's way faster than just simply updating every text

		for (i => item in grpTexts.members) {
			final searchIndex = i + curSelected - centerOfRenders;
			item.ID = searchOptions[searchIndex];
			final option = options[item.ID];

			if (option == null) {
				foundTexts[i] = null;
				continue;
			}

			foundTexts[i] = (grpTexts.members[0] is online.objects.AlphaLikeText ? ' ' : '') + option + (grpTexts.members[0] is online.objects.AlphaLikeText ? '\n ' : '');
		}

		var newMembs = [for (_ in grpTexts.members) null];
		var missings = [];
		for (obj in grpTexts.members) {
			var txt:Scrollable = cast obj;
			final newIndex = foundTexts.indexOf(txt.text);

			if (newIndex != -1 && foundTexts[newIndex] != null)
				newMembs[newIndex] = obj;
			else
				missings.push(obj);

			foundTexts[newIndex] = null;
		}

		for (obj in missings) {
			newMembs[newMembs.indexOf(null)] = obj;
		}

		grpTexts.clear();
		grpIcons.clear();
		grpIconsOverlay.killMembers();
		futureQueue = [];

		for (obj in newMembs) {
			grpTexts.add(obj);
		}

		var item:Scrollable;
		for (i => _item in grpTexts.members) {
			item = cast _item;
			final searchIndex = i + curSelected - centerOfRenders;
			item.ID = searchOptions[searchIndex];
			final option = options[item.ID];
			if (option == null || searchIndex >= searchOptions.length || searchIndex < 0) {
				item.visible = false;
				continue;
			}

			item.visible = true;
			final wantText = (item is online.objects.AlphaLikeText ? ' ' : '') + option + (item is online.objects.AlphaLikeText ? '\n ' : '');
			if (item.text != wantText) {
				item.text = wantText;
				item.scaleX = Math.min(1, 980 / item.width);
				if (item is online.objects.AlphaLikeText)
					cast (item, online.objects.AlphaLikeText).updateHitbox();
			}
			item.targetY = i - centerOfRenders + curSelected;

			final icon = optionsIcons.get(item.ID);
			if (icon != null) {
				icon.sprTracker = cast item;
				icon.snapToTracker();
				grpIcons.add(icon);
			}
			else if (!optionsIcons.exists(item.ID) && futureIndex != item.ID) {
				futureQueue.push(item.ID);
			}

			if (renderCallback != null)
				renderCallback(item.ID, item, icon);

			if (item.targetY == curSelected) {
				selectedItem = item;
				item.alpha = 1;
				continue;
			}
			item.alpha = 0.6;
		}
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

typedef PathInfo = {
	var path:String;
	@:optional var mod:String;
}