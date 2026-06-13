package mobile.io;

import openfl.Assets;
#if sys
import sys.FileSystem as SysFileSystem;
import sys.FileStat;
import sys.io.File as SysFile;
import sys.io.FileInput;
import sys.io.FileOutput;
#end

/**
 * Unified file class that works with both native file access and OpenFL assets.
 * @see https://github.com/Psych-Slice/P-Slice/blob/master/source/mikolka/funkin/custom/NativeFileSystem.hx
 */
class File
{
	inline static function cwd(path:String):String
	{
		/*if (path.startsWith(Sys.getCwd()) || path.startsWith(lime.system.System.applicationStorageDirectory))
			return path;
		else
			return Sys.getCwd() + path;*/
		return path;
	}

	static function openflcwd(path:String):String
	{
		@:privateAccess
		for (library in lime.utils.Assets.libraries.keys())
			if (Assets.exists('$library:$path') && !path.startsWith('$library:'))
				return '$library:$path';

		return path;
	}

	public static function getContent(path:String):Null<String>
	{
		#if sys
		#if linux
		var actualPath:String = cwd(path);
		actualPath = getCaseInsensitivePath(path);
		if (actualPath == null)
			actualPath = path;
		if (SysFileSystem.exists(actualPath))
			return SysFile.getContent(actualPath);
		#else
		if (SysFileSystem.exists(cwd(path)))
			return SysFile.getContent(cwd(path));
		#end
		#end

		if (Assets.exists(openflcwd(path)))
			return Assets.getText(openflcwd(path));

		return null;
	}

	public static function getBytes(path:String):Null<haxe.io.Bytes>
	{
		#if sys
		#if linux
		var actualPath:String = cwd(path);
		actualPath = getCaseInsensitivePath(path);
		if (actualPath == null)
			actualPath = path;
		if (SysFileSystem.exists(actualPath))
			return SysFile.getBytes(actualPath);
		#else
		if (SysFileSystem.exists(cwd(path)))
			return SysFile.getBytes(cwd(path));
		#end
		#end

		if (Assets.exists(openflcwd(path)))
			switch (haxe.io.Path.extension(path).toLowerCase())
			{
				case 'otf' | 'ttf':
					return openfl.utils.ByteArray.fromFile(openflcwd(path));
				default:
					return Assets.getBytes(openflcwd(path));
			}

		return null;
	}

	public static function saveContent(path:String, content:String):Void
	{
		#if sys
		SysFile.saveContent(cwd(path), cwd(content));
		#end
	}

	public static function saveBytes(path:String, bytes:haxe.io.Bytes):Void
	{
		#if sys
		SysFile.saveBytes(cwd(path), bytes);
		#end
	}

	public static function read(path:String, binary:Bool = true):Null<#if sys FileInput #else Dynamic #end>
	{
		#if sys
		#if linux
		var actualPath:String = cwd(path);
		actualPath = getCaseInsensitivePath(path);
		if (actualPath == null)
			actualPath = path;
		return SysFile.read(actualPath, binary);
		#else
		return SysFile.read(cwd(path), binary);
		#end
		#else
		return null;
		#end
	}

	public static function write(path:String, binary:Bool = true):Null<#if sys FileOutput #else Dynamic #end>
	{
		#if sys
		#if linux
		var actualPath:String = cwd(path);
		actualPath = getCaseInsensitivePath(path);
		if (actualPath == null)
			actualPath = path;
		return SysFile.write(actualPath, binary);
		#else
		return SysFile.write(cwd(path), binary);
		#end
		#else
		return null;
		#end
	}

	public static function append(path:String, binary:Bool = true):Null<#if sys FileOutput #else Dynamic #end>
	{
		#if sys
		#if linux
		var actualPath:String = cwd(path);
		actualPath = getCaseInsensitivePath(path);
		if (actualPath == null)
			actualPath = path;
		return SysFile.append(actualPath, binary);
		#else
		return SysFile.append(cwd(path), binary);
		#end
		#else
		return null;
		#end
	}

	public static function update(path:String, binary:Bool = true):Null<#if sys FileOutput #else Dynamic #end>
	{
		#if sys
		#if linux
		var actualPath:String = cwd(path);
		actualPath = getCaseInsensitivePath(path);
		if (actualPath == null)
			actualPath = path;
		return SysFile.update(actualPath, binary);
		#else
		return SysFile.update(cwd(path), binary);
		#end
		#else
		return null;
		#end
	}

	public static function copy(srcPath:String, dstPath:String):Void
	{
		#if sys
		#if linux
		var actualSrc:String = cwd(srcPath);
		actualSrc = getCaseInsensitivePath(actualSrc);
		if (actualSrc == null)
			actualSrc = srcPath;
		SysFile.copy(actualSrc, cwd(dstPath));
		#else
		SysFile.copy(srcPath, cwd(dstPath));
		#end
		#end
	}

	#if (linux && sys)
	static function getCaseInsensitivePath(path:String):String
	{
		if (SysFileSystem.exists(path))
			return path;

		var parts:Array<String> = path.split("/");
		var current:String = Sys.getCwd();

		if (path.charAt(0) == "/")
			current = "/";

		for (part in parts)
		{
			if (part == "")
				continue;

			if (!SysFileSystem.exists(current) || !SysFileSystem.isDirectory(current))
				return null;

			var files:Array<String> = SysFileSystem.readDirectory(current);

			var found:Bool = false;
			for (f in files)
			{
				if (f.toLowerCase() == part.toLowerCase())
				{
					if (current == "/")
						current += f;
					else
						current += "/" + f;
					found = true;
					break;
				}
			}

			if (!found)
				return null;
		}

		return current;
	}
	#end
}