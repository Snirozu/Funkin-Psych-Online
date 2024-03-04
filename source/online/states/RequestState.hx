package online.states;

import openfl.filters.BlurFilter;
import flixel.FlxObject;
import online.states.ServerSettingsSubstate.Option;

class RequestState extends MusicBeatSubstate {
	public var prompt:String;
	public var url:String;
	public var yesCallback:(nowTrusting:Null<Bool>) -> Void;
	public var noCallback:Void->Void;
	public var trust:Option;
	public var onCreate:RequestState->Void;
	
	var disableTrusting:Bool = false;

	public var promptText:FlxText;
	public var urlText:FlxText;
	public var yes:FlxText;
	public var no:FlxText;
	public var yesBg:FlxSprite;
	public var noBg:FlxSprite;

	var curSelected:Int = -1;

	var blurFilter:BlurFilter;
	var coolCam:FlxCamera;

	public static function requestURL(url:String, ?prompt:String = "Do you want to open this link", ?disableTrusting:Bool = false) {
		request(prompt, url, nowTrusting -> {
			if (nowTrusting != null) {
				var splitURL = url.split("//");
				if (nowTrusting)
					ClientPrefs.data.trustedSources.push(splitURL[0] + "//" + splitURL[1].split("/")[0]);
				else
					ClientPrefs.data.trustedSources.remove(splitURL[0] + "//" + splitURL[1].split("/")[0]);
				ClientPrefs.saveSettings();
			}

			FlxG.openURL(url);
		}, null, disableTrusting);
	}

	public static function requestDownload(url:String, ?prompt:String = "Do you want to download this file", ?onDownloadFinished:String->Void, ?disableTrusting:Bool = false, ?yesCallback:Void->Void) {
		request(prompt, url, nowTrusting -> {
			if (nowTrusting != null) {
				var splitURL = url.split("//");
				if (nowTrusting)
					ClientPrefs.data.trustedSources.push(splitURL[0] + "//" + splitURL[1].split("/")[0]);
				else
					ClientPrefs.data.trustedSources.remove(splitURL[0] + "//" + splitURL[1].split("/")[0]);
				ClientPrefs.saveSettings();
				if (yesCallback != null)
					yesCallback();
			}

			OnlineMods.startDownloadMod(url, url, null, onDownloadFinished);
		}, null, disableTrusting);
	}

	public static function request(prompt:String, url:String, yesCallback:(nowTrusting:Null<Bool>)->Void, noCallback:Void->Void, ?disableTrusting:Bool = false, ?onCreate:RequestState->Void) {
		if (FlxG.state.subState != null)
			FlxG.state.subState.close();

		if (!disableTrusting) {
			for (source in ClientPrefs.data.trustedSources) {
				if (StringTools.startsWith(url, source)) {
					yesCallback(null);
					return;
				}
			}
		}

		FlxG.state.openSubState(new RequestState(prompt, url, yesCallback, noCallback, disableTrusting, onCreate));
    }

	var _tempShowMouse:Bool = false;

	private function new(prompt:String, url:String, yesCallback:(nowTrusting:Null<Bool>) -> Void, noCallback:Void->Void, disableTrusting:Bool, onCreate:RequestState->Void) {
        super();

		this.prompt = prompt;
		this.url = url;
		this.yesCallback = yesCallback;
		this.noCallback = noCallback;
		this.disableTrusting = disableTrusting;
		this.onCreate = onCreate;
    }

	override function create() {
		super.create();
		
		blurFilter = new BlurFilter();
		for (cam in FlxG.cameras.list) {
			if (cam.filters == null)
				cam.filters = [];
			cam.filters.push(blurFilter);
		}

		coolCam = new FlxCamera();
		coolCam.bgColor.alpha = 0;
		FlxG.cameras.add(coolCam, false);

		cameras = [coolCam];

		if (!FlxG.mouse.visible) {
			FlxG.mouse.visible = true;
			_tempShowMouse = true;
		}

		var preBg = new FlxSprite();
		preBg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		preBg.alpha = 0.4;
		preBg.scrollFactor.set(0, 0);
		add(preBg);

		var bg = new FlxSprite();
		bg.makeGraphic(Std.int(FlxG.width / 2), FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.7;
		bg.scrollFactor.set(0, 0);
		bg.screenCenter(X);
		add(bg);

		promptText = new FlxText(bg.x, 200, bg.width - 50, prompt + ":");
		promptText.setFormat("VCR OSD Mono", 25, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		promptText.scrollFactor.set(0, 0);
		promptText.screenCenter(X);
		add(promptText);

		urlText = new FlxText(bg.x, promptText.y + promptText.height + 20, bg.width - 50, url);
		urlText.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		urlText.scrollFactor.set(0, 0);
		urlText.screenCenter(X);
		urlText.alpha = 0.8;
		add(urlText);

		yes = new FlxText(0, 0, 0, "Yes");
		yes.setFormat("VCR OSD Mono", 30, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		yes.x = FlxG.width / 2 - yes.width / 2 - 150;
		yes.y = promptText.y + 200;
		yes.scrollFactor.set(0, 0);
		yesBg = new FlxSprite();
		yesBg.makeGraphic(1, 1, 0x5D000000);
		yesBg.updateHitbox();
		yesBg.y = yes.y;
		yesBg.x = yes.x;
		yesBg.scale.set(yes.width, yes.height);
		yesBg.updateHitbox();
		yesBg.scrollFactor.set(0, 0);
		add(yesBg);
		add(yes);

		no = new FlxText(0, 0, 0, "No");
		no.setFormat("VCR OSD Mono", 30, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		no.x = FlxG.width / 2 - no.width / 2 + 150;
		no.y = yes.y;
		no.scrollFactor.set(0, 0);
		noBg = new FlxSprite();
		noBg.makeGraphic(1, 1, 0x5D000000);
		noBg.updateHitbox();
		noBg.y = no.y;
		noBg.x = no.x;
		noBg.scale.set(no.width, no.height);
		noBg.updateHitbox();
		noBg.scrollFactor.set(0, 0);
		add(noBg);
		add(no);

		if (!disableTrusting) {
			add(trust = new Option("Trust this source", "If checked, you will no longer be asked\nto accept links from this domain.", () -> {
				trust.checked = !trust.checked;
			}, null, 0, 500, isURLTrusted(url)));
			trust.scrollFactor.set(0, 0);
			trust.screenCenter(X);
			trust.alpha = 0.6;
		}

		yes.alpha = 0.6;
		no.alpha = 0.6;

		items = !disableTrusting ? 2 : 1;

		if (onCreate != null)
			onCreate(this);
	}

	override function destroy() {
		super.destroy();

		for (cam in FlxG.cameras.list) {
			if (cam?.filters != null)
				cam.filters.remove(blurFilter);
		}
		FlxG.cameras.remove(coolCam);
	}

	override public function close() {
		super.close();

		if (_tempShowMouse) {
			_tempShowMouse = false;
			FlxG.mouse.visible = false;
		}
	}

	var items:Int = 2;

	override function update(elapsed) {
		super.update(elapsed);

		if (controls.UI_LEFT_P || controls.UI_RIGHT_P) {
			curSelected++;

			if (curSelected > items) {
				curSelected = 0;
			}
			else if (curSelected < 0) {
				curSelected = items;
			}
		}

		if (FlxG.mouse.justPressed || FlxG.mouse.justMoved) {
			if (mouseHovers(yesBg))
				curSelected = 0;
			else if (mouseHovers(noBg))
				curSelected = 1;
			else if (!disableTrusting && mouseHovers(trust))
				curSelected = 2;
			else
				curSelected = -1;
		}

		if (controls.UI_LEFT_P || controls.UI_RIGHT_P || FlxG.mouse.justMoved) {
			yes.alpha = 0.6;
			no.alpha = 0.6;
			if (!disableTrusting)
				trust.alpha = 0.6;

			switch curSelected {
				case 0:
					yes.alpha = 1;
				case 1:
					no.alpha = 1;
				case 2:
					if (!disableTrusting)
						trust.alpha = 1;
			}
		}

		if (FlxG.mouse.justPressed || controls.ACCEPT) {
			switch curSelected {
				case 0:
					yesCallback(trust?.checked);
					close();
				case 1:
					if (noCallback != null)
						noCallback();
					close();
				case 2:
					if (!disableTrusting)
						trust.onClick();
			}
		}

		if (FlxG.keys.justPressed.ESCAPE) {
			if (noCallback != null)
				noCallback();
			close();
		}
	}

	function mouseHovers(object:FlxObject) {
		return FlxG.mouse.overlaps(object, camera);
	}

	function isURLTrusted(url:String) {
		for (source in ClientPrefs.data.trustedSources) {
			if (StringTools.startsWith(url, source)) {
				return true;
			}
		}
		return false;
	}
}