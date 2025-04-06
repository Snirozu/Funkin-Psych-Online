package online.network;

import online.http.HTTPClient;
import haxe.io.BytesOutput;
import openfl.display.BitmapData;
import online.http.HTTPHandler;
import haxe.CallStack;
import openfl.net.FileReference;
import haxe.io.Bytes;
import haxe.crypto.Base64;
import lime.ui.FileDialog;
import haxe.Http;
import haxe.Json;
import online.objects.NicommentsView.SongComment;
import haxe.ds.Either;

@:unreflective
class FunkinNetwork {
	public static var client:HTTPHandler = null;
	public static var nickname(default, null):String = null;
	public static var points(default, null):Float = 0;
	public static var avgAccuracy(default, null):Float = 0;
	public static var profileHue(default, null):Float = 0;
	public static var loggedIn:Bool = false;

	public static function requestLogin(email:String, ?code:String) {
		var response = requestAPI({
			path: "/api/auth/login",
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
			saveCredentials(Json.parse(response.getString()));

		return true;
	}

	public static function setEmail(email:String, ?code:String) {
		var emailSplit = email.trim().split(' from ');

		var response = requestAPI({
			path: "/api/account/email/set",
			headers: ["content-type" => "application/json"],
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
		var response = requestAPI("/api/account/delete");

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
		NetworkClient.leave();
	}

	public static function ping():Bool {
		if (Auth.authID == null || Auth.authToken == null)
			return loggedIn = false;

		var response = requestAPI("/api/account/me", false);

		if (response == null)
			return loggedIn = false;

		var json = Json.parse(response.getString());
		nickname = json.name;
		points = json.points;
		avgAccuracy = json.avgAccuracy;
		profileHue = json.profileHue;
		loggedIn = true;
		NetworkClient.connect();
		return loggedIn;
	}

	public static function requestRegister(username:String, email:String, ?code:String) {
		var response = requestAPI({
			path: "/api/auth/register",
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
			saveCredentials(Json.parse(response.getString()));

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
			path: "/api/account/rename",
			headers: ["content-type" => "application/json"],
			body: Json.stringify({
				username: name
			}),
			post: true
		});

		if (response == null)
			return nickname;

		return nickname = response.getString();
	}

	public static function postFrontMessage(message:String):Bool {
		var response = requestAPI({
			path: "/api/sez",
			headers: ["content-type" => "application/json"],
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
		var response = requestAPI("/api/front", false);

		if (response == null)
			return null;

		try {
			return Json.parse(response.getString());
		}
		catch (exc) {
			trace(exc);
			return null;
		}
	}

	public static function fetchSongComments(songId:String):Array<SongComment> {
		var response = requestAPI("/api/song/comments?id=" + StringTools.urlEncode(songId));

		if (response == null)
			return null;

		try {
			return Json.parse(response.getString());
		}
		catch (exc) {
			trace(exc);
			return null;
		}
	}

	public static function postSongComment(songId:String, content:String, at:Float):Array<SongComment> {
		var response = requestAPI({
			path: "/api/song/comment",
			headers: ["content-type" => "application/json"],
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
			return Json.parse(response.getString());
		}
		catch (exc) {
			trace(exc);
			return null;
		}
	}

	public static function fetchUserInfo(user:String):Dynamic {
		if (user == null)
			return null;

		var response = requestAPI("/api/user/info?name=" + StringTools.urlEncode(user));

		if (response == null)
			return null;

		try {
			return Json.parse(response.getString());
		}
		catch (exc) {
			trace(exc);
			return null;
		}
	}

	public static var cacheAvatar:Map<String, Bytes> = [];
	public static function getUserAvatar(user:String):BitmapData {
		if (cacheAvatar.exists(user)) {
			var bytes = cacheAvatar.get(user);
			if (bytes == null)
				return getDefaultAvatar();
			return BitmapData.fromBytes(bytes);
		}

		var avatarResponse = FunkinNetwork.requestAPI('/api/avatar/' + StringTools.urlEncode(user), false);

		var bytes = avatarResponse?.getBytes() ?? null;
		if (bytes == null || !ShitUtil.isSupportedImage(bytes)) {
			cacheAvatar.set(user, null);
			return getDefaultAvatar();
		}

		try {
			cacheAvatar.set(user, bytes);
			return BitmapData.fromBytes(bytes);
		}
		catch (exc) {
			trace(exc);
			return getDefaultAvatar();
		}
	}

	public static function getDefaultAvatar():BitmapData
	{
		return Paths.image('bf' + FlxG.random.int(1, 2), null, false).bitmap;
	}

	public static function requestAPI(data:OneOf<HTTPRequest, String>, ?alertError:Bool = true):Null<HTTPResponse> {
		var request:HTTPRequest;

		switch (data) {
			case Left(v):
				request = v;
			case Right(v):
				request = {
					path: v
				};
			case null:
				request = {};
		}

		if (request.headers == null)
			request.headers = new Map<String, String>();

		if (Auth.authID != null && Auth.authToken != null)
			request.headers.set("authorization", Auth.getAuthHeader());
		
		var response = client.request(request);

		if (response.isFailed()) {
			if (response.exception != null) {
				if (alertError)
					Waiter.put(() -> {
						Alert.alert("Exception: " + request.path, ShitUtil.readableError(response.exception) + (response.exception.stack != null ? "\n\n" + CallStack.toString(response.exception.stack) : ""));
					});
			}
			else if (alertError) {
				Waiter.put(() -> {
					Alert.alert('HTTP Error ${ShitUtil.prettyStatus(response.status)}: ' + request.path, response.getString() != null && 
					response.getString()
						.ltrim()
						.startsWith("{") ? Json.parse(response.getString())
						.error : response.getString());
				});
			}
			return null;
		}

		return response;
	}
}