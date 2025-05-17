package online.network;

import haxe.io.Bytes;
import haxe.crypto.Base64;
import haxe.io.Path;
import haxe.Json;
import sys.FileSystem;
import sys.io.File;

@:unreflective
class URIData {
    public static function generateSave() {
		var savePath:String = lime.system.System.applicationStorageDirectory + 'peo_uri_data.json';

		if (!FileSystem.exists(Path.directory(savePath)))
			FileSystem.createDirectory(Path.directory(savePath));

		File.saveContent(savePath, Json.stringify({
			lastAppDir: Path.normalize(lime.system.System.applicationDirectory) + '/' + lime.app.Application.current.meta.get("file") + '.exe'
		}));
	}
}

typedef URIDataStructure = {
	var lastAppDir:String;
}