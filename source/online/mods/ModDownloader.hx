package online.mods;

import haxe.Exception;
import sys.FileSystem;
import online.mods.GameBanana;
import online.http.HTTPClient;
import sys.io.File;

class ModDownloader {
	public static var downloaders:Array<ModDownloader> = [];
	public static var failed:Array<String> = [];

	public var client:HTTPClient;
	public var alert:DownloadAlert;

	public var status(default, set):DownloaderStatus;
	function set_status(v) {
		if (onStatus != null)
			onStatus(v);
		return status = v;
	}
	public var onStatus:DownloaderStatus->Void;

	static var downloadDir:String = openfl.filesystem.File.applicationDirectory.nativePath + "/downloads/";
	var downloadPath:String;
	var id:String;
	public var url:String;

	public function new(fileName:String, modURL:String, ?gbMod:GBMod, ?onSuccess:String->Void, ?headers:Map<String, String>, ?ogURL:String) {
		url = ogURL ?? modURL;
		id = FileUtils.formatFile(url);
		downloadPath = downloadDir + id + ".dwl";
		fileName = FileUtils.formatFile(fileName);

		for (down in downloaders) {
			if (down.id == id)
				return;
		}

		if (downloaders.length >= 6) {
			Waiter.put(() -> {
				Alert.alert('Downloading failed!', 'Too many files are downloading right now! (Max 6)');
			});
			return;
		}

		if (!FileSystem.exists(downloadDir)) {
			FileSystem.createDirectory(downloadDir);
		}

		client = new HTTPClient(modURL);
		alert = new DownloadAlert(url);

		client.onStatus = v -> {
			switch (v) {
				case CONNECTING:
					status = CONNECTING;
				case READING_HEADERS:
					status = READING_HEADERS;
				case READING_BODY:
					status = READING_BODY;
					if (!isMediaTypeAllowed(client.response.headers.get("content-type"))) {
						client.cancel();
						Waiter.put(() -> {
							Alert.alert('Downloading failed!', client.response.headers.get("content-type") + " may be invalid or unsupported file type!");
							RequestSubstate.requestURL(url, "The following mod needs to be installed from this source", true);
						});
					}
				case COMPLETED:
					status = DOWNLOADED;
				case FAILED(exc):
					status = FAILED(exc);
					failed.push(modURL);
			}
		};

		downloaders.push(this);
		
		Thread.run(() -> {
			try {
				client.request({
					output: File.append(downloadPath, true),
					headers: headers
				});
			} 
			catch (exc) {
				if (!client.cancelRequested) {
					Waiter.put(() -> {
						Alert.alert('Error!', id + ': ' + ShitUtil.prettyError(exc));
					});
				}
			}

			client.close();

			if (client.response.isFailed()) {
				if (client.cancelRequested) {
					Waiter.put(() -> {
						Alert.alert('Download canceled!');
					});
				}
				else {
					Waiter.put(() -> {
						Alert.alert('Downloading failed!', 
							ShitUtil.prettyStatus(client.response.status) + "\n" +
							(client?.response?.exception != null ? ShitUtil.prettyError(client.response.exception) : '')
						);
					});
				}
			}
			else {
				status = INSTALLING;
				OnlineMods.installMod(downloadPath, url, gbMod, onSuccess);
				status = FINISHED;
			}

			delete();
		});
    }

	function delete() {
		downloaders.remove(this);
		if (alert != null)
			alert.destroy();
		alert = null;
		deleteTempFile();
	}

	function deleteTempFile() {
		try {
			if (FileSystem.exists(downloadPath)) {
				FileSystem.deleteFile(downloadPath);
			}
		} catch (_) {}
	}

    static var allowedMediaTypes:Array<String> = [
		"application/zip",
		"application/zip-compressed",
		"application/x-zip-compressed",
		"application/x-zip",
		"application/x-tar",
		"application/gzip",
		"application/x-gtar",
		"application/octet-stream", // unknown files
		#if RAR_SUPPORTED
		"application/vnd.rar",
		"application/x-rar-compressed",
		"application/x-rar",
		#end
	];

	public static function isMediaTypeAllowed(file:String) {
		file = file.trim();
		for (item in allowedMediaTypes) {
			if (file == item)
				return true;
		}
		return false;
	}

	public static function cancelAll() {
		Sys.println("Cancelling " + downloaders.length + " downloads...");
		for (downloader in downloaders) {
			if (downloader != null)
				downloader.client.cancel();
		}
	}

	public static function checkDeleteDlDir() {
		if (FileSystem.exists(downloadDir)) {
			FileUtils.removeFiles(downloadDir);
		}
	}
}

enum DownloaderStatus {
	CONNECTING;
	READING_HEADERS;
	READING_BODY;
	FAILED(exc:Exception);
	DOWNLOADED;
	INSTALLING;
	FINISHED;
}