package online;

import backend.WeekData;
import haxe.io.Path;
import online.states.RequestState;
import openfl.net.URLRequestHeader;
import haxe.Http;
import online.GameBanana.GBMod;
import openfl.display.PNGEncoderOptions;
import haxe.Json;
import openfl.geom.Rectangle;
import openfl.utils.ByteArray;
import openfl.display.BitmapData;
import lime.system.System;
import haxe.zip.Reader;
import haxe.zip.Entry;
import online.states.SetupMods;
import sys.io.File;
import sys.FileSystem;

class OnlineMods {

	public static function checkMods() {
		var needMods:Array<String> = [];
		for (mod in Mods.getModDirectories()) {
			if (!FileSystem.exists(Paths.mods(mod + "/mod_url.txt"))) {
				needMods.push(mod);
			}
		}

		if (needMods.length > 0) {
			FlxG.switchState(() -> new SetupMods(needMods, false));
			return true;
		}
		return false;
	}

	public static function getModURL(mod:String) {
		if (!FileSystem.exists(Paths.mods(mod + "/mod_url.txt")) || StringTools.trim(File.getContent(Paths.mods(mod + "/mod_url.txt"))) == "") {
			return null;
		}

		return StringTools.trim(File.getContent(Paths.mods(mod + "/mod_url.txt")));
	}

	public static function saveModURL(mod:String, url:String) {
		File.saveContent(Paths.mods(mod + "/mod_url.txt"), url);
	}

	public static function downloadMod(url:String, ?onSuccess:String->Void) {
		if (url == null || url.trim() == "")
			return;

		if (StringTools.startsWith(url, "https://gamebanana.com/mods/")) {
			LoadingScreen.toggle(true);
			GameBanana.getMod(url.substring("https://gamebanana.com/mods/".length), (mod, err) -> {
				Waiter.put(() -> {
					LoadingScreen.toggle(false);
					if (err != null) {
						Alert.alert("Failed to download!", "For mod: " + url + "\n" + err);
						return;
					}

					GameBanana.downloadMod(mod, onSuccess);
				});
			});
			return;
		}

		if (StringTools.startsWith(url, "https://drive.google.com/file/d/")) {
			URLScraper.downloadFromGDrive(url, onSuccess);
			return;
		}

		if (StringTools.startsWith(url, "https://drive.google.com/drive/folders/")) {
			Alert.alert("Mod download failed!", "Can't download GDrive folders!");
			return;
		}

		if (StringTools.startsWith(url, "https://www.mediafire.com/file/")) {
			URLScraper.downloadFromMediaFire(url, onSuccess);
			return;
		}

		RequestState.requestDownload(url, "Do you want to download this mod?", onSuccess);
	}

	static final vanillaSongs:Array<String> = [
		'tutorial',
		'bopeebo', 'fresh', 'dadbattle',
		'spookeez', 'south', "monster",
		'pico', 'philly', "blammed",
		'satin-panties', "high", "milf",
		'cocoa', 'eggnog', 'winter-horrorland',
		'senpai', 'roses', 'thorns',
		'ugh', 'guns', 'stress'
		//OTHER SHIT
		,'dad-battle', 'philly-nice', 'test', 'smash', 'ridge'
	];

	@:unreflective
	public static function startDownloadMod(fileName:String, modURL:String, ?gbMod:GBMod, ?onSuccess:String->Void, ?headers:Map<String, String>, ?ogURL:String) {
		new Downloader(fileName, ogURL ?? modURL, modURL, (fileName, downloader) -> {
			installMod(fileName, downloader, downloader.originURL, gbMod, onSuccess);
		}, gbMod, headers, ogURL);
	}

	//gbMod only works if the url is a mod page url not the direct download one
	public static function installMod(fileName:String, ?downloader:Downloader, ?modURL:String, ?gbMod:GBMod, ?onSuccess:String->Void) {
		fileName = Path.normalize(fileName); // I HATE WINDOWS PATH FORMAT AAAAAAAAAAAAAA (C:/ is cool though, JUST INVERT THESE SLASHES PLEASE)
		var _fileNameSplit = fileName.split("/");
		var swagFileName = _fileNameSplit[_fileNameSplit.length - 1].split(".")[0];
		var file = File.read(fileName, true);
		var zipFiles:List<Entry>;
		try {
			zipFiles = Reader.readZip(file);
		} 
		catch (exc) {
			trace(exc);
			file.close();
			Waiter.put(() -> {
				Alert.alert("Mod's data is corrupted or invalid!");
			});
			return;
		}
		file.close();
		var beginFolder = null; // the folder inside the archive to extract
		var parentFolder = Paths.mods(); // the destination mod path
		var ignoreRest = false;
		var fileSize = 0.;
		var dataSize = 0.;
		var isExecutable = false;
		for (entry in zipFiles) {
			fileSize += entry.fileSize;
			dataSize += entry.dataSize;

			if (entry.fileName.endsWith(".exe"))
				isExecutable = true;

			if (!ignoreRest) {
				var pathSplit = entry.fileName.split("/");

				var suppModPath = pathSplit[pathSplit.length - 3] ?? "";
				var suppModFolder = pathSplit[pathSplit.length - 2] ?? "";

				var removeCount = 
					suppModFolder.length == 0 ? 0 : 1 + 
					entry.fileName.length == 0 ? 0 : 1
				;

				if (Mods.ignoreModFolders.contains(suppModFolder)) {
					beginFolder = 
						entry.fileName // something/mod_name/characters/ or something/mod_name/assets/characters/ (because assets always go first)
						.substring(0, entry.fileName.length - (
							suppModPath == "assets" ?
								suppModFolder.length + suppModPath.length + removeCount + (suppModPath.length == 0 ? 0 : 1)
								:
								suppModFolder.length + removeCount
							)
						)
					;

					if (beginFolder == "assets/" || beginFolder == "mods/") {
						beginFolder = "";
					}

					var splat = beginFolder.split("/");
					if (splat[splat.length - 1] == "bin" || splat[splat.length - 1] == "mods" || splat[splat.length - 1].trim() == "")
						parentFolder += (gbMod != null ? gbMod._id : swagFileName);
					else
						if (splat[splat.length - 1] == "assets")
							parentFolder += splat[splat.length - 2] ?? (gbMod != null ? gbMod._id : swagFileName);
						else
							parentFolder += splat[splat.length - 1] ?? (gbMod != null ? gbMod._id : swagFileName);
					parentFolder += "/"; //dont ask
					ignoreRest = true;
				}
			}
		}
		if (Math.min(fileSize, dataSize) < 0 || Math.max(fileSize, dataSize) >= 3000000000) {
			Waiter.put(() -> {
				Alert.alert("Downloading Cancelled",
					'Mod\'s archive file is WAY too big!\n${FlxMath.roundDecimal(Math.max(fileSize, dataSize) / 1000000000, 4)}GB');
			});
			return;
		}
		if (beginFolder == null) {
			if (downloader != null)
				System.openFile(downloader.tryRenameFile());
			Waiter.put(() -> {
				Alert.alert("Mod data not found inside of the archive!");
			});
			return;
		}

		//Sys.println('found data in archive: "${beginFolder}", to: "${parentFolder}"');

		var modName = FileUtils.formatFile(parentFolder.substring(Paths.mods().length, parentFolder.length - 1));

		if (FileSystem.exists(Paths.mods(modName))) {
			try {
				FileUtils.removeFiles(Paths.mods(modName));
			}
			catch (exc) {
				Waiter.put(() -> {
					Alert.alert("Installation Error!", "It seems this mod directory is already being accessed\nby the game or another program!\n\nPlease try again by re-opening the game!");
				});
				return;
			}
		}

		for (entry in zipFiles) {
			_unzip(entry, beginFolder, parentFolder);
		}

		if ((gbMod != null ? gbMod.rootCategory == "Skins" : false) && !FileSystem.exists(Paths.mods(modName + '/pack.json'))) {
			var isLegacy = false;
			if (FileSystem.exists(Paths.mods(modName + '/images/BOYFRIEND.png'))) {
				Sys.println("Legacy mod detected! (Converting)");

				FileSystem.createDirectory(Paths.mods(modName + '/images/characters/'));
				FileSystem.rename(Paths.mods(modName + '/images/BOYFRIEND.png'), Paths.mods(modName + '/images/characters/BOYFRIEND.png'));
				if (FileSystem.exists(Paths.mods(modName + '/images/BOYFRIEND.xml')))
					FileSystem.rename(Paths.mods(modName + '/images/BOYFRIEND.xml'), Paths.mods(modName + '/images/characters/BOYFRIEND.xml'));

				if (!FileSystem.exists(Paths.mods(modName + '/images/icons/icon-bf.png'))
					&& FileSystem.exists(Paths.mods(modName + '/images/iconGrid.png'))) {
					FileSystem.createDirectory(Paths.mods(modName + '/images/icons/'));
					var iconGrid = BitmapData.fromBytes(File.getBytes(Paths.mods(modName + '/images/iconGrid.png')));
					var byteArray:ByteArray = new ByteArray();
					iconGrid.encode(new Rectangle(0, 0, 300, 150), new PNGEncoderOptions(), byteArray);
					File.saveBytes(Paths.mods(modName + '/images/icons/icon-bf.png'), byteArray);
				}

				isLegacy = true;
			}

			File.saveContent(Paths.mods(modName + '/pack.json'), Json.stringify({
				name: (gbMod != null ? gbMod.name : modName),
				description: (gbMod != null ? gbMod.pageDownload : ""),
				runsGlobally: isLegacy
			}));
		}
		else if (/*(gbMod != null ? gbMod.rootCategory == "Executables" : */isExecutable) { // sometimes dum dum people put their non-exe mods to that section
			trace("Executable mod found! Converting...");
			for (file in FileSystem.readDirectory(Paths.mods(modName))) {
				if (file != "assets" && file != "mods")
					FileUtils.removeFiles(Paths.mods(modName + "/" + file));
			}

			if (FileSystem.exists(Paths.mods(modName + '/mods/pack.json')))
				FileSystem.deleteFile(Paths.mods(modName + '/mods/pack.json'));

			if (FileSystem.exists(Paths.mods(modName + '/mods'))) {
				for (file in FileSystem.readDirectory(Paths.mods(modName + '/mods'))) {
					if (FileSystem.isDirectory(Path.join([Paths.mods(modName + '/mods'), file]))
						&& !Mods.ignoreModFolders.contains(file)) {
						FileUtils.cut(Path.join([Paths.mods(modName + '/mods'), file]), Paths.mods(modName + "/"));
					}
				}

				FileUtils.cut(Paths.mods(modName + '/mods'), Paths.mods(modName + "/"));
			}

			if (FileSystem.exists(Paths.mods(modName + '/assets')))
				FileUtils.cut(Paths.mods(modName + '/assets'), Paths.mods(modName + "/"));

			if (FileSystem.exists(Paths.mods(modName + '/shared')))
				FileUtils.cut(Paths.mods(modName + '/shared'), Paths.mods(modName + "/"));

			if (FileSystem.exists(Paths.mods(modName + '/data/songData'))) // special for mario madness hehe
				FileUtils.cut(Paths.mods(modName + '/data/songData'), Paths.mods(modName + "/data/"));

			// exclude alphabets because they change like every psych engine version so they cause bugs
			if (FileSystem.exists(Paths.mods(modName + "/images/alphabet.png")) || FileSystem.exists(Paths.mods(modName + "/images/alphabet.xml"))) {
				FileSystem.deleteFile(Paths.mods(modName + "/images/alphabet.png"));
				FileSystem.deleteFile(Paths.mods(modName + "/images/alphabet.xml"));
			}

			var songsToAdd = [];
			var diffsToAdd = [];
			// for (file in FileSystem.readDirectory(Paths.mods(modName + "/songs"))) {
			// 	if (FileSystem.isDirectory(Path.join([Paths.mods(modName + "/songs"), file]))) {
			// 		songsToAdd.push(file);
			// 	}
			// }
			FileUtils.forEachFile(Paths.mods(modName + "/data/"), (path) -> {
				try {
					if (path.endsWith(".json")) {
						var spath = path.split("/");
						var songName = formatSongName(spath[spath.length - 2]);
						if (!formatSongName(spath[spath.length - 1]).startsWith(songName) || vanillaSongs.contains(songName.toLowerCase()))
							return;

						var preDiff = spath[spath.length - 1].substr(songName.length + 1);
						preDiff = preDiff.substring(0, preDiff.length - ".json".length);
						if (preDiff.trim() == "")
							preDiff = "Normal";

						if (!songsToAdd.contains(songName))
							songsToAdd.push(songName);
						if (!diffsToAdd.contains(preDiff))
							diffsToAdd.push(preDiff);
					}
				}
				catch (exc) {
					Sys.println("failed to include a song " + exc);
				}
			});
			var _normalIndex = -1;
			if ((_normalIndex = diffsToAdd.indexOf("normal")) != -1) {
				diffsToAdd[_normalIndex] = "Normal";
			}

			if (!FileSystem.exists(Paths.mods(modName + "/weeks/"))) {
				FileSystem.createDirectory(Paths.mods(modName + "/weeks/"));
			}
			
			FileUtils.forEachFile(Paths.mods(modName + "/weeks/"), (path) -> {
				try {
					if (path.endsWith(".json")) {
						var json = Json.parse(File.getContent(path));
						var songs:Array<Array<Dynamic>> = json.songs;
						for (song in songs) {
							songsToAdd.remove(formatSongName(song[0]));
						}
					}
				}
				catch (exc) {}
			});

			FileUtils.readAndSave(Paths.mods(modName + "/weeks/auto_gen_week_" + modName + ".json"), text -> {
				var data:WeekFile = WeekData.createWeekFile();
				data.hideStoryMode = true;
				data.difficulties = diffsToAdd.join(", ");
				data.songs = [];

				for (song in songsToAdd) {
					data.songs.push([
						song,
						'bf',
						[146, 113, 253]
					]);
				}

				return Json.stringify(data);
			});
		}

		if (!FileSystem.exists(Paths.mods(modName + '/pack.json')))
			File.saveContent(Paths.mods(modName + '/pack.json'), Json.stringify({
				name: (gbMod != null ? gbMod.name : modName),
				description: (gbMod != null ? gbMod.pageDownload : ""),
				runsGlobally: false
			}));

		//var modLink = (gbMod != null ? "https://gamebanana.com/mods/" + gbMod._id : modURL);
		var modLink = modURL;
		OnlineMods.saveModURL(modName, modLink);

		Waiter.put(() -> {
			Alert.alert("Mod Installation Successful!", "Downloaded mod: " + modName + "\nFrom: " + (modLink == null ? "Local Storage" : modLink));
			if (onSuccess != null)
				onSuccess(modName);

			if (modLink == null && !(FlxG.state is PlayState) && checkMods()) {
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
			}
		});
	}

	private static function _unzip(entry:Entry, begins:String, newParent:String) {
		if (!StringTools.startsWith(entry.fileName, begins) || entry.fileName.endsWith("/")) {
			return;
		}

		if (!FileSystem.exists(Path.directory(Path.join([newParent, entry.fileName.substring(begins.length)])))) {
			FileSystem.createDirectory(Path.join([newParent, Path.directory(entry.fileName).substring(begins.length)]));
		}
		File.saveBytes(Path.join([newParent, entry.fileName.substring(begins.length)]), Reader.unzip(entry));
	}

	public static function formatSongName(song:String) {
		return song.trim().replace(" ", "-").toLowerCase();
	}
}