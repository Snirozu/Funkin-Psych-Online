package online.states;

import lime.system.Clipboard;
import openfl.events.KeyboardEvent;
import flixel.math.FlxRect;
import sys.thread.Thread;
import haxe.io.Bytes;
import haxe.Http;
import openfl.display.BitmapData;
import flixel.graphics.FlxGraphic;
import online.GameBanana.GBSub;
import flixel.group.FlxGroup;

class BananaDownload extends MusicBeatState {
	var items:FlxTypedSpriteGroup<ModItem> = new FlxTypedSpriteGroup<ModItem>();
	var itemsY:Int = FlxG.height - (3 * 190) - 50;
	var curSelected:Int = 0;
	var page:Int = 1;
	var loading:Bool = false;
	var searchBg:FlxSprite;
	var searchPlaceholder:FlxText;
	var searchInput:FlxText;
	var pageInfo:FlxText;
	var inputWait:Bool = false;
	
	override function create() {
		super.create();

		DiscordClient.changePresence("Browsing mods on GameBanana.", null, null, false);

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xff46463b;
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = Wrapper.prefAntialiasing;
		bg.scrollFactor.set(0, 0);
		add(bg);

		add(items);

		searchBg = new FlxSprite();
		searchBg.makeGraphic(800, 60, FlxColor.BLACK);
		searchBg.screenCenter(X);
		searchBg.y = itemsY / 2 - searchBg.height / 2;
		searchBg.alpha = 0.6;
		add(searchBg);

		searchPlaceholder = new FlxText();
		searchPlaceholder.text = "Search mods here // Enter a URL to download...";
		searchPlaceholder.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		searchPlaceholder.alpha = 0.6;
		searchPlaceholder.x = searchBg.x + 20;
		searchPlaceholder.y = searchBg.y + searchBg.height / 2 - searchPlaceholder.height / 2;
		add(searchPlaceholder);

		searchInput = new FlxText();
		searchInput.text = "";
		searchInput.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		searchInput.setPosition(searchPlaceholder.x, searchPlaceholder.y);
		add(searchInput);

		pageInfo = new FlxText(0, 0, FlxG.width);
		pageInfo.text = '< Page ${page} >';
		pageInfo.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		pageInfo.y = FlxG.height - pageInfo.height - 30;
		add(pageInfo);

		var pageTip1 = new FlxText(20, 0, FlxG.width, 'Q - Go to previous page');
		pageTip1.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		pageTip1.y = pageInfo.y;
		pageTip1.alpha = 0.6;
		add(pageTip1);

		var pageTip2 = new FlxText(-20, 0, FlxG.width, 'E - Go to next page');
		pageTip2.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		pageTip2.y = pageInfo.y;
		pageTip2.alpha = pageTip1.alpha;
		add(pageTip2);

		FlxG.sound.music.fadeIn(1, 1, 0.5);

		loadNextPage(true);

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
    }

	override function destroy() {
		super.destroy();

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
	}

	function loadNextPage(?value:Int = 0, ?newSearch:Bool = false) {
		if (page + value < 1) {
			return;
		}

		LoadingScreen.toggle(true);
		loading = true;

		var search = searchInput.text == "" ? null : searchInput.text;

		var newPage = page + value;
		if (search != null && newSearch) {
			newPage = 1;
		}

		GameBanana.searchMods(search, newPage, (mods, err) -> {
			LoadingScreen.toggle(false);
			
			if (destroyed)
				return;
			
			if (err != null) {
				loading = false;
				pageInfo.text = "Error: " + err;
				return;
			}

			page = newPage;
			pageInfo.text = '< Page ${page} >';

			loadMods(mods);
		});
	}

	function changeSelection(value:Int) {
		curSelected += value;

		if (curSelected >= items.length) {
			curSelected = items.length - 1;
		}
		else if (curSelected < 0) {
			curSelected = 0;
		}
	}

    override function update(elapsed:Float) {
        super.update(elapsed);

		if (!inputWait) {
			if (!loading) {
				if (FlxG.mouse.wheel == 1 || FlxG.keys.justPressed.Q) {
					loadNextPage(-1);
				}
				if (FlxG.mouse.wheel == -1 || FlxG.keys.justPressed.E) {
					loadNextPage(1);
				}
				
				if (controls.UI_RIGHT_P) {
					changeSelection(1);
				}
				if (controls.UI_LEFT_P) {
					changeSelection(-1);
				}
				if (controls.UI_UP_P) {
					if (curSelected - 5 < 0) {
						curSelected = -1;
					}
					else {
						changeSelection(-5);
					}
				}
				if (controls.UI_DOWN_P) {
					changeSelection(5);
				}

				if (FlxG.mouse.justMoved) {
					curSelected = -2;
				}

				for (item in items) {
					if (FlxG.mouse.justMoved && FlxG.mouse.overlaps(item.bg)) {
						curSelected = item.ID;
					}

					item.selected = curSelected == item.ID;
				}

				if (FlxG.mouse.justMoved && FlxG.mouse.overlaps(searchBg)) {
					curSelected = -1;
				}

				if (curSelected == -1) {
					searchBg.alpha = 0.8;
				}
				else {
					searchBg.alpha = 0.6;
				}

				if (controls.ACCEPT || FlxG.mouse.justPressed) {
					if (curSelected == -1) {
						inputWait = true;
					}
					else if (curSelected >= 0 && items.length - 1 >= curSelected) {
						if (FlxG.mouse.justPressed) {
							if (FlxG.mouse.overlaps(items.members[curSelected].dlBg)) {
								OnlineMods.downloadMod(items.members[curSelected].mod._sProfileUrl);
							}
							else if (FlxG.mouse.overlaps(items.members[curSelected].linkBg)) {
								RequestState.requestURL(items.members[curSelected].mod._sProfileUrl, "The following button redirects to:");
							}
						}
						else {
							OnlineMods.downloadMod(items.members[curSelected].mod._sProfileUrl);
						}
					}
				}
			}
		}
		else {
			if (FlxG.mouse.justPressed && !FlxG.mouse.overlaps(searchBg)) {
				inputWait = false;
				curSelected = -2;
			}
		}

		searchPlaceholder.visible = searchInput.text.length <= 0;
    }

	function loadMods(mods:Array<GBSub>) {
		items.clear();
		curSelected = 0;

		trace("loading page " + page);

		var i:Int = 0;
		for (mod in mods) {
			if (mod._aRootCategory._sName == "Executables") {
				continue;
			}

			var item = new ModItem(mod);
			item.y = Math.floor(i / 5) * 190;
			item.x = Math.floor(i % 5) * 250;
			item.ID = i;
			items.add(item);

			i++;
		}

		if (i == 0) {
			pageInfo.text = "None mods found!";
		}

		items.screenCenter(X);
		items.y = itemsY;

		loading = false;
	}

	function onKeyDown(e:KeyboardEvent) {
		if (!inputWait) {
			if (controls.BACK) {
				FlxG.sound.music.volume = 1;
				MusicBeatState.switchState(new OnlineState());
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}

			return;
		}

		var key = e.keyCode;

		if (e.charCode == 0) { // non-printable characters crash String.fromCharCode
			return;
		}

		if (key == 46) { // delete
			return;
		}

		if (key == 8) { // bckspc
			searchInput.text = searchInput.text.substring(0, searchInput.text.length - 1);
			return;
		}
		else if (key == 13) { // enter
			inputWait = false;
			if (StringTools.startsWith(searchInput.text, "https://")) {
				OnlineMods.downloadMod(searchInput.text);
				searchInput.text = "";
			}
			else
				loadNextPage(true);
			return;
		}
		else if (key == 27) { // esc
			inputWait = false;
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
			searchInput.text += newText;
		}
	}
}

class ModItem extends FlxSpriteGroup {
	public var mod:GBSub;

	public var bg:FlxSprite;
	public var dlBg:FlxSprite;
	var dl:FlxSprite;
	public var linkBg:FlxSprite;
	var link:FlxSprite;
	var thumb:FlxSprite;

	public var selected = false;

	public function new(mod:GBSub) {
		this.mod = mod;
		super();

		bg = new FlxSprite();
		bg.makeGraphic(220, 170, FlxColor.BLACK);
		bg.alpha = 0.5;
		add(bg);

		thumb = new FlxSprite();
		thumb.clipRect = new FlxRect(0, 0, 220, 125);
		thumb.makeGraphic(mod._aPreviewMedia._aImages[0]._wFile220, mod._aPreviewMedia._aImages[0]._hFile220, FlxColor.BLACK);
		add(thumb);

		loadScreenshot();

		var categoryNameBg = new FlxSprite();
		categoryNameBg.makeGraphic(1, 1, FlxColor.BLACK);
		categoryNameBg.alpha = 0.7;
		add(categoryNameBg);

		var categoryName = new FlxText(5, 5, bg.width, mod._aRootCategory._sName);
		categoryName.setFormat("VCR OSD Mono", 15, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(categoryName);

		categoryNameBg.scale.set(categoryName.textField.textWidth, categoryName.textField.textHeight);
		categoryNameBg.updateHitbox();
		categoryNameBg.setPosition(categoryName.x, categoryName.y);

		var category = new FlxSprite();
		category.visible = false;
		add(category);

		getImage(mod._aRootCategory._sIconUrl, (bytes, err) -> {
			if (!exists)
				return;

			if (err != null)
				return;

			category.loadGraphic(FlxGraphic.fromBitmapData(BitmapData.fromBytes(bytes)));
			category.x = bg.x + bg.width - category.width; // bg.x is needed for some reason
			categoryName.fieldWidth = bg.width - category.width;
			category.visible = true;
		});

		var name = new FlxText(0, thumb.clipRect.height, bg.width, mod._sName);
		name.setFormat("VCR OSD Mono", 15, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(name);

		var detailsBg = new FlxSprite();
		detailsBg.makeGraphic(1, 1, FlxColor.BLACK);
		detailsBg.alpha = 0.7;
		add(detailsBg);

		var like = new FlxSprite();
		like.loadGraphic(Paths.image("like"));
		add(like);

		var likes = new FlxText(0, 0, 0, (mod._nLikeCount == null ? 0 : mod._nLikeCount) + "");
		likes.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(likes);

		detailsBg.scale.set(like.width + 5 + likes.width + 15, likes.height + 10);
		detailsBg.updateHitbox();
		detailsBg.x = bg.width - detailsBg.width - 5;
		detailsBg.y = thumb.clipRect.height - detailsBg.height - 5;

		like.setPosition(detailsBg.x + (15 / 2), detailsBg.y + detailsBg.height / 2 - like.height / 2);
		likes.setPosition(like.x + like.width + 5, detailsBg.y + 5);

		dlBg = new FlxSprite(5);
		dlBg.makeGraphic(1, 1, FlxColor.BLACK);
		dlBg.alpha = 0.6;
		add(dlBg);

		dl = new FlxSprite();
		dl.loadGraphic(Paths.image("dl"));
		add(dl);
		
		dlBg.scale.set(dl.width + 20, dl.height + 20);
		dlBg.updateHitbox();
		dlBg.y = thumb.clipRect.height - dlBg.height - 5;

		dl.x = dlBg.x + 10;
		dl.y = dlBg.y + 10;

		
		linkBg = new FlxSprite(dlBg.x + dlBg.width + 5);
		linkBg.makeGraphic(1, 1, FlxColor.BLACK);
		linkBg.alpha = 0.6;
		add(linkBg);

		link = new FlxSprite();
		link.loadGraphic(Paths.image("gbLink"));
		add(link);

		linkBg.scale.set(link.width + 20, link.height + 20);
		linkBg.updateHitbox();
		linkBg.y = thumb.clipRect.height - linkBg.height - 5;

		link.x = linkBg.x + 10;
		link.y = linkBg.y + 10;
	}
	
	public var curScreenshot = 0;
	var holdTime = 0.;
	var loadingScreenshot = true;
	var prevSelected = false;
	override function update(elapsed) {
		super.update(elapsed);

		dl.visible = selected;
		dlBg.visible = dl.visible;
		link.visible = selected;
		linkBg.visible = link.visible;

		if (!selected || loadingScreenshot)
			holdTime = 0;
		else
			holdTime += elapsed;

		if (!loadingScreenshot) {
			if (holdTime >= 1) {
				curScreenshot++;
				if (curScreenshot >= mod._aPreviewMedia._aImages.length) {
					curScreenshot = 0;
				}

				loadScreenshot();
			}
		}

		if (prevSelected != selected) {
			if (!selected) {
				curScreenshot = 0;
				loadScreenshot();
			}
		}
		
		prevSelected = selected;
	}

	function loadScreenshot() {
		holdTime = 0;
		loadingScreenshot = true;
		if (curScreenshot == 0) {
			getImage(mod._aPreviewMedia._aImages[0]._sBaseUrl + "/" + mod._aPreviewMedia._aImages[0]._sFile220, (bytes, err) -> {
				if (!exists)
					return;

				if (err != null) {
					loadingScreenshot = false;
					return;
				}

				thumb.clipRect = new FlxRect(0, 0, 220, 125);

				thumb.loadGraphic(FlxGraphic.fromBitmapData(BitmapData.fromBytes(bytes), false, null, false));
				if (mod._aPreviewMedia._aImages[0]._hFile220 < thumb.clipRect.height) {
					thumb.setGraphicSize(mod._aPreviewMedia._aImages[0]._wFile220, thumb.clipRect.height);
				}
				else {
					thumb.setGraphicSize(mod._aPreviewMedia._aImages[0]._wFile220, mod._aPreviewMedia._aImages[0]._hFile220);
				}
				thumb.updateHitbox();

				loadingScreenshot = false;
			});
		}
		else {
			getImage(mod._aPreviewMedia._aImages[curScreenshot]._sBaseUrl + "/" + mod._aPreviewMedia._aImages[curScreenshot]._sFile, (bytes, err) -> {
				if (!exists)
					return;
				if (err != null || !selected) {
					loadingScreenshot = false;
					return;
				}

				thumb.clipRect = null;

				thumb.loadGraphic(FlxGraphic.fromBitmapData(BitmapData.fromBytes(bytes), false, null, false));
				thumb.setGraphicSize(220, 125);
				thumb.updateHitbox();

				loadingScreenshot = false;
			});
		}
	}

	public static function getImage(url:String, response:(bytes:Bytes, err:Dynamic) -> Void) {
		Thread.create(() -> {
			var http = new Http(url);

			http.onBytes = function(data) {
				Waiter.put(() -> {
					response(data, null);
				});
			}

			http.onError = function(error) {
				Waiter.put(() -> {
					response(null, error);
				});
			}

			http.request();
		});
	}
}