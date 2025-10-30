package online.network;

import externs.WinAPI;
import haxe.io.Path;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import online.http.HTTPClient;
import haxe.zip.Reader;
import haxe.zip.Entry;
#if sys
import sys.io.File;
#end

class URI
{
	/**
	 * Registers the URI onto the system.
	 * @return If it completed successfully or not.
	 */
	public static function registerURI():Bool
	{
		#if windows
		var uriHandlerPath:String = Path.normalize(lime.system.System.applicationStorageDirectory + 'peo_uri.exe');

		var response:HTTPResponse = new HTTPClient("https://nightly.link/TechnikTil/Psych-Online-URI/workflows/main/main/windowsBuild.zip").request();

		if(response.isFailed())
			return false;

		var responseBytes:Bytes = response.getBytes();

		var zip:List<Entry> = Reader.readZip(new BytesInput(responseBytes));
		if(zip == null || zip.length < 1) return false;

		var uriHandlerBytes:Bytes = Reader.unzip(zip.first());
		File.saveBytes(uriHandlerPath, uriHandlerBytes);

		var regFileContent:String =
		'Windows Registry Editor Version 5.00\n'
		+ '\n'
		+ '[HKEY_CLASSES_ROOT\\psych-online]\n'
		+ '@="URL:psych-online"\n'
		+ '"URL Protocol"=""\n'
		+ '\n'
		+ '[HKEY_CLASSES_ROOT\\psych-online\\shell]\n'
		+ '\n'
		+ '[HKEY_CLASSES_ROOT\\psych-online\\shell\\open]\n'
		+ '\n'
		+ '[HKEY_CLASSES_ROOT\\psych-online\\shell\\open\\command]\n'
		+ '@="\\"${StringTools.replace(uriHandlerPath, '/', '\\\\')}\\" \\"%1\\""'
		+ '\n\n';
		'"\\"%1\\""';

		var tempFile:String = haxe.io.Path.join([Sys.getEnv("TEMP"), 'peo-uri.reg']);
		File.saveContent(tempFile, regFileContent);

		WinAPI.commandAsAdministrator('reg.exe', 'import "${tempFile}"');

		sys.FileSystem.deleteFile(tempFile);
		return true;
		#elseif linux
		// this has NOT been tested at all
		var uriHandlerPath:String = Path.normalize(lime.system.System.applicationStorageDirectory + 'peo_uri');

		var response:HTTPResponse = new HTTPClient("https://nightly.link/TechnikTil/Psych-Online-URI/workflows/main/main/linuxBuild.zip").request();

		if(response.isFailed())
			return false;

		var responseBytes:Bytes = response.getBytes();

		var zip:List<Entry> = Reader.readZip(new BytesInput(responseBytes));
		if(zip == null || zip.length < 1) return false;

		var uriHandlerBytes:Bytes = Reader.unzip(zip.first());

		File.saveBytes(uriHandlerPath, uriHandlerBytes);
		Sys.command('chmod', ['+x', '"${uriHandlerPath}"']);

		var xdgDesktopContent:String =
		'[Desktop Entry]\n'
		+ 'Type=Application\n'
		+ 'Name=Psych Online URI\n'
		+ 'Exec="${uriHandlerPath}" %u\n'
		+ 'StartupNotify=false\n'
		+ 'MimeType=x-scheme-handler/psych-online;';

		var xdgDesktopPath:String = Path.join([Sys.getEnv('HOME'), 'peo-uri.desktop']);
		File.saveContent(xdgDesktopPath, xdgDesktopContent);

		Sys.command('xdg-mime', ['default', 'peo-uri.desktop', 'x-scheme-handler/psych-online']);
		return true;
		#else
		online.gui.Alert.alert('URI Registration is not supported for this platform!', '');
		return false;
		#end
	}

	public static function saveLastLocation():Void
	{
		var uriDataPath:String = Path.normalize(lime.system.System.applicationStorageDirectory + 'peo_uri_data.json');
		var appPath:String = Path.normalize(Sys.programPath());

		var jsonToSave:String = haxe.Json.stringify({
			lastAppDir: appPath
		});

		File.saveContent(uriDataPath, jsonToSave);
	}
}