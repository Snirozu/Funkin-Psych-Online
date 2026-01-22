package online.util;

import openfl.text.TextFormat;
import openfl.Assets;
import openfl.text.TextField;

class TextFormats {
	public static function applyASCII(field:TextField) {
		var newText = '';
		var i = 0;
		var isControl = false;
		var cookingArg = '';
		var controlArgs = [];
		var formats:Array<Dynamic> = [];
		var curFormat = field.defaultTextFormat;

		function getColor(sint:String):Int {
			switch (sint) {
				case '0', '30', '40':
					return FlxColor.BLACK;
				case '1', '31', '41':
					return FlxColor.RED;
				case '2', '32', '42':
					return FlxColor.GREEN;
				case '3', '33', '43':
					return FlxColor.YELLOW;
				case '4', '34', '44':
					return FlxColor.BLUE;
				case '5', '35', '45':
					return FlxColor.PURPLE;
				case '6', '36', '46':
					return FlxColor.CYAN;
				case '7', '37', '47':
					return FlxColor.WHITE;
				case '8', '90', '100':
					return FlxColor.GRAY;
				case '9', '91', '101':
					return FlxColor.RED; //light
				case '10', '92', '102':
					return FlxColor.LIME;
				case '11', '93', '103':
					return FlxColor.YELLOW;
				case '12', '94', '104':
					return FlxColor.BLUE;
				case '13', '95', '105':
					return FlxColor.MAGENTA;
				case '14', '96', '106':
					return FlxColor.CYAN;
				case '15', '97', '107':
					return FlxColor.WHITE;
			}
			return field.defaultTextFormat.color;
		}

		while (i < field.text.length) {
			var char = field.text.charAt(i);
			if (!isControl) {
				if (field.text.charCodeAt(i) == 27 && field.text.charAt(i + 1) == '[') { // ESC and [ character
					isControl = true;
					i++;
				}
				else {
					newText += char;
				}
				i++;
				continue;
			}

			if (char == 'm' || char == ';') {
				controlArgs[controlArgs.length] = cookingArg;
				cookingArg = '';
				if (char == 'm') {
					curFormat = curFormat.clone();

					switch (controlArgs[0]) {
						case '0':
							curFormat = field.defaultTextFormat.clone();
						case '1':
							curFormat.bold = true;
						case '2':
							curFormat.bold = false;
						case '3':
							curFormat.italic = true;
						case '4':
							curFormat.underline = true;
						case '30', '31', '32', '33', '34', '35', '36', '37':
							curFormat.color = getColor(controlArgs[1]);
						case '38':
							switch (controlArgs[1]) {
								case '2':
									curFormat.color = FlxColor.fromRGB(Std.parseInt(controlArgs[2]), Std.parseInt(controlArgs[3]), Std.parseInt(controlArgs[4]));
								case '5':
									curFormat.color = getColor(controlArgs[2]);
							}
						case '39':
							curFormat.color = field.defaultTextFormat.color;
					}

					formats.push([curFormat, newText.length - 1]);

					isControl = false;
				}
				i++;
				continue;
			}

			cookingArg += char;
			i++;
		}

		field.text = newText;

		for (form in formats) {
			field.setTextFormat(form[0], form[1]);
		}
	}

	static var emojis:Array<Int> = null;
	public static function applyEmojis(field:TextField) {
		if (emojis == null) {
			var emojiStrs = Assets.getText('assets/fonts/emojis.txt').trim().split(' ');
			emojis = [];
			for (emojiStr in emojiStrs) {
				emojis.push(emojiStr.charCodeAt(0));
			}
		}

		var format = new TextFormat(Assets.getFont('assets/fonts/NotoEmoji.ttf').fontName);

		for (i in 0...field.text.length) {
			if (emojis.contains(field.text.charCodeAt(i))) {
				trace(field.text.charCodeAt(i), field.text.charAt(i));
				field.setTextFormat(format, i, i + 1);
			}
			if (field.text.charAt(i) == 'a') {
				field.setTextFormat(new TextFormat(Assets.getFont('assets/fonts/pixel.otf').fontName), i, i + 1);
			}
		}
	}
}