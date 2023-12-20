package online;

import online.states.OpenURL;
import online.states.Room;
import backend.Song;
import haxe.crypto.Md5;
import haxe.zip.Entry;
import sys.FileSystem;
import sys.io.File;
import haxe.zip.Reader;
import haxe.Http;
import haxe.Json;

typedef GBMod = {
	var _id:String;
	var name:String;
	var description:String;
	var downloads:Dynamic;
	var pageDownload:String;
	var game:String;
	var trashed:Bool;
	var withheld:Bool;
}

typedef DownloadProp = {
	var _sFile:String;
	var _sAnalysisState:String;
	var _sDownloadUrl:String;
	var _bContainsExe:Bool;
}

class GameBanana {
	public static function getMod(id:String, response:(mod:GBMod, err:Dynamic)->Void) {
		var http = new Http(
		"https://api.gamebanana.com/Core/Item/Data?itemtype=Mod&itemid=" + id + 
        "&fields=name,description,Files().aFiles(),Url().sDownloadUrl(),Game().name,Trash().bIsTrashed(),Withhold().bIsWithheld()"
        );

		http.onData = function(data:String) {
			var arr:Array<Dynamic> = Json.parse(data);
            
			response({
				_id: id,
				name: arr[0],
				description: arr[1],
				downloads: arr[2],
				pageDownload: arr[3],
				game: arr[4],
				trashed: arr[5],
				withheld: arr[6]
            }, null);
		}

		http.onError = function(error) {
			response(null, error);
		}

		http.request();
    }

    public static function downloadMod(mod:GBMod) {
        if (mod.trashed || mod.withheld) {
			Alert.alert("Failed to download!", "That mod is deleted!");
			return;
        }

        var daModUrl:String = null;
		for (_download in Reflect.fields(mod.downloads)) {
			var download = Reflect.field(mod.downloads, _download);
			if (StringTools.endsWith(download._sFile, ".zip") && download._bContainsExe == false && download._sClamAvResult == "clean") {
				daModUrl = download._sDownloadUrl;
                break;
            }
        }

        if (daModUrl != null) {
			new Downloader().download(daModUrl, daModUrl, (fileName) -> {
				var file = File.read(fileName, true);
				var zipFiles = Reader.readZip(file);
				file.close();
                var beginFolder = "";
				var parentFolder = Paths.mods();
				for (entry in zipFiles) {
					if (StringTools.endsWith(entry.fileName, "/songs/")) {
						beginFolder = entry.fileName.substring(0, entry.fileName.length - "/songs/".length);
						var splat = beginFolder.split("/");
						parentFolder += splat[splat.length - 1];
                        break;
                    }
				}
				for (entry in zipFiles) {
					_unzip(entry, beginFolder, parentFolder);
				}
				FileSystem.deleteFile(fileName);
				OnlineMods.saveModURL(parentFolder.substring(Paths.mods().length), "https://gamebanana.com/mods/" + mod._id);
				Waiter.put(() -> {
					Alert.alert("Completed the download!", "Downloaded mod: " + parentFolder);

					if (Mods.getModDirectories().contains(GameClient.room.state.modDir)) {
						Mods.currentModDirectory = GameClient.room.state.modDir;
						GameClient.send("verifyChart", Md5.encode(Song.loadRawSong(GameClient.room.state.song, GameClient.room.state.folder)));
					}
				});
            }, mod);
		}
        else {
			Alert.alert("Failed to download!", "Unsupported file archive type!\n(Only ZIP archives are supported!)");
			OpenURL.open(mod.pageDownload, "The following mod needs to be installed from this source");
            return;
        }
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