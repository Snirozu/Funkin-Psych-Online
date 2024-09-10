package online.net;

import haxe.io.Error;
import haxe.io.Eof;
import online.HTTPClient.HTTPResponse;
import online.HTTPClient.HTTPRequest;
import haxe.CallStack;
import openfl.net.FileReference;
import haxe.io.Bytes;
import haxe.crypto.Base64;
import lime.ui.FileDialog;
import haxe.Http;
import haxe.Json;
import online.NicommentsView.SongComment;

@:unreflective
class FunkinNetwork {
	public static var client:HTTPClient = null;
	public static var nickname(default, null):String = null;
	public static var points(default, null):Float = 0;
	public static var loggedIn:Bool = false;

	public static function requestLogin(email:String, ?code:String) {
		var response = requestAPI({
			path: "/api/network/auth/login",
			headers: ["content-type" => "application/json"],
			body: Json.stringify({
				email: email,
				code: code
			}),
			post: true
		});

		if (response == null)
			return false;

		if (code != null)
			saveCredentials(Json.parse(response.body));

		return true;
	}

	public static function setEmail(email:String, ?code:String) {
		var emailSplit = email.split(' from ');

		var response = requestAPI({
			path: "/api/network/auth/email/set",
			headers: ["authorization" => getAuthHeader(), "content-type" => "application/json"],
			body: Json.stringify({
				email: emailSplit[0].trim(),
				old_email: emailSplit[1].trim(),
				code: code
			}),
			post: true
		});

		if (response == null)
			return false;

		return true;
	}

	public static function logout() {
		ClientPrefs.data.networkAuthID = null;
		ClientPrefs.data.networkAuthToken = null;
		ClientPrefs.saveSettings();
		loggedIn = false;
		nickname = null;
		points = 0;
	}

	public static function getAuthHeader(?authID:String, ?authToken:String) {
		return "Basic " + Base64.encode(Bytes.ofString((authID ?? ClientPrefs.data.networkAuthID) + ":" + (authToken ?? ClientPrefs.data.networkAuthToken)));
	}

	public static function ping():Bool {
		if (ClientPrefs.data.networkAuthID == null || ClientPrefs.data.networkAuthToken == null)
			return loggedIn = false;

		var response = requestAPI({
			path: "/api/network/account/me",
			headers: ["authorization" => getAuthHeader()]
		});

		if (response == null)
			return loggedIn = false;

		var json = Json.parse(response.body);
		nickname = json.name;
		points = json.points;
		return loggedIn = true;
	}

	public static function register(username:String):Void {
		var response = requestAPI({
			path: "/api/network/auth/register",
			headers: ["content-type" => "application/json"],
			body: Json.stringify({
				username: username
			}),
			post: true
		});

		if (response == null)
			return;

		var json = Json.parse(response.body);
		Waiter.put(() -> {
			saveCredentials(json);
			Alert.alert("Successfully registered!");
		});
	}

	static function saveCredentials(json:Dynamic) {
		trace("Saving credentials");
		ClientPrefs.data.networkAuthID = json.id;
		ClientPrefs.data.networkAuthToken = json.token;
		ClientPrefs.saveSettings();
		// new FileReference().save(json.id + "\n" + json.secret, "recovery_token.txt");
		ping();
	}

    // public static function postResults(path:String) {
	// 	var http = new Http(API_URL + "/api/rankings/post");
	// 	var input = File.read(path);
	// 	http.fileTransfer("replay", "replay.funkinreplay", input, FileSystem.stat(path).size);
	// 	http.request(true);
	// 	input.close();
    // }

	public static function updateName(name:String):String {
		var response = requestAPI({
			path: "/api/network/account/rename",
			headers: ["authorization" => getAuthHeader(), "content-type" => "application/json"],
			body: Json.stringify({
				username: name
			}),
			post: true
		});

		if (response == null)
			return nickname;

		return nickname = response.body;
	}

	public static function postFrontMessage(message:String):Bool {
		var response = requestAPI({
			path: "/api/network/sez",
			headers: ["authorization" => getAuthHeader(), "content-type" => "application/json"],
			body: Json.stringify({
				message: message
			}),
			post: true
		});

		if (response == null)
			return false;

		return true;
	}

	public static function fetchFront():Dynamic {
		var response = requestAPI({
			path: "/api/front"
		});

		if (response == null)
			return null;

		try {
			return Json.parse(response.body);
		}
		catch (exc) {
			trace(exc);
			return null;
		}
	}

	public static function fetchSongComments(songId:String):Array<SongComment> {
		var response = requestAPI({
			path: "/api/network/song/comments?id=" + songId,
		});

		if (response == null)
			return null;

		try {
			return Json.parse(response.body);
		}
		catch (exc) {
			trace(exc);
			return null;
		}
	}

	public static function postSongComment(songId:String, content:String, at:Float):Array<SongComment> {
		var response = requestAPI({
			path: "/api/network/song/comment",
			headers: ["authorization" => getAuthHeader(), "content-type" => "application/json"],
			body: Json.stringify({
				id: songId,
				content: content,
				at: at
			}),
			post: true
		});

		if (response == null)
			return null;

		try {
			return Json.parse(response.body);
		}
		catch (exc) {
			trace(exc);
			return null;
		}
	}

	public static function requestAPI(request:HTTPRequest, ?alertError:Bool = true):Null<HTTPResponse> {
		var response = client.request(request);

		if (response.isFailed()) {
			if (response.exception != null) {
				if (alertError && response.exception != "Eof" && response.exception != "EOF")
					Waiter.put(() -> {
						Alert.alert("Exception: " + request.path, response.exception + (response.exception.stack != null ? "\n\n" + CallStack.toString(response.exception.stack) : ""));
					});
			}
			else if (response.status == 404) {
				return null;
			}
			else if (alertError) {
				Waiter.put(() -> {
					Alert.alert('HTTP Error ${response.status}: ' + request.path, response.body != null && response.body.ltrim().startsWith("{") ? Json.parse(response.body).error : response.body);
				});
			}
			return null;
		}

		return response;
	}
}