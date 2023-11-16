package online;

import flixel.math.FlxRect;
import openfl.events.KeyboardEvent;
import lime.system.Clipboard;

// this class took me 2 days to make because my ass iz addicted to websites HELP
class ChatBox extends FlxTypedSpriteGroup<FlxSprite> {
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
    var chatText:FlxText;
	var typeBg:FlxSprite;
    var typeText:FlxText;
    var typeTextHint:FlxText; // i can call it a hint or tip whatever i want

	var targetAlpha:Float;

    public function new() {
        super();
        
        bg = new FlxSprite();
        bg.makeGraphic(600, 400, FlxColor.BLACK);
		bg.alpha = 0.6;
        add(bg);

		typeTextHint = new FlxText(0, 0, bg.width, "(Type something to input the message, ACCEPT to send)");
		typeTextHint.setFormat("VCR OSD Mono", 16, FlxColor.WHITE);
		typeTextHint.alpha = 0.6;

		typeBg = new FlxSprite(0, bg.y + bg.height);
		typeBg.makeGraphic(Std.int(bg.width), Std.int(typeTextHint.height), FlxColor.BLACK);
		add(typeBg);

		chatText = new FlxText(0, 0, bg.width);
		chatText.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);

		typeText = new FlxText(0, 0, bg.width);
		typeText.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);

		typeTextHint.y = typeBg.y;
		typeText.y = typeBg.y;

		add(chatText);
		add(typeTextHint);
		add(typeText);

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);

		focused = false; // initial update
    }

	override function destroy() {
		super.destroy();

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
	}

    public function addMessage(message:String) {
		targetAlpha = 3;

        chatText.text += "\n" + message;
		chatText.y = typeBg.y - chatText.height;
		var newClipRect = chatText.clipRect ?? new FlxRect();
		newClipRect.height = bg.height;
		newClipRect.width = bg.width;
        newClipRect.y = chatText.height - bg.height;
		chatText.clipRect = newClipRect;
    }

    override function update(elapsed) {
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
			GameClient.room.send("chat", typeText.text);
			typeText.text = "";
			return;
		}
		else if (key == 27) { // esc
			focused = false;
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
}