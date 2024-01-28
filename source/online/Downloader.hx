package online;

import online.GameBanana.GBMod;
import sys.FileSystem;
import openfl.events.IOErrorEvent;
import openfl.filesystem.FileMode;
import openfl.filesystem.File;
import openfl.filesystem.FileStream;
import openfl.utils.ByteArray;
import openfl.events.ProgressEvent;
import openfl.net.URLStream;
import openfl.net.URLRequest;
import openfl.events.Event;

class Downloader {
	var stream:URLStream;
	var fileStream:FileStream;
	var id:String;
	var fileName:String;
	var gbMod:GBMod;

	var downloadPath:String;
	static var downloadDir:String = File.applicationDirectory.nativePath + "/downloads/";

	var alert:DownloadAlert;

	static var downloading:Array<String> = [];
	static var downloaders:Array<Downloader> = [];
	
	public function new(fileName:String, id:String, url:String, callback:(fileName:String, downloader:Downloader) -> Void, ?mod:GBMod) {
		this.fileName = idFilter(fileName);
		id = idFilter(id);
		if (downloading.contains(id)) {
			// Waiter.put(() -> {
			// 	Alert.alert('Downloading failed!', 'Download ' + id + " is already being downloaded!");
			// });
			return;
		}
		if (downloading.length >= 6) {
			Waiter.put(() -> {
				Alert.alert('Downloading failed!', 'Too many files are downloading right now! (Max 6)');
			});
			return;
		}
		this.gbMod = mod;
		if (ChatBox.instance != null && gbMod != null) {
			ChatBox.instance.addMessage("Starting the download of " + gbMod.name + " from: " + url);
		}
		this.id = id;
		downloaders.push(this);
		downloading.push(id);
		alert = new DownloadAlert(id);
		checkCreateDlDir();
		downloadPath = downloadDir + id + ".dwl";
		fileStream = new FileStream();
		fileStream.open(new File(downloadPath), FileMode.WRITE);

		var request = new URLRequest(url);
		stream = new URLStream();

		stream.addEventListener(Event.OPEN, (event) -> {
			writeIncoming();
		});
		stream.addEventListener(ProgressEvent.PROGRESS, (event) -> {
			Waiter.put(() -> {
				alert.updateProgress(event.bytesLoaded, event.bytesTotal);
			});
			writeIncoming();
		});
		stream.addEventListener(Event.COMPLETE, (event) -> {
			Sys.println('Download $id completed!');
			writeIncoming();
			fileStream.close();
			stream.close();
			callback(downloadPath, this);
			deleteTempFile();
			downloading.remove(id);
			downloaders.remove(this);
			alert.destroy();
		});
		stream.addEventListener(IOErrorEvent.IO_ERROR, (event) -> {
			Waiter.put(() -> {
				Alert.alert('Downloading failed!', id + ': ' + event.text);
			});
			Sys.println('Download $id encountered an exception!\n' + event.text);
			cancel();
		});

		try {
			stream.load(request);
		}
		catch (exc) {
			cancel();
		}
	}

	public static function checkCreateDlDir() {
		if (FileSystem.exists(downloadDir)) {
			FileSystem.createDirectory(downloadDir);
		}
	}

	public static function checkDeleteDlDir() {
		if (FileSystem.exists(downloadDir)) {
			FileUtils.removeFiles(downloadDir);
		}
	}

	public function tryRenameFile():String {
		if (FileSystem.exists(downloadPath)) {
			if (FileSystem.exists(downloadDir + fileName))
				FileSystem.deleteFile(downloadDir + fileName);
			FileSystem.rename(downloadPath, downloadDir + fileName);
		}
		return downloadDir + fileName;
	}

	function deleteTempFile() {
		if (FileSystem.exists(downloadPath)) {
			FileSystem.deleteFile(downloadPath);
		}
	}

    function writeIncoming() {
		if (stream.bytesAvailable > 0) {
			// get incoming bytes
			var fileData:ByteArray = new ByteArray();
			stream.readBytes(fileData, 0, stream.bytesAvailable);
			// write them to the file (doesn't do that, im studpi)
			fileStream.writeBytes(fileData, 0, fileData.length);
        }
    }

	public function cancel() {
		Sys.println('Download $id cancelled!');
		fileStream.close();
		stream.close();
		deleteTempFile();
		downloading.remove(id);
		downloaders.remove(this);
		alert.destroy();
	}

	public static function cancelAll() {
		Sys.println("Cancelling " + downloaders.length + " downloads...");
		for (downloader in downloaders) {
			if (downloader != null)
				downloader.cancel();
		}
	}

	static function isNumber(char:Int) {
		return char >= 48 && char <= 57; // 0-9
	}

	static function isLetter(char:Int) {
		return (char >= 65 && char <= 90) || /* A-Z */ (char >= 97 && char <= 122); // a-z
	}
	
	public static function idFilter(id:String):String {
		var filtered = "";
		var i = -1;
		while (++i < id.length) {
			var char = id.charCodeAt(i);
			if (isNumber(char) || isLetter(char))
				filtered += id.charAt(i);
			else
				filtered += "-";
		}
		return filtered;
	}
}