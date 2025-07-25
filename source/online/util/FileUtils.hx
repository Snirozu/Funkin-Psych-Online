package online.util;

import sys.io.File;
import haxe.io.Path;
import sys.FileSystem;

// can haxe have useful classes like in java please this language is BORING AND UNNERVING
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

	/**
	 * copies singular files and directories with it's contents
	 */
	public static function copyFiles(from:String, to:String) {
		if (!FileSystem.exists(Path.directory(to)))
			FileSystem.createDirectory(Path.directory(to));
		
		if (FileSystem.isDirectory(from)) {
			for (file in FileSystem.readDirectory(from)) {
				copyFiles(Path.join([from, file]), Path.join([to, file]));
			}
		}
		else {
			File.copy(from, to);
		}
	}

	/**
	 * copies files and deletes the origin path
	 */
	public static function cut(from:String, to:String) {
		from = Path.normalize(from);
		to = Path.normalize(to);

		copyFiles(from, to);
		removeFiles(from);
	}

	public static function forEachFile(path:String, callback:(path:String)->Void) {
		if (FileSystem.isDirectory(path)) {
			for (file in FileSystem.readDirectory(path)) {
				forEachFile(Path.join([path, file]), callback);
			}
		}
		else {
			callback(path);
		}
	}

	public static function readAndSave(path:String, callback:(contents:String)->String) {
		File.saveContent(path, callback(FileSystem.exists(path) ? File.getContent(path) : null));
	}

	static final illegalCharacters = ~/[\/|\\|?|*|:|\||"|<|>|.]/;

	/**
	 * Filters characters that are invalid to a file name
	 */
	public static function formatFile(file:String, ?ignoreExtension:Bool = false):String {
		var filtered = "";
		var i = -1;
		while (++i < file.length) {
			var char = file.charAt(i);
			if ((ignoreExtension && char == ".") || !illegalCharacters.match(char))
				filtered += char;
		}
		return filtered;
	}

	/**
	 * Safe way to join filesystem files/directories (by one item at a time) by filtering invalid characters using `formatFile`
	 */
	public static function joinFiles(paths:Array<String>):String {
		return Path.join([for (path in paths) formatFile(path, true)]);
	}

	public static function joinNativePath(paths:Array<String>):String {
		return Path.join(paths).replace('/', #if windows '\\' #else '/' #end);
	}
}