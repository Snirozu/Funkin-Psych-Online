package online;

import htmlparser.HtmlDocument;
import haxe.Http;

class URLScraper {
    public static function downloadFromGDrive(url:String, ?onSuccess:String->Void) {
		var id = url.substr("https://drive.google.com/file/d/".length).split("/")[0];
		OnlineMods.startDownloadMod(url, 'https://drive.usercontent.google.com/download?id=$id&export=download&confirm=t', null, onSuccess, [], url);
    }

	public static function downloadFromMediaFire(url:String, ?onSuccess:String->Void) {
		Thread.run(() -> {
			var http = new Http(url);

			http.onData = function(data:String) {
				Waiter.put(() -> {
                    var doc = new HtmlDocument(data, true);
					var titles = doc.find("#downloadButton");
					if (titles[0] == null) {
						Waiter.put(() -> {
							Alert.alert("Download failed!", "Can't get the download link for this MediaFire file!");
						});
						return;
					}
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

	public static function getURLFormat(url:String):URLFormat {
		var urlFormat:URLFormat = {
			isSSL: false,
			domain: "",
			port: 80,
			path: ""
		};

		if (url.startsWith("https://") || url.startsWith("wss://")) {
			urlFormat.isSSL = true;
			urlFormat.port = 443;
		}
		else if (url.startsWith("http://") || url.startsWith("ws://")) {
			urlFormat.isSSL = false;
			urlFormat.port = 80;
		}
		if (url.contains("://")) {
			url = url.substr(url.indexOf("://") + 3);
		}

		urlFormat.domain = url.substring(0, url.indexOf("/"));
		if (urlFormat.domain.indexOf(":") != -1) {
			var split = urlFormat.domain.split(":");
			urlFormat.domain = split[0];
			urlFormat.port = Std.parseInt(split[1]) ?? urlFormat.port;
		}
		urlFormat.path = url.substr(url.indexOf("/"));

		return urlFormat;
	}
}

typedef URLFormat = {
	var isSSL:Bool;
	var domain:String;
	var port:Int;
	var path:String;
}