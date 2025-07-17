package online.gui;

import online.gui.sidebar.SideUI;
import openfl.text.TextFormat;
import openfl.text.TextField;
import openfl.display.DisplayObject;

@:publicFields
class Util {
	static function checkKey(key:Int, keyID:String):Bool {
		for (k in ClientPrefs.keyBinds.get(keyID)) {
			if (key == k)
				return true;
		}
		return false;
	}

	static function overlapsMouse(obj:DisplayObject) {
		return obj.visible && obj.alpha > 0 && obj.mouseX > 0 && obj.mouseX < obj.width && obj.mouseY > 0 && obj.mouseY < obj.height;
		//return obj.mouseX >= obj.x && obj.mouseX <= obj.x + obj.width && obj.mouseY >= obj.y && obj.mouseY <= obj.y + obj.height;
	}

	static function createText(?parent:DisplayObject, x:Float, y:Float, size:Int = 18, ?color:Int = 0xFFFFFFFF) {
		var obj = new TextField();
		obj.x = x;
		obj.y = y;
		obj.selectable = false;
		obj.multiline = true;
		obj.defaultTextFormat = new TextFormat(Assets.getFont('assets/fonts/vcr.ttf').fontName, size, color, false);
		return obj;
	}

	static function setText(obj:TextField, text:String, ?maxWidth:Null<Float>, ?color:Null<Int>) {
		obj.scaleX = 1;
		obj.scaleY = 1;
		if (color != null) {
			var format = obj.defaultTextFormat;
			format.color = color;
			obj.defaultTextFormat = format;
		}
		obj.text = text + '\n ';
		obj.width = obj.textWidth;
		obj.height = obj.textHeight;
		obj.scaleX = Math.min(1, (maxWidth ?? (SideUI.instance.curTab.tabWidth - obj.x - 20)) / obj.width);
		obj.scaleY = obj.scaleX;
	}

	static function getTextWidth(obj:TextField) {
		return obj.textWidth * obj.scaleX;
	}
	static function getTextHeight(obj:TextField):Float {
		if (obj.text.length <= 0 || obj.text == '\n ') return 0;
		return obj.textHeight * obj.scaleY - obj.defaultTextFormat.size * obj.scaleY;
	}

	static function inviteToPlay(daUsername:String) {
		if (GameClient.isConnected()) {
			if (NetworkClient.room == null)
				NetworkClient.connect();

			while (NetworkClient.connecting) {}

			if (NetworkClient.room != null) {
				NetworkClient.room.send('inviteplayertoroom', daUsername);
			}
			else
				Alert.alert('Failed to connect to the Network!');
		}
		else {
			Alert.alert('You\'re not in a room!');
		}
	}

	static function getRealHeight(?parent:DisplayObject) {
		var maxHeight:Float = 0;
		for (child in @:privateAccess parent.__children) {
			if (child.visible && child.y + child.height - parent.y > maxHeight)
				maxHeight = child.y + child.height - parent.y;
		}
		return maxHeight;
	}

	static function wrapText(text:String, ?everyCharacters:Int = 45, ?stopAtLine:Int = 10) {
		var output = '';
		var i = -1;
		var score = 0;
		var lineScore = 0;
		var char = '';

		while (++i < text.length) {
			if (char == '\n' && char == text.charAt(i)) {
				//skip double newlines
				continue;
			}
			char = text.charAt(i);
			score++;

			if (score >= everyCharacters) {
				score = 0;
				output += '[...]\n';
				lineScore++;
				if (lineScore >= stopAtLine) {
					break;
				}

				while (++i < text.length) {
					if (text.charAt(i) == ' ' || text.charAt(i) == '\n') {
						break;
					}
				}
				continue;
			}
			else if (score >= everyCharacters - 10 && char == ' ') {
				score = 0;
				output += '\n';
				lineScore++;
				if (lineScore >= stopAtLine) {
					break;
				}
				continue;
			}

			if (char == '\n') {
				score = 0;
				lineScore++;
				if (lineScore >= stopAtLine) {
					break;
				}
			}

			output += char;
		}

		if (lineScore >= stopAtLine) {
			output += '\n...';
		}

		return output;
	}
}