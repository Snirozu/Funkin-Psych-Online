package online.states;

import flixel.FlxObject;

class OpenURL extends MusicBeatSubstate {
    final url:String;
	var yes:FlxText;
	var yesBg:FlxSprite;
	var yesOnce:FlxText;
	var yesOnceBg:FlxSprite;
	var no:FlxText;
	var noBg:FlxSprite;

    var selected:Int = -1;

	var swagPrompt:String = "Do you want to open URL:";

	var isDownload:Bool = false;
	var onDownloadFinished:String->Void;

	var disableAutoRedirect:Bool = false;

	public static function open(url:String, ?swagPrompt:String, ?isDownload:Bool = false, ?onDownloadFinished:String->Void, ?disableAutoRedirect:Bool = false) { 
        if (FlxG.state.subState != null)
			FlxG.state.subState.close();

		if (!disableAutoRedirect) {
			for (source in Wrapper.prefTrustedSources) {
				if (StringTools.startsWith(url, source)) {
					if (isDownload) {
						OnlineMods.startDownloadMod(url, url, null, onDownloadFinished);
					}
					else {
						FlxG.openURL(url);
					}

					return;
				}
			}
		}

		FlxG.state.openSubState(new OpenURL(url, swagPrompt, isDownload, onDownloadFinished, disableAutoRedirect));
    }
	function new(url:String, ?swagPrompt:String, ?isDownload:Bool = false, ?onDownloadFinished:String->Void, ?disableAutoRedirect:Bool = false) {
        super();

		this.url = url.trim();
		if (swagPrompt != null)
		    this.swagPrompt = swagPrompt;
		this.isDownload = isDownload;
		this.onDownloadFinished = onDownloadFinished;
		this.disableAutoRedirect = disableAutoRedirect;
    }

    override function create() {
        super.create();

		var bg = new FlxSprite();
		bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.8;
		add(bg);

		var prompt = new FlxText(0, 0, FlxG.width, swagPrompt + "\n\n" + url);
		prompt.setFormat("VCR OSD Mono", 25, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		prompt.y = 200;
		prompt.scrollFactor.set(0, 0);
		prompt.screenCenter(X);
		add(prompt);

		yes = new FlxText(0, 0, 0, isDownload ? "Download & Trust" : "Open & Trust");
		yes.setFormat("VCR OSD Mono", 30, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		yes.x = FlxG.width / 2 - yes.width / 2 - 150;
		yes.y = 400;
		yes.scrollFactor.set(0, 0);
		yesBg = new FlxSprite();
		yesBg.makeGraphic(1, 1, 0x5D000000);
		yesBg.updateHitbox();
		yesBg.y = yes.y;
		yesBg.x = yes.x;
		yesBg.scale.set(yes.width, yes.height);
		yesBg.updateHitbox();
		add(yesBg);
        add(yes);

		yesOnce = new FlxText(0, 0, 0, isDownload ? "Download Once" : "Open Once");
		yesOnce.setFormat("VCR OSD Mono", 30, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		yesOnce.x = FlxG.width / 2 - yesOnce.width / 2 + 150;
		yesOnce.y = yes.y;
		yesOnce.scrollFactor.set(0, 0);
		yesOnceBg = new FlxSprite();
		yesOnceBg.makeGraphic(1, 1, 0x5D000000);
		yesOnceBg.updateHitbox();
		yesOnceBg.y = yesOnce.y;
		yesOnceBg.x = yesOnce.x;
		yesOnceBg.scale.set(yesOnce.width, yesOnce.height);
		yesOnceBg.updateHitbox();
		add(yesOnceBg);
		add(yesOnce);

		no = new FlxText(0, 0, 0, "Cancel");
		no.setFormat("VCR OSD Mono", 30, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		no.x = FlxG.width / 2 - no.width / 2;
		no.y = 500;
		no.scrollFactor.set(0, 0);
		noBg = new FlxSprite();
		noBg.makeGraphic(1, 1, 0x5D000000);
		noBg.updateHitbox();
		noBg.y = no.y;
		noBg.x = no.x;
		noBg.scale.set(no.width, no.height);
		noBg.updateHitbox();
		add(noBg);
		add(no);

		if (disableAutoRedirect) {
			yes.visible = false;
			yesBg.visible = false;
			no.setPosition(yesOnce.x, yesOnce.y);
			noBg.setPosition(yesOnceBg.x, yesOnceBg.y);
			yesOnce.setPosition(yes.x, yes.y);
			yesOnceBg.setPosition(yesBg.x, yesBg.y);
		}
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

		var len = disableAutoRedirect ? 1 : 2;

        if (FlxG.mouse.justMoved) {
			if (FlxG.mouse.overlaps(yesBg, camera)) {
				selected = 0;
            }
			else if (FlxG.mouse.overlaps(yesOnceBg, camera)) {
				if (disableAutoRedirect)
					selected = 0;
				else
					selected = 1;
			}
			else if (FlxG.mouse.overlaps(noBg, camera)) {
				if (disableAutoRedirect)
					selected = 1;
				else 
					selected = 2;
			}
            else {
				selected = -1;
            }
        }

		if (controls.UI_LEFT_P || controls.UI_RIGHT_P) {
			selected++;

			if (selected > len) {
				selected = 0;
			}
			else if (selected < 0) {
				selected = len;
			}
        }

		if (!disableAutoRedirect) {
			if (selected == 0) {
				if (controls.ACCEPT || FlxG.mouse.justPressed) {
					var splitURL = url.split("//");
					Wrapper.prefTrustedSources.push(splitURL[0] + "//" + splitURL[1].split("/")[0]);
					ClientPrefs.saveSettings();

					if (isDownload) {
						OnlineMods.startDownloadMod(url, url, null, onDownloadFinished);
					}
					else {
						FlxG.openURL(url);
					}
					close();
				}
				yes.alpha = 1;
				no.alpha = 0.7;
				yesOnce.alpha = 0.7;
			}
			else if (selected == 1) {
				if (controls.ACCEPT || FlxG.mouse.justPressed) {
					if (isDownload) {
						OnlineMods.startDownloadMod(url, url, null, onDownloadFinished);
					}
					else {
						FlxG.openURL(url);
					}
					close();
				}
				yes.alpha = 0.7;
				no.alpha = 0.7;
				yesOnce.alpha = 1;
			}
			else if (selected == 2) {
				if (controls.ACCEPT || FlxG.mouse.justPressed) {
					close();
				}
				yes.alpha = 0.7;
				no.alpha = 1;
				yesOnce.alpha = 0.7;
			}
			else {
				yes.alpha = 0.7;
				no.alpha = 0.7;
				yesOnce.alpha = 0.7;
			}
		}
		else {
			if (selected == 0) {
				if (controls.ACCEPT || FlxG.mouse.justPressed) {
					if (isDownload) {
						OnlineMods.startDownloadMod(url, url, null, onDownloadFinished);
					}
					else {
						FlxG.openURL(url);
					}
					close();
				}
				yes.alpha = 0.7;
				no.alpha = 0.7;
				yesOnce.alpha = 1;
			}
			else if (selected == 1) {
				if (controls.ACCEPT || FlxG.mouse.justPressed) {
					close();
				}
				yes.alpha = 0.7;
				no.alpha = 1;
				yesOnce.alpha = 0.7;
			}
			else {
				yes.alpha = 0.7;
				no.alpha = 0.7;
				yesOnce.alpha = 0.7;
			}
		}

        
		if (controls.BACK) {
			close();
		}
    }
}