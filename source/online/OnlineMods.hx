package online;

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
			FlxG.switchState(new SetupMods(needMods));
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

	public static function downloadMod(url:String) {
		if (url == null || url.trim() == "")
			return;

		if (StringTools.startsWith(url, "https://gamebanana.com/mods/")) {
			GameBanana.getMod(url.substring("https://gamebanana.com/mods/".length), (mod, err) -> {
				Waiter.put(() -> {
					if (err != null) {
						Alert.alert("Failed to download!", "For mod: " + url + "\n" + err);
						return;
					}

					GameBanana.downloadMod(mod);
				});
			});
			return;
		}

		OpenURL.open(url, "The following mod needs to be installed manually\nbecause it comes from an untrusted source\ndo you want to open this URL?");
	}
}