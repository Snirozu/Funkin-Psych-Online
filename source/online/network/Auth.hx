package online.network;

import haxe.io.Bytes;
import haxe.crypto.Base64;
import haxe.io.Path;
import haxe.Json;
import sys.FileSystem;
import sys.io.File;

@:unreflective
class Auth {
	public static var authID:String = null;
	public static var authToken:String = null;
    private static var savePath:String;
	private static var saveData:AuthData;

	public static function getAuthHeader(?authID:String, ?authToken:String) {
		return "Basic " + Base64.encode(Bytes.ofString((authID ?? Auth.authID) + ":" + (authToken ?? Auth.authToken)));
	}

    public static function load() {		
		savePath = lime.system.System.applicationStorageDirectory + 'peo_auth.json';

		//migrate old path
		var legacyPath = Path.normalize(savePath).replace(
			FlxG.stage.application.meta.get('company') + '/' + FlxG.stage.application.meta.get('file')
			, 'ShadowMario/PsychEngine');
		if (FileSystem.exists(legacyPath)) {
			File.saveContent(savePath, File.getContent(legacyPath));
			FileSystem.deleteFile(legacyPath);
			trace('migrated auth data');
		}

		if (!FileSystem.exists(savePath))
			generateSave();

		try {
			saveData = Json.parse(File.getContent(savePath));
		} catch(e) {
			trace("Couldn't load peo_auth.json! More info: " + e);
			generateSave();
			saveData = {
				id: null,
				token: null
			};
		}

        //FileSystem.deleteFile(savePath); // maybe not a good idea?

		authID = saveData.id;
		authToken = saveData.token;
        
        // move from old save data
		if (authID == null && authToken == null && FlxG.save.data.networkAuthID != null && FlxG.save.data.networkAuthToken != null) {
            trace("Moved credentials from the old save data!");
			save(FlxG.save.data.networkAuthID, FlxG.save.data.networkAuthToken);
			FlxG.save.data.networkAuthID = null;
			FlxG.save.data.networkAuthToken = null;
			FlxG.save.flush();
        }
    }

	public static function generateSave() {
		if (!FileSystem.exists(Path.directory(savePath)))
			FileSystem.createDirectory(Path.directory(savePath));

		File.saveContent(savePath, Json.stringify({
            id: null,
            token: null
        }));
	}

    public static function save(id:String, token:String) {
		saveData.id = authID = id;
		saveData.token = authToken = token;

		if ((saveData.id == null || saveData.token == null) && FileSystem.exists(savePath))
			FileSystem.deleteFile(savePath);
    }

	public static function saveClose() {
		//don't mind me adding it here
		if (online.gui.sidebar.tabs.HostServerTab.process != null)
			online.gui.sidebar.tabs.HostServerTab.stopServer();

		if (saveData.id == null || saveData.token == null) {
			saveData = {
				id: authID,
				token: authToken,
			}
		}
		if (saveData.id != null && saveData.token != null) {
			File.saveContent(savePath, Json.stringify(saveData));
			trace("Saved Auth Credentials...");
		}
        Sys.exit(1);
	}
}

typedef AuthData = {
	var id:String;
	var token:String;
} 