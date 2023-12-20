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
    public function new() {}

	var stream:URLStream;
	var fileStream:FileStream;
	var id:String;
	var gbMod:GBMod;

	static var downloading:Array<String> = [];
	static var downloaders:Array<Downloader> = [];

	public function download(id:String, url:String, callback:(fileName:String)->Void, ?mod:GBMod) {		
		id = idFilter(id);
		if (downloading.contains(id)) {
			Waiter.put(() -> {
				Alert.alert('Downloading failed!', 'Download ' + id + " is already being downloaded!");
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
		var fileName = id + ".dwl";

		fileStream = new FileStream();
		fileStream.open(new File(File.applicationDirectory.nativePath + "/" + fileName), FileMode.WRITE);
        
		var request = new URLRequest(url);
		stream = new URLStream();

		stream.addEventListener(Event.OPEN, (event) -> {
			writeIncoming();
		});
		stream.addEventListener(ProgressEvent.PROGRESS, (event) -> {
			Waiter.put(() -> {
				Alert.alert('Downloading...', id + ': ${FlxMath.roundDecimal(event.bytesLoaded / 1000000, 1)}MB of ${FlxMath.roundDecimal(event.bytesTotal / 1000000, 1)}MB');
            });
			writeIncoming();
        });
		stream.addEventListener(Event.COMPLETE, (event) -> {
			Sys.println('Download $id completed!');
			writeIncoming();
			fileStream.close();
			stream.close();
			callback(fileName);
			downloading.remove(id);
			downloaders.remove(this);
        });
		stream.addEventListener(IOErrorEvent.IO_ERROR, (event) -> {
			Sys.println('Download $id encountered an exception!\n' + event.text);
			cancel();
		});

		try {
			stream.load(request);
		}
		catch (exc) {
			fileStream.close();
			stream.close();
			downloading.remove(id);
			downloaders.remove(this);
		}
    }

    function writeIncoming() {
		if (stream.bytesAvailable > 0) {
			// get incoming bytes
			var fileData:ByteArray = new ByteArray();
			stream.readBytes(fileData, 0, stream.bytesAvailable);
			// write them to the file
			fileStream.writeBytes(fileData, 0, fileData.length);
        }
    }

	public function cancel() {
		Sys.println('Download $id cancelled!');
		fileStream.close();
		stream.close();
		FileSystem.deleteFile(id + ".dwl");
		downloading.remove(id);
		downloaders.remove(this);
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
				filtered += "_";
		}
		return filtered;
	}
}