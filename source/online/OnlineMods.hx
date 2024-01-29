package online;

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
import online.states.OpenURL;
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
			MusicBeatState.switchState(new SetupMods(needMods));
		}
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

		OpenURL.open(url, "Do you want to download this mod?", true, onSuccess);
	}

	@:unreflective
	public static function startDownloadMod(fileName:String, modURL:String, ?gbMod:GBMod, ?onSuccess:String->Void) {
		new Downloader(fileName, modURL, modURL, (fileName, downloader) -> {
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
			var beginFolder = null;
			var parentFolder = Paths.mods();
			var ignoreRest = false;
			var fileSize = 0;
			var dataSize = 0;
			for (entry in zipFiles) {
				fileSize += entry.fileSize;
				dataSize += entry.dataSize;
				if (!ignoreRest) {
					var entryPathSplit = entry.fileName.split("/");
					if (Mods.ignoreModFolders.contains(entryPathSplit[entryPathSplit.length - 2])) {
						// beginFolder = entry.fileName.substring(0, entry.fileName.length - "/songs/".length);
						beginFolder = entry.fileName.substring(0, entry.fileName.length - (entryPathSplit[entryPathSplit.length - 2].length + 2));
						var splat = beginFolder.split("/");
						if (splat[splat.length - 1] == "mods" || splat[splat.length - 1].trim() == "")
							parentFolder += (gbMod != null ? gbMod._id : swagFileName) + "/";
						else
							parentFolder += splat[splat.length - 1];
						ignoreRest = true;
					}
				}
			}
			if (Math.min(fileSize, dataSize) < 0 || Math.max(fileSize, dataSize) >= 3000000000) {
				Waiter.put(() -> {
					Alert.alert("Downloading Cancelled", 'Mod\'s archive file is WAY too big!\n${FlxMath.roundDecimal(Math.max(fileSize, dataSize) / 1000000000, 4)}GB');
				});
				return;
			}
			if (beginFolder == null) {
				System.openFile(downloader.tryRenameFile());
				Waiter.put(() -> {
					Alert.alert("Mod data not found inside of the archive!");
				});
				return;
			}

			var modName = parentFolder.substring(Paths.mods().length);

			if (FileSystem.exists(Paths.mods(modName))) {
				FileUtils.removeFiles(Paths.mods(modName));
			}

			for (entry in zipFiles) {
				_unzip(entry, beginFolder, parentFolder);
			}

			if ((gbMod != null ? gbMod.rootCategory == "Skins" : true) && !FileSystem.exists(Paths.mods(modName + '/pack.json'))) {
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
					name: (gbMod != null ? gbMod.name : swagFileName),
					description: (gbMod != null ? gbMod.pageDownload : ""),
					runsGlobally: isLegacy
				}));
			}
			OnlineMods.saveModURL(modName, (gbMod != null ? "https://gamebanana.com/mods/" + gbMod._id : modURL));

			Waiter.put(() -> {
				Alert.alert("Completed the download!", "Downloaded mod: " + parentFolder);
				if (onSuccess != null)
					onSuccess(beginFolder);
			});
		}, gbMod);
	}

	private static function _unzip(entry:Entry, begins:String, newParent:String) {
		if (!StringTools.startsWith(entry.fileName, begins)) {
			return;
		}

		if (entry.fileName.endsWith("/")) {
			_unzipFolder(entry, begins, newParent);
		}
		else {
			_unzipFile(entry, begins, newParent);
		}
	}

	private static function _unzipFolder(entry:Entry, begins:String, newParent:String) {
		FileSystem.createDirectory(newParent + entry.fileName.substring(begins.length, entry.fileName.length));
	}

	private static function _unzipFile(entry:Entry, begins:String, newParent:String) {
		File.saveBytes(newParent + entry.fileName.substring(begins.length, entry.fileName.length), Reader.unzip(entry));
	}
}