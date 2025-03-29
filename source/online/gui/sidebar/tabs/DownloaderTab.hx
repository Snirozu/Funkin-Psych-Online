package online.gui.sidebar.tabs;

import online.gui.sidebar.obj.TabSprite.ITabInteractable;

class DownloaderTab extends TabSprite {
    public function new() {
        super('Downloads', 'downloads');
    }

    override function create() {
        super.create();

		var title = this.createText(0, 0, 20, FlxColor.WHITE);
        title.setText('Downloader Test');
		addChild(title);

		for (dow in ModDownloader.downloaders) {
            
        }
    }
}

class DownloadItem extends Sprite implements ITabInteractable {
	public var underlay:Bitmap;
	public var nameTxt:TextField;
	public var status:TextField;
	public var cancel:TabButton;
	public var bar:Bitmap;

    public function new() {
        super();

		underlay = new Bitmap(new BitmapData(SideUI.DEFAULT_TAB_WIDTH, 80, true, FlxColor.fromRGB(20, 20, 20)));
		addChild(underlay);

		nameTxt = this.createText(20, 20, 22);
		addChild(nameTxt);

		status = this.createText(nameTxt.x, nameTxt.y + 30, 18);
		addChild(status);

		cancel = new TabButton('cancel', () -> {});
		cancel.x = underlay.width - cancel.width - 20;
		cancel.y = underlay.height / 2 - cancel.height / 2;
		addChild(cancel);

		updateVisual();
    }

    //don't sue me sony for this argument name :pray:
	public function create(trackId:String) {
		underlay.bitmapData = new BitmapData(SideUI.DEFAULT_TAB_WIDTH, 100, true, FlxColor.fromRGB(20, 20, 20));

		nameTxt.setText(trackId);
		status.setText('Initializing...');

		cancel.onClick = () -> {

		}
	}

	override function __enterFrame(delta) {
		super.__enterFrame(delta);

	}

	private function mouseDown(event:MouseEvent) {}
	private function mouseMove(event:MouseEvent) {
		updateVisual();
    }

    function updateVisual() {
		underlay.alpha = 0.3;
		if (this.overlapsMouse()) {
			underlay.alpha = 0.6;
		}
    }

	private function keyDown(event:KeyboardEvent) {};
	private function mouseWheel(event:MouseEvent) {};
}