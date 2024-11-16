package online.gui.sidebar;

import openfl.events.TextEvent;
import openfl.Lib;
import online.network.FunkinNetwork;
import haxe.io.BytesOutput;
import haxe.io.Bytes;
import haxe.crypto.Base64;

class MainTab extends TabSprite {
	var profileBg:Bitmap;
	var nickname:TextField;
	var nameDesc:TextField;
	var avatar:Bitmap;
	var avatarLoaded:Bool = false;

	var chatBg:Bitmap;
	var chatInput:TextField;
	static var messages:Array<TextField> = [];
	var msgSprite:Sprite;

	override function create() {
		msgSprite = new Sprite();
		addChild(msgSprite);

		profileBg = new Bitmap(new BitmapData(Std.int(widthTab), 150, true, FlxColor.fromRGB(0, 0, 0, 200)));
		addChild(profileBg);

		nickname = new TextField();
		nickname.selectable = false;
		var format = TabSprite.getDefaultFormat();
		format.size = 20;
		nickname.defaultTextFormat = format;
		nickname.width = widthTab;
		nickname.y = 20;
		nickname.x = widthTab / 2 - nickname.width / 2;
		addChild(nickname);

		nameDesc = new TextField();
		nameDesc.selectable = false;
		nameDesc.defaultTextFormat = TabSprite.getDefaultFormat();
		nameDesc.width = widthTab;
		nameDesc.y = nickname.y + 30;
		nameDesc.x = nickname.x;
		addChild(nameDesc);

		avatar = new Bitmap(new BitmapData(30, 30, true, FlxColor.fromRGB(0, 0, 0, 0)));
		addChild(avatar);

		chatInput = new TextField();
		chatInput.defaultTextFormat = TabSprite.getDefaultFormat();
		chatInput.text = "";
		chatInput.type = INPUT;
		chatInput.width = Std.int(widthTab);

		var chatInputPlaceholder:TextField = new TextField();
		chatInputPlaceholder.defaultTextFormat = TabSprite.getDefaultFormat();
		chatInputPlaceholder.text = "(Click here to chat)";
		chatInputPlaceholder.selectable = false;
		chatInputPlaceholder.y = Lib.application.window.height - (chatInputPlaceholder.textHeight + 5);
		chatInputPlaceholder.width = Std.int(widthTab);

		chatInput.y = chatInputPlaceholder.y;

		chatBg = new Bitmap(new BitmapData(Std.int(widthTab), Std.int(chatInputPlaceholder.textHeight + 5), true, FlxColor.fromRGB(0, 0, 0, 200)));
		chatBg.y = Lib.application.window.height - chatBg.height;
		addChild(chatBg);
		addChild(chatInputPlaceholder);
		addChild(chatInput);

		chatInput.addEventListener(Event.CHANGE, _ -> {
			chatInputPlaceholder.visible = chatInput.text.length <= 0;
		});

		updateMessages();
	}

	public static function addMessage(raw:Dynamic) {
		var data = ShitUtil.parseLog(raw);

		var msg:TextField = new TextField();
		var format = TabSprite.getDefaultFormat();
		format.color = data.hue != null ? FlxColor.fromHSL(data.hue, 0.8, 0.6) : FlxColor.WHITE;
		msg.defaultTextFormat = format;
		msg.height = 10000;
		msg.wordWrap = true;
		msg.text = data.content;
		msg.height = msg.textHeight + 1;
		messages.unshift(msg);

		updateMessages();
	}

	public static function updateMessages() {
		//maybe ill add other tabs later
		if (SideUI.instance?.curTab == null || !(SideUI.instance.curTab is MainTab)) {
			return;
		}

		var instance:MainTab = cast SideUI.instance.curTab;

		if (messages.length > 100) {
			messages.pop();
		}

		instance.msgSprite.removeChildren();

		var lastY:Null<Float> = null;
		for (message in messages) {
			message.width = Std.int(instance.widthTab);
			message.y = lastY = (lastY ?? Lib.application.window.height - instance.chatBg.height) - (message.textHeight + 5);
			instance.msgSprite.addChild(message);
		}
	}

	override function keyDown(event:KeyboardEvent):Void {
		if (stage.focus == chatInput && event.keyCode == 13) {
			//addMessage(FunkinNetwork.nickname + ': ' + chatInput.text);
			if (NetworkClient.room != null) {
				NetworkClient.room.send('chat', chatInput.text);
			}
			else {
				addMessage("Not connected to the server! Trying to connect!");
				NetworkClient.connect();
			}
			
			chatInput.text = '';
			chatInput.dispatchEvent(new Event(Event.CHANGE, true));
		}
	}

	override function mouseDown(e:MouseEvent):Void {
		if (e.localX < width && e.localY >= Lib.application.window.height - chatBg.height - 5) {
			stage.focus = chatInput;
		}
	}

	override function mouseWheel(e:MouseEvent):Void {
		msgSprite.y += e.delta * 30;

		if (msgSprite.y <= 0)
			msgSprite.y = 0;
		if (msgSprite.y >= msgSprite.height)
			msgSprite.y = msgSprite.height;
	}

	override function onShow() {
		profileBg.bitmapData.floodFill(0, 0, FlxColor.fromHSL(FunkinNetwork.profileHue, 0.25, 0.25));
		nickname.text = FunkinNetwork.loggedIn ? "Welcome, " + FunkinNetwork.nickname : "Not Logged In";
		nameDesc.text = "Points: " + FunkinNetwork.points + "\nAvg. Accuracy: " + FlxMath.roundDecimal(FunkinNetwork.avgAccuracy * 100, 2) + "%";

		loadAvatar();

		if (NetworkClient.room == null) {
			NetworkClient.connect();
		}

		updateMessages();
	}

	function loadAvatar() {
		if (avatarLoaded)
			return;

		nickname.x = widthTab / 2 - nickname.width / 2;
		nameDesc.x = nickname.x;
		avatar.visible = false;

		if (FunkinNetwork.loggedIn) {
			Thread.run(() -> {
				var output = new BytesOutput();
				var avatarResponse = FunkinNetwork.requestAPI({
					path: 'api/avatar/' + Base64.encode(Bytes.ofString(FunkinNetwork.nickname)),
					bodyOutput: output
				});
				if (!avatarResponse.isFailed()) {
					Waiter.put(() -> {
						if (avatar != null) {
							avatarLoaded = true;
							avatar.bitmapData = BitmapData.fromBytes(output.getBytes());
							avatar.width = 100;
							avatar.height = 100;
							avatar.x = 50;
							avatar.y = 20;
							avatar.visible = true;

							nickname.x = avatar.x + avatar.width + 20;
							nameDesc.x = nickname.x;
						}
					});
				}
			});
		}
	}
}