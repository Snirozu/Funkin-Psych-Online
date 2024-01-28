package online;

import haxe.io.Path;
import sys.FileSystem;

class FileUtils {
	static var supportedArchives = [".zip", ".tar", ".tgz", ".tar.gz",];

	public static function isArchiveSupported(file:String) {
		for (item in supportedArchives) {
			if (StringTools.endsWith(file, item))
				return true;
		}
		return false;
	}

	/**
	 * removes singular files and directories with it's contents
	 */
	public static function removeFiles(path:String) {
		if (FileSystem.isDirectory(path)) {
			for (file in FileSystem.readDirectory(path)) {
				removeFiles(Path.join([path, file]));
			}
			FileSystem.deleteDirectory(path);
		}
		else {
			FileSystem.deleteFile(path);
		}
	}
}