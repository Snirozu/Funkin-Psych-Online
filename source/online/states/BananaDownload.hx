package online.states;

import lime.system.Clipboard;
import openfl.events.KeyboardEvent;
import flixel.math.FlxRect;
import haxe.io.Bytes;
import haxe.Http;
import openfl.display.BitmapData;
import flixel.graphics.FlxGraphic;
import online.GameBanana.GBSub;
import flixel.group.FlxGroup;

class BananaDownload extends MusicBeatState {
	var items:FlxTypedSpriteGroup<ModItem> = new FlxTypedSpriteGroup<ModItem>();
	var itemsY:Int = FlxG.height - (3 * 190) - 50;
	public static var curSelected:Int = 0;
	var page:Int = 1;
	var searchBg:FlxSprite;
	var searchPlaceholder:FlxText;
	var searchInput:InputText;
	var pageInfo:FlxText;
	
	override function create() {
		curSelected = 0;
		
		super.create();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Browsing mods on GameBanana.", null, null, false);
		#end

		GameClient.send("status", "Browsing mods on GameBanana");

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xff46463b;
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.scrollFactor.set(0, 0);
		add(bg);

		var lines:FlxSprite = new FlxSprite().loadGraphic(Paths.image('coolLines'));
		lines.updateHitbox();
		lines.screenCenter();
		lines.antialiasing = ClientPrefs.data.antialiasing;
		lines.scrollFactor.set(0, 0);
		add(lines);

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

		searchInput = new InputText(0, 0, Std.int(searchBg.width - 40), text -> {
			if (StringTools.startsWith(searchInput.text, "https://")) {
				OnlineMods.downloadMod(searchInput.text);
				searchInput.text = "";
			}
			else
				loadNextPage(true);
		});
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
    }

	function loadNextPage(?value:Int = 0, ?newSearch:Bool = false) {
		if (page + value < 1) {
			return;
		}

		LoadingScreen.toggle(true);

		var query = "";
		var order:String = null;
		for (word in searchInput.text.split(" ")) {
			if (word.startsWith("sort:"))
				order = word.substr("sort:".length);
			else
				query += word + " ";
		}
		query = query.trim() == "" ? null : query.trim();
		
		var newPage = page + value;
		if (query != null && newSearch) {
			newPage = 1;
		}

		GameBanana.searchMods(query, newPage, order, (mods, err) -> {
			LoadingScreen.toggle(false);
			
			if (destroyed)
				return;

			if (mods == null)
				err = "Mods not found!";
			
			if (err != null) {
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
		if (!searchInput.hasFocus) {
			if (controls.BACK) {
				FlxG.sound.music.volume = 1;
				FlxG.switchState(() -> GameClient.isConnected() ? new Room() : new OnlineState());
				FlxG.sound.play(Paths.sound('cancelMenu'));
				LoadingScreen.loading = false;
			}

			if (!LoadingScreen.loading) {
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

				if (FlxG.mouse.justMoved || FlxG.mouse.justPressed) {
					curSelected = -2;

					if (FlxG.mouse.overlaps(searchBg)) {
						curSelected = -1;
					}
				}
			}
		}

		searchPlaceholder.visible = searchInput.text.length <= 0;

		super.update(elapsed);

		if (!searchInput.hasFocus && !LoadingScreen.loading) {
			if (curSelected == -1)
				searchBg.alpha = 0.8;
			else
				searchBg.alpha = 0.6;

			if (controls.ACCEPT || FlxG.mouse.justPressed) {
				if (curSelected == -1) {
					searchInput.hasFocus = true;
				}
				else if (curSelected >= 0 && items.length - 1 >= curSelected) {
					if (FlxG.mouse.justPressed) {
						if (FlxG.mouse.overlaps(items.members[curSelected].dlBg)) {
							openModDownloads();
						}
						else if (FlxG.mouse.overlaps(items.members[curSelected].linkBg)) {
							RequestState.requestURL(items.members[curSelected].mod._sProfileUrl, "The following button redirects to:", true);
						}
					}
					else {
						openModDownloads();
					}
				}
			}
		}
    }

	function openModDownloads() {
		if (items.members[curSelected].mod._idRow == 479714) {
			FlxG.openURL('https://www.youtube.com/watch?v=WC_mHIBCHDo');
			return;
		}

		LoadingScreen.toggle(true);
		GameBanana.getModDownloads(items.members[curSelected].mod._idRow, (downloads, err) -> {
			LoadingScreen.toggle(false);

			if (err != null) {
				Alert.alert("Fetching downloads failed!", err);
				return;
			}

			if (downloads._bIsTrashed || downloads._bIsWithheld) {
				Alert.alert("Fetching downloads failed!", "That mod is deleted!");
				return;
			}

			openSubState(new SelectDownloadState(downloads));
		});
	}

	function loadMods(mods:Array<GBSub>) {
		items.clear();
		curSelected = 0;

		trace("loading page " + page);

		var i:Int = 0;
		for (mod in mods) {
			// if (mod._aRootCategory._sName == "Executables") {
			// 	continue;
			// }

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
		thumb.makeGraphic(220, 125, FlxColor.BLACK);
		add(thumb);

		loadScreenshot(0);

		var categoryNameBg = new FlxSprite();
		categoryNameBg.makeGraphic(1, 1, FlxColor.BLACK);
		categoryNameBg.alpha = 0.7;
		categoryNameBg.visible = false;
		add(categoryNameBg);

		var categoryName = new FlxText(5, 5, 0, mod._aRootCategory._sName);
		categoryName.setFormat("VCR OSD Mono", 15, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		categoryName.visible = false;
		add(categoryName);

		var category = new FlxSprite();
		category.visible = false;
		add(category);

		getImage(mod._aRootCategory._sIconUrl, (bytes, err) -> {
			if (!exists)
				return;

			categoryName.visible = true;
			categoryNameBg.visible = true;

			if (err == null) {
				category.loadGraphic(FlxGraphic.fromBitmapData(BitmapData.fromBytes(bytes)));
				category.antialiasing = ClientPrefs.data.antialiasing;
				category.x = bg.x + bg.width - category.width; // bg.x is needed for some reason
				category.visible = true;
				if (categoryName.width > bg.width - 10)
					categoryName.fieldWidth = bg.width - category.frameWidth - 20;
			}
			else if (categoryName.width > bg.width - 10) {
				categoryName.fieldWidth = bg.width - 10;
			}
			categoryNameBg.scale.set(categoryName.width + 5, categoryName.height + 5);
			categoryNameBg.updateHitbox();
			categoryNameBg.setPosition(categoryName.x, categoryName.y);
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

		dl.visible = false;
		dlBg.visible = false;
		link.visible = false;
		linkBg.visible = false;

		link.x = linkBg.x + 10;
		link.y = linkBg.y + 10;
	}
	
	public var curScreenshot = -1;
	var holdTime = 0.;
	var loadingScreenshot = true;
	var prevSelected = false;
	override function update(elapsed) {
		super.update(elapsed);

		if ((FlxG.mouse.justPressed || FlxG.mouse.justMoved) && FlxG.mouse.overlaps(bg)) {
			BananaDownload.curSelected = ID;
		}

		selected = BananaDownload.curSelected == ID;

		if (!ClientPrefs.data.lowQuality) {
			if (FlxG.mouse.overlaps(dlBg))
				dl.scale.set(FlxMath.lerp(dl.scale.x, 1.25, elapsed * 10), FlxMath.lerp(dl.scale.y, 1.25, elapsed * 10));
			else
				dl.scale.set(FlxMath.lerp(dl.scale.x, 1, elapsed * 10), FlxMath.lerp(dl.scale.y, 1, elapsed * 10));

			if (FlxG.mouse.overlaps(linkBg))
				link.scale.set(FlxMath.lerp(link.scale.x, 1.25, elapsed * 10), FlxMath.lerp(link.scale.y, 1.25, elapsed * 10));
			else
				link.scale.set(FlxMath.lerp(link.scale.x, 1, elapsed * 10), FlxMath.lerp(link.scale.y, 1, elapsed * 10));

			if (!selected || loadingScreenshot)
				holdTime = 0;
			else
				holdTime += elapsed;

			if (!loadingScreenshot) {
				if (holdTime >= 1) {
					loadScreenshot(curScreenshot + 1);
				}
			}
		}

		if (prevSelected != selected) {
			dl.visible = selected;
			dlBg.visible = dl.visible;
			link.visible = selected;
			linkBg.visible = link.visible;

			if (!ClientPrefs.data.lowQuality && !selected) {
				loadScreenshot(0);
			}
		}
		
		prevSelected = selected;
	}

	function loadScreenshot(index:Int) {
		if (index >= mod._aPreviewMedia._aImages.length) {
			index = 0;
		}

		holdTime = 0;
		if (index != curScreenshot) {
			loadingScreenshot = true;
			if (index == 0) {
				getImage(mod._aPreviewMedia._aImages[0]._sBaseUrl + "/" + mod._aPreviewMedia._aImages[0]._sFile220, (bytes, err) -> {
					if (!exists)
						return;

					if (err != null) {
						loadingScreenshot = false;
						return;
					}

					thumb.clipRect = new FlxRect(0, 0, 220, 125);

					thumb.loadGraphic(FlxGraphic.fromBitmapData(BitmapData.fromBytes(bytes), false, null, false));
					thumb.antialiasing = ClientPrefs.data.antialiasing;
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
				getImage(mod._aPreviewMedia._aImages[index]._sBaseUrl + "/" + mod._aPreviewMedia._aImages[index]._sFile, (bytes, err) -> {
					if (!exists)
						return;
					if (err != null || !selected) {
						loadingScreenshot = false;
						return;
					}

					thumb.clipRect = null;

					thumb.loadGraphic(FlxGraphic.fromBitmapData(BitmapData.fromBytes(bytes), false, null, false));
					thumb.antialiasing = ClientPrefs.data.antialiasing;
					thumb.setGraphicSize(220, 125);
					thumb.updateHitbox();

					loadingScreenshot = false;
				});
			}
		}
		curScreenshot = index;
	}

	public static function getImage(url:String, response:(bytes:Bytes, err:Dynamic) -> Void) {
		Thread.run(() -> {
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