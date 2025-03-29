package online.util;

import haxe.io.Bytes;
import flixel.math.FlxAngle;
import flixel.FlxObject;
import haxe.Json;
import haxe.CallStack;

@:publicFields
class ShitUtil {
	static function tempSwitchMod(switchMod:String, func:Void->Void) {
		var beforeMod = Mods.currentModDirectory;
		Mods.currentModDirectory = switchMod;
		func();
		Mods.currentModDirectory = beforeMod;
	}

	static function toOrdinalNumber(num:Float) {
		if (num % 10 == 1 && num != 11)
			return num + 'st';
		if (num % 10 == 2 && num != 12)
			return num + 'nd';
		if (num % 10 == 3 && num != 13)
			return num + 'rd';
		return num + "th";
	}

	static function timeAgo(time:Float):String {
		var diff = Sys.time() - (time / 1000 - (Date.now().getTimezoneOffset() * 60));
		if (diff <= 120)
			return 'just now';
		// if (diff < 60)
		// 	return Math.floor(diff) + ' seconds ago';
		if (diff < 3600)
			return _addSuffixHT1(Math.floor(diff / 60), 'minute') + ' ago';
		if (diff < 86400)
			return _addSuffixHT1(Math.floor(diff / 3600), 'hour') + ' ago';
		if (diff < 604800)
			return _addSuffixHT1(Math.floor(diff / 86400), 'day') + ' ago';
		if (diff < 2629800)
			return _addSuffixHT1(Math.floor(diff / 604800), 'week') + ' ago';
		if (diff < 31557600)
			return _addSuffixHT1(Math.floor(diff / 2629800), 'month') + ' ago';
		return _addSuffixHT1(Math.floor(diff / 31557600), 'year') + ' ago';
	}

	private static function _addSuffixHT1(v:Float, word:String, ?suffix:String = 's') {
		return v + ' ' + word + (v >= 2 ? suffix : '');
	}


	// yyyy-mm-ddThh:mm:ss.mssZ
	static function parseISODate(date:String) {
		var char = '';
		var word = '';
		var part = 0;
		var values = [];
		// reject .split() embrace for and while
		for (i in 0...date.length) {
			char = date.charAt(i);

			// go till it hits the letter T
			if (part == 0) {
				if (char == '-' || char == 'T') {
					values.push(word);
					word = '';
					if (char == 'T')
						part = 1;
					continue;
				}
			}
			else { // until it hits Z
				if (char == ':' || char == 'Z' || i == date.length - 1) {
					values.push(word);
					word = '';
					if (char == 'Z')
						break;
					continue;
				}
			}

			word += char;
		}

		return new Date(
			Std.parseInt(values[0]), // year
			Std.parseInt(values[1]) - 1, // month
			Std.parseInt(values[2]), // day
			Std.parseInt(values[3]), // hour
			Std.parseInt(values[4]), // min
			Std.parseInt(values[5]), // sec
		);
	}

	static function wordWrapText(string:String, lineLength:Int) {
		var lines = [];
		var semmiSentence = '';
		var word = '';
		var char = '';
		for (i in 0...string.length) {
			char = string.charAt(i);

			if (char == ' ' || char == '\n' || i == string.length - 1) {
				if (char == '\n' || semmiSentence.length + word.length > lineLength) {
					lines.push(semmiSentence);
					semmiSentence = '';
				}
				if (i == string.length - 1)
					word += char;
				semmiSentence += (semmiSentence.length > 0 ? ' ' : '') + word;
				word = '';
				continue;
			}

			word += char;
		}
		if (semmiSentence.length > 0)
			lines.push(semmiSentence);
		return lines.join('\n');
	}

	static function getMonthName(date:Date) {
		switch (date.getMonth()) {
			case 0:
				return 'January';
			case 1:
				return 'February';
			case 2:
				return 'March';
			case 3:
				return 'April';
			case 4:
				return 'May';
			case 5:
				return 'June';
			case 6:
				return 'July';
			case 7:
				return 'August';
			case 8:
				return 'September';
			case 9:
				return 'October';
			case 10:
				return 'November';
			case 11:
				return 'December';
			default:
				return '?';
		}
	}

	static function toBiDigitString(num:Float) {
		return (num < 10 ? '0' : '') + num;
	}

	// can flixel implement this please
	static function moveByDegrees(object:FlxObject, distance:Float, angle:Float) {
		var rad = FlxAngle.asRadians(angle);
		object.x += Math.cos(rad) * distance;
		object.y += Math.sin(rad) * distance;
	}

	static function getJson(path:String) {
		var raw = Paths.getTextFromFile(path + '.json');
		if (raw == null)
			return null;
		return Json.parse(raw);
	}

	static function parseLog(msg:Dynamic):LogData {
		try {
			if (msg is String)
				return cast(Json.parse(msg));
			return cast(msg);
		}
		catch (e) {
			return {
				content: msg,
				hue: null,
				date: null
			}
		}
	}

    static function readableError(exc:Dynamic) {
        var str = Std.string(exc);
		switch (str.toLowerCase()) {
            case 'eof':
                str += " (Server Refused to Respond)";
        }
        return str;
    }

	static function prettyError(exc:Dynamic) {
		return '${Std.string(exc)} (${exc != null ? Type.getClassName(Type.getClass(exc)) : 'NULL CLASS'})\n' + (exc?.stack != null ? CallStack.toString(exc.stack) : "(NO CALLSTACK)") + "\n";
    }

	static function prettyStatus(status:Dynamic) {
		var str = Std.string(status);
		switch (Std.parseInt(str)) {
            // informational (1XX)
			case 100:
				str += " (Continue)";
			case 101:
				str += " (Switching Protocols)";
			case 102:
				str += " (Processing)";
			case 103:
				str += " (Early Hints)";
            //successful (2XX)
			case 200:
				str += " (OK)";
			case 201:
				str += " (Created)";
			case 202:
				str += " (Accepted)";
			case 203:
				str += " (Non-Authoritative Information)";
			case 204:
				str += " (No Content)";
			case 205:
				str += " (Reset Content)";
			case 206:
				str += " (Partial Content)";
			case 207:
				str += " (Multi-Status)";
			case 208:
				str += " (Already Reported)";
			case 226:
				str += " (IM Used)";
			// redirect (3XX)
			case 300:
				str += " (Multiple Choices)";
			case 301:
				str += " (Moved Permanently)";
			case 302:
				str += " (Found)";
			case 303:
				str += " (See Other)";
			case 304:
				str += " (Not Modified)";
			case 305:
				str += " (Use Proxy)";
			case 306:
				str += " (Switch Proxy)";
			case 307:
				str += " (Temporary Redirect)";
			case 308:
				str += " (Permanent Redirect)";
			// bad request (4XX)
			case 400:
				str += " (Bad Request)";
			case 401:
				str += " (Unauthorized)";
			case 402:
				str += " (Payment Required)";
			case 403:
				str += " (Forbidden)";
			case 404:
				str += " (Not Found)";
			case 405:
				str += " (Method Not Allowed)";
			case 406:
				str += " (Not Acceptable)";
			case 407:
				str += " (Proxy Authentication Required)";
			case 408:
				str += " (Request Timeout)";
			case 409:
				str += " (Conflict)";
			case 410:
				str += " (Gone)";
			case 411:
				str += " (Length Required)";
			case 412:
				str += " (Precondition Failed)";
			case 413:
				str += " (Content Too Large)";
			case 414:
				str += " (URI Too Long)";
			case 415:
				str += " (Unsupported Media Type)";
			case 416:
				str += " (Range Not Satisfiable)";
			case 417:
				str += " (Expectation Failed)";
			case 418:
				str += " (I'm a teapot)";
			case 421:
				str += " (Misdirected Request)";
			case 422:
				str += " (Unprocessable Content)";
			case 423:
				str += " (Locked)";
			case 424:
				str += " (Failed Dependency)";
			case 425:
				str += " (Too Early)";
			case 426:
				str += " (Upgrade Required)";
			case 428:
				str += " (Precondition Required)";
			case 429:
				str += " (Too Many Requests)";
			case 431:
				str += " (Request Header Fields Too Large)";
			case 451:
				str += " (Unavailable For Legal Reasons)";
			// server error (5XX)
			case 500:
				str += " (Internal Server Error)";
			case 501:
				str += " (Not Implemented)";
			case 502:
				str += " (Bad Gateway)";
			case 503:
				str += " (Service Unavailable)";
			case 504:
				str += " (Gateway Timeout)";
			case 505:
				str += " (HTTP Version Not Supported)";
			case 506:
				str += " (Variant Also Negotiates)";
			case 507:
				str += " (Insufficient Storage)";
			case 508:
				str += " (Loop Detected)";
			case 510:
				str += " (Not Extended)";
			case 511:
				str += " (Network Authentication Required)";
            // websockets
            case 1000:
				str += " (WebSocket Closed)";
			case 1001:
				str += " (WebSocket Lost)";
			// colyseus
			case 4000:
				str += " (Consented Leave)";
			case 4002:
				str += " (WebSocket Close Crash)";
			case 4010:
				str += " (Server Restarted)";
			case 4201:
				str += " (Server Disconnected)";
			case 4202:
				str += " (Too Many Clients)";
			case 4210:
				str += " (Unrecognized Room Handler)";
			case 4211:
				str += " (No Available Rooms for Criteria)";
			case 4212:
				str += " (Room Not Found)";
			case 4213:
				str += " (Room Connection Failure)";
			case 4214:
				str += " (Reconnection Timeout)";
			case 4215:
				str += " (Authentication Failure)";
			case 4216:
				str += " (Application Error)";
			case 4217:
				str += " (Unknown Message Type)";
            // psych online
			case 5000:
				str += " (Too Short Username)";
			case 5001:
				str += " (Too Long Username)";
			case 5002:
				str += " (IP Limit)";
			case 5003:
				str += " (Server/Client Protocol Mismatch)";
			case 5004:
				str += " (Illegal Username Characters)";
		}
		return str;
	}
	
	private static final pngPrefix = Bytes.ofHex("89504E47");

	static function isPNG(bytes:Bytes) {
		if (bytes == null) return false;
		return bytes.sub(0, pngPrefix.length).compare(pngPrefix) == 0;
	}

	private static final jpegPrefix = Bytes.ofHex("FFD8FFE000104A464946");

	static function isJPEG(bytes:Bytes) {
		if (bytes == null) return false;
		return bytes.sub(0, jpegPrefix.length).compare(jpegPrefix) == 0;
	}

	static function isSupportedImage(bytes:Bytes) {
		return isPNG(bytes) || isJPEG(bytes);
	}
}

typedef LogData = {
	var content:String;
	var hue:Null<Float>;
	var date:Null<Float>;
	@:optional var color:Null<Int>;
	@:optional var center:Null<Bool>;
}