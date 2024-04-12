package online;

import online.states.RequestState;
import openfl.utils.ByteArray;
import openfl.display.PNGEncoderOptions;
import openfl.geom.Rectangle;
import openfl.display.BitmapData;
import lime.system.System;
import states.ModsMenuState.ModMetadata;
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
	var rootCategory:String;
	var downloadCount:Float;
	var likes:Float;
	var screenshots:Array<GBImage>;
}

typedef GBSub = {
	var _idRow:Float;
	var _sModelName:String;
	var _sName:String;
	var _sProfileUrl:String;
	var _aPreviewMedia:GBPrevMedia;
	var _aRootCategory:GBCategory;
	var _sVersion:String;
	var _aGame:GBGame;
	var _nLikeCount:Null<Float>; // "null cant be used as int!!!" then why does this return null instead of 0
}

typedef GBGame = {
	var _idRow:Float;
}

typedef GBPrevMedia = {
	var _aImages:Array<GBImage>;
}

typedef GBImage = {
	var _sBaseUrl:String;
	var _sFile:String;
	var _sFile220:String; //only on the first
	var _wFile220:Int;
	var _hFile220:Int;
	var _sFile100:String;
}

typedef GBCategory = {
	var _sName:String;
	var _sIconUrl:String;
}

typedef DownloadProp = {
	var _sFile:String;
	var _nFilesize:Float;
	var _sDescription:String;
	var _sAnalysisState:String;
	var _sDownloadUrl:String;
	var _bContainsExe:Bool;
}

typedef AltDownload = {
	var url:String;
	var description:String;
}

typedef DownloadPage = {
	var _bIsTrashed:Bool;
	var _bIsWithheld:Bool;
	var _aFiles:Array<DownloadProp>;
	var _aAlternateFileSources:Array<AltDownload>;
}

class GameBanana {
	public static function searchMods(?search:String, page:Int, ?sortOrder:String = "default", response:(mods:Array<GBSub>, err:Dynamic) -> Void) {
		Thread.run(() -> {
			var http = new Http(
			'https://gamebanana.com/apiv11/Game/8694/Subfeed?_nPage=${page}&_sSort=${sortOrder}&_csvModelInclusions=Mod' + (search != null ? '&_sName=$search' : '')
			);

			http.onData = function(data:String) {
				Waiter.put(() -> {
					var json:Dynamic = Json.parse(data);
					response(cast(json._aRecords), json._sErrorCode != null ? json._sErrorMessage : null);
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

	public static function listCollection(id:String, page:Int, response:(mods:Array<GBSub>, err:Dynamic) -> Void) {
		Thread.run(() -> {
			var http = new Http(
			'https://gamebanana.com/apiv11/Collection/${id}/Items?_nPage=${page}&_nPerpage=15'
			);

			http.onData = function(data:String) {
				Waiter.put(() -> {
					var json:Dynamic = Json.parse(data);
					response(cast(json._aRecords), json._sErrorCode != null ? json._sErrorMessage : null);
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

	public static function getMod(id:String, response:(mod:GBMod, err:Dynamic)->Void, ?threaded:Bool = true) {
		var func = () -> {
			var http = new Http(
			"https://api.gamebanana.com/Core/Item/Data?itemtype=Mod&itemid=" + id + 
			"&fields=name,description,Files().aFiles(),Url().sDownloadUrl(),Game().name,Trash().bIsTrashed(),Withhold().bIsWithheld(),RootCategory().name,downloads,likes,screenshots"
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
					withheld: arr[6],
					rootCategory: arr[7],
					downloadCount: arr[8],
					likes: arr[9],
					screenshots: Json.parse(arr[10])
				}, null);
			}

			http.onError = function(error) {
				response(null, error);
			}

			http.request();
		};
		if (threaded)
			Thread.run(func);
		else
			func();
    }

	public static function getModDownloads(modID:Float, response:(downloads:DownloadPage, err:Dynamic) -> Void) {
		Thread.run(() -> {
			var http = new Http('https://gamebanana.com/apiv11/Mod/$modID/DownloadPage');

			http.onData = function(data:String) {
				Waiter.put(() -> {
					var json:Dynamic = Json.parse(data);
					response(cast(json), json._sErrorCode != null ? json._sErrorMessage : null);
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

	public static function downloadMod(mod:GBMod, ?onSuccess:String->Void) {
        if (mod.trashed || mod.withheld) {
			Alert.alert("Failed to download!", "That mod is deleted!");
			return;
        }

        var daModUrl:String = null;
		var dlFileName:String = null;
		var dlCount:Int = -1;
		for (_download in Reflect.fields(mod.downloads)) {
			var download = Reflect.field(mod.downloads, _download);
			if (FileUtils.isArchiveSupported(download._sFile) /*&& download._bContainsExe == false*/ && download._sClamAvResult == "clean" && download._nDownloadCount >= dlCount) {
				daModUrl = download._sDownloadUrl;
				dlFileName = download._sFile;
				dlCount = download._nDownloadCount;
            }
        }

		if (daModUrl == null) {
			Alert.alert("Failed to download!", "Unsupported file archive type!\n(Only ZIP, TAR, TGZ, RAR archives are supported!)");
			RequestState.requestURL(mod.pageDownload, "The following mod needs to be installed from this source", true);
			return;
		}

		OnlineMods.startDownloadMod(dlFileName, daModUrl, mod, onSuccess);
    }
}