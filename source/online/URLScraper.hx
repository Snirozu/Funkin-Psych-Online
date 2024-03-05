package online;

import htmlparser.HtmlDocument;
import haxe.Http;
import sys.thread.Thread;

class URLScraper {
    public static function downloadFromGDrive(url:String, ?onSuccess:String->Void) {
		var id = url.substr("https://drive.google.com/file/d/".length).split("/")[0];
		OnlineMods.startDownloadMod(url, 'https://drive.usercontent.google.com/download?id=$id&export=download&confirm=t', null, onSuccess, [], url);
    }

	public static function downloadFromMediaFire(url:String, ?onSuccess:String->Void) {
		Thread.create(() -> {
			var http = new Http(url);

			http.onData = function(data:String) {
				Waiter.put(() -> {
                    var doc = new HtmlDocument(data, true);
					var titles = doc.find("#downloadButton");
					OnlineMods.startDownloadMod(url, titles[0].getAttribute("href"), null, onSuccess, [], url);
				});
			}

			http.onError = function(error) {
				Waiter.put(() -> {
                    Alert.alert("Download failed!", "Can't get the download for this MediaFire file!");
				});
			}

			http.request();
		});
	}
}