package online;

import online.states.OpenURL;
import flixel.math.FlxRect;
import openfl.events.KeyboardEvent;
import lime.system.Clipboard;

// this class took me 2 days to make because my ass iz addicted to websites HELP
class ChatBox extends FlxTypedSpriteGroup<FlxSprite> {
	public static var instance:ChatBox;
	var prevMouseVisibility:Bool = false;

    public var focused(default, set):Bool = false;
	function set_focused(v) {
		if (v) {
			prevMouseVisibility = FlxG.mouse.visible;
			FlxG.mouse.visible = true;
			typeTextHint.text = "(Type something to input the message, ACCEPT to send)";
		}
		else {
			FlxG.mouse.visible = prevMouseVisibility;
			typeTextHint.text = "(Press TAB to open chat!)";
		}
		targetAlpha = v ? 3 : 0;
		return focused = v;
	}

	var bg:FlxSprite;
	var chatGroup:FlxTypedSpriteGroup<ChatMessage>;
	var typeBg:FlxSprite;
    var typeText:FlxText;
    var typeTextHint:FlxText; // i can call it a hint or tip whatever i want

	var targetAlpha:Float;

	var onCommand:(String, Array<String>) -> Bool;

	public function new(camera:FlxCamera, ?onCommand:(command:String, args:Array<String>) -> Bool) {
		super();
		instance = this;

		this.onCommand = onCommand;
		cameras = [camera];
        
        bg = new FlxSprite();
        bg.makeGraphic(600, 400, FlxColor.BLACK);
		bg.alpha = 0.6;
        add(bg);

		typeTextHint = new FlxText(0, 0, bg.width, "(Type something to input the message, ACCEPT to send)");
		typeTextHint.setFormat("VCR OSD Mono", 16, FlxColor.WHITE);
		typeTextHint.alpha = 0.6;

		typeBg = new FlxSprite(0, bg.y + bg.height);
		typeBg.makeGraphic(/*Std.int(bg.width)*/ FlxG.width, Std.int(typeTextHint.height), FlxColor.BLACK);
		add(typeBg);

		chatGroup = new FlxTypedSpriteGroup<ChatMessage>();
		add(chatGroup);

		typeText = new FlxText(0, 0, typeBg.width);
		typeText.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);

		typeTextHint.y = typeBg.y;
		typeText.y = typeBg.y;

		add(typeTextHint);
		add(typeText);

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);

		focused = false; // initial update

		if (GameClient.isConnected())
			GameClient.room.onMessage("log", function(message) {
				Waiter.put(() -> {
					addMessage(message);
					var sond = FlxG.sound.play(Paths.sound('scrollMenu'));
					sond.pitch = 1.5;
				});
			});
    }

	override function destroy() {
		super.destroy();

		instance = null;

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
	}

    public function addMessage(message:String) {
		targetAlpha = 3;

		var chat = new ChatMessage(bg.width, message);
		chatGroup.insert(0, chat);

		if (chatGroup.length >= 22) {
			chatGroup.remove(chatGroup.members[chatGroup.length - 1], true);
		}
    }

    override function update(elapsed) {
		if (focused || alpha > 0) {
			if (FlxG.keys.justPressed.ESCAPE) {
				focused = false;
			}

			var i = -1;
			while (++i < chatGroup.length) {
				var msg = chatGroup.members[i];

				if (i == 0) {
					msg.y = typeBg.y - msg.height;
				}
				else if (chatGroup.members[i - 1] != null) {
					msg.y = chatGroup.members[i - 1].y - msg.height;
				}

				msg.alpha = 0.8;
				if (msg != null && FlxG.mouse.visible && FlxG.mouse.overlaps(msg, camera)) {
					msg.alpha = 1;
					if (FlxG.mouse.justPressed && msg.link != null) {
						focused = false;
						OpenURL.open(msg.link);
					}
				}
				if (msg.alpha > targetAlpha) {
					msg.alpha = targetAlpha;
				}

				var newClipRect = msg.clipRect ?? new FlxRect();
				newClipRect.height = bg.height;
				newClipRect.width = bg.width;
				newClipRect.y = bg.y - msg.y;
				msg.clipRect = newClipRect;
			}
		}

		if (bg.alpha > 0.6)
			bg.alpha = 0.6;
		if (typeTextHint.alpha > 0.6)
			typeTextHint.alpha = 0.6;

        super.update(elapsed);

		if (FlxG.keys.justPressed.TAB) {
			focused = !focused;
		}

		typeTextHint.visible = focused ? (typeText.text.length <= 0) : true;

		if (!focused && targetAlpha > 0.)
			targetAlpha -= elapsed;

		alpha = targetAlpha;
    }

	// some code from FlxInputText
	function onKeyDown(e:KeyboardEvent) {
		if (!focused)
			return;

		var key = e.keyCode;

		if (e.charCode == 0) { // non-printable characters crash String.fromCharCode
			return;
		}

		if (key == 46) { // delete
			return;
		}

		if (key == 8) { // bckspc
			typeText.text = typeText.text.substring(0, typeText.text.length - 1);
			return;
		}
		else if (key == 13) { // enter
			if (StringTools.startsWith(typeText.text, "/"))
				if (onCommand != null)
					parseCommand(typeText.text);
				else
					addMessage("No available commands!");
			else
				GameClient.send("chat", typeText.text);
			
			typeText.text = "";
			return;
		}
		else if (key == 27) { // esc
			return;
		}

		var newText:String = String.fromCharCode(e.charCode);
		if (key == 86 && e.ctrlKey) {
			newText = Clipboard.text;
		}
		if (e.shiftKey) {
			newText = newText.toUpperCase();
		}

		if (newText.length > 0) {
			typeText.text += newText;
		}
	}

	function parseCommand(text:String) {
		var splitText:Array<String> = text.split(" ");
		var command = splitText.shift().substr(1);
		if (!onCommand(command, splitText)) {
			if (command == "/help") {
				addMessage("No available commands!");
				return;
			}
			addMessage("Unknown command; try /help for command list!");
		}
	}
}

class ChatMessage extends FlxText {
	public var link:String = null;

	public function new(fieldWidth:Float = 0, message:String) {
		super(0, 0, fieldWidth, message);
		setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);

		var _split = message.split("");
		var i = -1;
		var str = "";
		var formatBeg = null;
		var formatEnd = null;
		while (++i < message.length) {
			if (this.link == null && str.startsWith("https://")) {
				if (_split[i].trim() == "") {
					this.link = str;
					formatEnd = i;
				}
				else if (i == message.length - 1) {
					this.link = str + _split[i].trim();
					formatEnd = i + 1;
				}
			}

			str += _split[i];

			if (this.link == null && str.endsWith("https://")) {
				str = "https://";
				formatBeg = i - 7;
			}
		}

		if (link != null)
			addFormat(new FlxTextFormat(FlxColor.CYAN), formatBeg, formatEnd);
	}
}