package online.network;

import haxe.io.BytesOutput;
import openfl.display.BitmapData;
import online.util.HTTPClient.HTTPResponse;
import online.util.HTTPClient.HTTPRequest;
import haxe.CallStack;
import openfl.net.FileReference;
import haxe.io.Bytes;
import haxe.crypto.Base64;
import lime.ui.FileDialog;
import haxe.Http;
import haxe.Json;
import online.objects.NicommentsView.SongComment;

@:unreflective
class FunkinNetwork {
	public static var client:HTTPClient = null;
	public static var nickname(default, null):String = null;
	public static var points(default, null):Float = 0;
	public static var avgAccuracy(default, null):Float = 0;
	public static var profileHue(default, null):Float = 0;
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
		var emailSplit = email.trim().split(' from ');

		var response = requestAPI({
			path: "/api/network/account/email/set",
			headers: ["authorization" => Auth.getAuthHeader(), "content-type" => "application/json"],
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

	public static function deleteAccount() {
		var response = requestAPI({
			path: "/api/network/account/delete",
			headers: ["authorization" => Auth.getAuthHeader()],
		});

		if (response == null)
			return false;

		logout();
		return true;
	}

	public static function logout() {
		Auth.save(null, null);
		loggedIn = false;
		nickname = null;
		points = 0;
	}

	public static function ping():Bool {
		if (Auth.authID == null || Auth.authToken == null)
			return loggedIn = false;

		var response = requestAPI({
			path: "/api/network/account/me",
			headers: ["authorization" => Auth.getAuthHeader()],
		}, false);

		if (response == null)
			return loggedIn = false;

		var json = Json.parse(response.body);
		nickname = json.name;
		points = json.points;
		avgAccuracy = json.avgAccuracy;
		profileHue = json.profileHue;
		return loggedIn = true;
	}

	public static function requestRegister(username:String, email:String, ?code:String) {
		var response = requestAPI({
			path: "/api/network/auth/register",
			headers: ["content-type" => "application/json"],
			body: Json.stringify({
				username: username,
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

	static function saveCredentials(json:Dynamic) {
		trace("Saving credentials");
		Auth.save(json.id, json.token);
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
			headers: ["authorization" => Auth.getAuthHeader(), "content-type" => "application/json"],
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
			headers: ["authorization" => Auth.getAuthHeader(), "content-type" => "application/json"],
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
		}, false);

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
			headers: ["authorization" => Auth.getAuthHeader(), "content-type" => "application/json"],
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

	public static function fetchUserInfo(user:String):Dynamic {
		if (user == null)
			return null;

		var response = requestAPI({
			path: "/api/network/user/info?name=" + user
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

	public static var cacheAvatar:Map<String, Bytes> = [];
	public static function getUserAvatar(user:String):BitmapData {
		if (cacheAvatar.exists(user))
			return BitmapData.fromBytes(cacheAvatar.get(user));

		var output = new BytesOutput();
		var avatarResponse = FunkinNetwork.requestAPI({
			path: 'api/avatar/' + Base64.encode(Bytes.ofString(user)),
			bodyOutput: output
		});

		if (avatarResponse == null)
			return null;

		try {
			var bytes = output.getBytes();
			cacheAvatar.set(user, bytes);
			return BitmapData.fromBytes(bytes);
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
				if (alertError)
					Waiter.put(() -> {
						Alert.alert("Exception: " + request.path, ShitUtil.readableError(response.exception) + (response.exception.stack != null ? "\n\n" + CallStack.toString(response.exception.stack) : ""));
					});
			}
			else if (response.status == 404) {
				return null;
			}
			else if (alertError) {
				Waiter.put(() -> {
					Alert.alert('HTTP Error ${ShitUtil.prettyStatus(response.status)}: ' + request.path, response.body != null && response.body.ltrim().startsWith("{") ? Json.parse(response.body).error : response.body);
				});
			}
			return null;
		}

		return response;
	}
}