package online.states;

import openfl.filters.BlurFilter;
import online.GameBanana.DownloadPage;
import online.GameBanana.GBMod;
import flixel.FlxObject;

class SelectDownloadState extends MusicBeatSubstate {
	public static var instance:SelectDownloadState;

	public var items:FlxTypedGroup<DownloadBox>;
	public var selected(default, set):Int = 0;

	var downloads:DownloadPage;

	var blurFilter:BlurFilter;
	var coolCam:FlxCamera;

	function set_selected(v) {
		if (v >= items.length) {
			v = items.length - 1;
		}
		else if (v < 0) {
			v = 0;
		}

		return selected = v;
	}

	public function new(downloads:DownloadPage) {
        super();

		instance = this;

		this.downloads = downloads;
    }

	var bg:FlxSprite;

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

		var preBg = new FlxSprite();
		preBg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		preBg.alpha = 0.5;
		preBg.scrollFactor.set(0, 0);
		add(preBg);

		bg = new FlxSprite();
		bg.makeGraphic(700, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.4;
		bg.scrollFactor.set(0, 0);
		bg.screenCenter(X);
		add(bg);

		add(items = new FlxTypedGroup<DownloadBox>());
		var i = -1;

		var altText = new FlxText(bg.x, 0, bg.width);
		altText.text = 'Files';
		altText.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		altText.y = 30;
		add(altText);

		var endCoord = altText.y + altText.height;

		if (downloads._aFiles != null && downloads._aFiles.length > 0) {
			for (dl in downloads._aFiles) {
				if (dl._sFile.endsWith(".7z"))
					continue;
				
				dl._sDescription += (dl._sDescription.trim() != "" ? "\n" : "") + "Size: " + DownloadAlert.prettyBytes(dl._nFilesize);

				var download = new DownloadBox(dl._sFile, dl._sDescription, dl._sDownloadUrl, ++i);
				download.y = endCoord + 10;
				endCoord = download.y + download.height;
				download.camera = camera; //smh
				items.add(download);
			}
		}

		if (downloads._aAlternateFileSources != null && downloads._aAlternateFileSources.length > 0) {
			var altText = new FlxText(bg.x, 0, bg.width);
			altText.text = 'Alternate File Sources';
			altText.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			if (items.members.length > 0)
				altText.y = endCoord + 20;
			endCoord = altText.y + altText.height;
			add(altText);

			for (dl in downloads._aAlternateFileSources) {
				var download = new DownloadBox(dl.description, dl.url, dl.url, ++i);
				download.y = endCoord + 10;
				endCoord = download.y + download.height;
				download.camera = camera; // smh
				items.add(download);
			}
		}

		coolCam.setScrollBounds(FlxG.width, FlxG.width, 0, endCoord + 20 > FlxG.height ? endCoord + 20 : FlxG.height);
    }

	override function destroy() {
		super.destroy();

		for (cam in FlxG.cameras.list) {
			if (cam?.filters != null)
				cam.filters.remove(blurFilter);
		}
		FlxG.cameras.remove(coolCam);
	}

	override function update(elapsed) {
		if (controls.UI_UP_P)
			selected--;
		else if (controls.UI_DOWN_P)
			selected++;

		if (controls.BACK || (FlxG.mouse.justPressed && !FlxG.mouse.overlaps(bg, camera))) {
			close();
		}

		super.update(elapsed);

		if (items.length > 0)
			coolCam.follow(items.members[selected], null, 0.1);
	}
}

class DownloadBox extends FlxSpriteGroup {
	public var code:String;

	public var bg:FlxSprite;
	var name:FlxText;
	var description:FlxText;
	var url:String;

	public function new(daName:String, daDescription:String, url:String, id:Int) {
		super();

		this.url = url;
		this.ID = id;

		bg = new FlxSprite();
		bg.makeGraphic(600, 1, 0xD3000000);
		add(bg);

		name = new FlxText(0, 0, bg.width - 20, daName);
		name.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, LEFT);
		name.setPosition(10, 10);
		add(name);

		if (daDescription.trim() != "") {
			description = new FlxText(0, 0, bg.width - 20, daDescription);
			description.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT);
			description.setPosition(10, name.y + name.height + 10);
			add(description);

			bg.scale.y = description.y + description.height + 10;
			bg.updateHitbox();
		}
		else {
			bg.scale.y = name.y + name.height + 10;
			bg.updateHitbox();
		}

		screenCenter(X);
	}

	override function update(elapsed) {
		super.update(elapsed);

		if (FlxG.mouse.overlaps(bg, camera) && (FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0 || FlxG.mouse.justPressed)) {
			SelectDownloadState.instance.selected = ID;
		}

		if (ID == SelectDownloadState.instance.selected) {
			alpha = 1.0;

			@:privateAccess
			if (SelectDownloadState.instance.controls.ACCEPT || (FlxG.mouse.justPressed && FlxG.mouse.overlaps(bg, camera))) {
				OnlineMods.downloadMod(url);
				SelectDownloadState.instance.close();
			}
		}
		else {
			alpha = 0.7;
		}
	}
}