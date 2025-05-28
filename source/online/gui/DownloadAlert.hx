package online.gui;

import openfl.Lib;
import openfl.Assets;
import openfl.text.TextFormat;
import openfl.text.TextField;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.display.Sprite;

@:allow(online.gui.DownloadAlert)
class DownloadAlerts extends Sprite {
	static var instance:DownloadAlerts ;
	static var instances:Array<DownloadAlert> = [];

	public function new() {
		super();
		
		instance = this;
	}

	override function __enterFrame(delta) {
		super.__enterFrame(delta);

		if (FlxG.keys.pressed.ALT) {
			if (FlxG.keys.justPressed.ONE && ModDownloader.downloaders[0] != null)
				ModDownloader.downloaders[0].client.cancel();
			if (FlxG.keys.justPressed.TWO && ModDownloader.downloaders[1] != null)
				ModDownloader.downloaders[1].client.cancel();
			if (FlxG.keys.justPressed.THREE && ModDownloader.downloaders[2] != null)
				ModDownloader.downloaders[2].client.cancel();
			if (FlxG.keys.justPressed.FOUR && ModDownloader.downloaders[3] != null)
				ModDownloader.downloaders[3].client.cancel();
			if (FlxG.keys.justPressed.FIVE && ModDownloader.downloaders[4] != null)
				ModDownloader.downloaders[4].client.cancel();
			if (FlxG.keys.justPressed.SIX && ModDownloader.downloaders[5] != null)
				ModDownloader.downloaders[5].client.cancel();
			if (FlxG.keys.justPressed.SEVEN && ModDownloader.downloaders[6] != null)
				ModDownloader.downloaders[6].client.cancel();
			if (FlxG.keys.justPressed.EIGHT && ModDownloader.downloaders[7] != null)
				ModDownloader.downloaders[7].client.cancel();
			if (FlxG.keys.justPressed.NINE && ModDownloader.downloaders[8] != null)
				ModDownloader.downloaders[8].client.cancel();
		}

		var prevAlert:DownloadAlert = null;
		var i = 1;
		for (alert in instances) {
			var downloader = ModDownloader.downloaders[i - 1];

			if (downloader != null) {
				if (downloader.client.cancelRequested) {
					alert.cancelText.text = 'Cancelling...';
				}
				else {
					alert.cancelText.text = 'Cancel: ALT + $i ';
					if (i >= 10) {
						alert.cancelText.text = "";
					}
				}

				switch (downloader.status) {
					case CONNECTING:
						alert.setStatus("Connecting...");
					case READING_HEADERS:
						alert.setStatus("Reading Headers...");
					case READING_BODY:
						alert.updateProgress(downloader.client.receivedBytes, downloader.client.contentLength);
					case FAILED(exc):
						alert.setStatus("Failed! " + exc);
					case DOWNLOADED:
						alert.setStatus("Preparing to instal...");
					case INSTALLING:
						alert.setStatus("Installing...");
					case FINISHED:
						alert.setStatus("Finished!");
					default:
						alert.setStatus("Initializing...");
				}
			}
			else {
				alert.setStatus("...");
			}

			if (prevAlert?.bg != null)
				alert.bg.y = prevAlert.bg.y + prevAlert.bg.height + 10;
			else
				alert.bg.y = 0;
			alert.bg.x = Lib.application.window.width - alert.bg.width;
			alert.text.x = alert.bg.x + 10;
			alert.text.y = alert.bg.y;

			alert.bar.y = alert.bg.y + alert.bg.height - 15;
			alert.bar.x = alert.bg.x + 10;

			alert.cancelText.width = alert.cancelText.textWidth;

			alert.cancelBg.x = alert.bg.x - alert.cancelText.textWidth - 5;
			alert.cancelBg.y = alert.bg.y;
			alert.cancelText.x = alert.cancelBg.x;
			alert.cancelText.y = alert.cancelBg.y;

			alert.cancelBg.scaleX = alert.cancelText.textWidth;
			alert.cancelBg.scaleY = alert.cancelText.textHeight + 5;

			prevAlert = alert;
			i++;
		}
	}
}

class DownloadAlert extends Sprite {
	public var bg:Bitmap;
	public var bar:Bitmap;
	public var text:TextField;
	var id:String;

	public var cancelBg:Bitmap;
	public var cancelText:TextField;

    public function new(id:String) {
        super();

		this.id = id;

		DownloadAlerts.instances.push(this);
		DownloadAlerts.instance.addChild(this);

		bg = new Bitmap(new BitmapData(600, 40, true, 0xFF000000));
		bg.alpha = 0.6;
        addChild(bg);

		bar = new Bitmap(new BitmapData(1, 5, true, 0xFFFFFFFF));
		addChild(bar);

		text = new TextField();
		text.text = 'Waiting to download: $id';
		text.selectable = false;
		text.defaultTextFormat = new TextFormat(Assets.getFont('assets/fonts/vcr.ttf').fontName, 15, 0xFFFFFFFF);
		addChild(text);

		text.y = 5;
		text.wordWrap = false;
		text.width = bg.width - text.y * 2;

		bar.y = bg.y + bg.height - 15;
		text.x = 10;
		bar.x = 10;

		bar.visible = false;

		cancelBg = new Bitmap(new BitmapData(1, 1, true, 0xFF000000));
		cancelBg.alpha = 0.5;
		addChild(cancelBg);

		cancelText = new TextField();
		cancelText.text = 'Cancel: ALT + ' + ModDownloader.downloaders.length;
		cancelText.selectable = false;
		cancelText.defaultTextFormat = new TextFormat(Assets.getFont('assets/fonts/vcr.ttf').fontName, 13, 0xFFFFFFFF);
		addChild(cancelText);

		setStatus('Initializing the Download...');
    }

    public function updateProgress(loaded:Float, total:Float) {
		if (text == null)
			return;

		var idCut = id.substr(id.length - 30);
		if (id.length > 30) {
			idCut = "..." + idCut;
		}

		if (total < 0 || loaded > total) {
			bar.visible = false;
			bar.scaleX = 1;
			total = 1;
			text.text = 'Downloading $idCut: ${prettyBytes(loaded)} of ?MB';
			return;
		}
		
		bar.visible = true;
		text.text = 'Downloading $idCut: ${prettyBytes(loaded)} of ${prettyBytes(total)}';

		bar.scaleX = (bg.width - 20) * (loaded / total);
		// bar.x = bg.x + bg.width / 2 - bar.width / 2;
    }

	public function setStatus(string:String) {
		if (text == null || string == text.text)
			return;

		bar.visible = false;
		text.text = string;
	}

	public static function prettyBytes(bytes:Float):String {
		if (bytes > 1000000000) {
			return FlxMath.roundDecimal(bytes / 1000000000, 2) + "GB";
		}
		return FlxMath.roundDecimal(bytes / 1000000, 1) + "MB";
	}

	public function destroy() {
		DownloadAlerts.instances.remove(this);
		Waiter.put(() -> {
			bg = null;
			text = null;
			DownloadAlerts.instance.removeChild(this);
		});
	}
}