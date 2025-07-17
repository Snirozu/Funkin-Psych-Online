package online.network;

import openfl.Assets;
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

	public static function deleteAccount(?code:String) {
		var response = requestAPI("/api/account/delete" + (code != null ? '?code=' + code : ''));

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

		Waiter.putPersist(() -> {
			if (!online.gui.sidebar.SideUI.instance.active)
				online.gui.sidebar.SideUI.instance.active = true;
		});
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
	public static function getUserAvatar(user:String):Bytes {
		if (cacheAvatar.exists(user)) {
			var bytes = cacheAvatar.get(user);
			return bytes;
		}

		var avatarResponse = FunkinNetwork.requestAPI('/api/avatar/' + StringTools.urlEncode(user), false);

		var bytes = avatarResponse?.getBytes() ?? null;
		if (bytes == null || !ShitUtil.isSupportedImage(bytes)) {
			cacheAvatar.set(user, null);
			return null;
		}

		try {
			cacheAvatar.set(user, bytes);
			return bytes;
		}
		catch (exc) {
			trace(exc);
			return null;
		}
	}

	public static function getDefaultAvatar():BitmapData {
		return Assets.getBitmapData('assets/images/' + 'bf' + FlxG.random.int(1, 2) + '.png');
	}

	public static function requestAPI(data:OneOf<HTTPRequest, String>, ?alertError:Bool = true):Null<HTTPResponse> {
		GameClient.asyncUpdateAddresses();

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
			if (alertError)
				Waiter.putPersist(() -> {
					var errorDetails = response.exception != null ? response.getErrorDetails() : (
						response.getString() != null && response.getString()
							.ltrim()
							.startsWith("{") ? Json.parse(response.getString())
							.error : response.getString()
					);
					Alert.alert(response.getErrorTitle(), errorDetails);
				});
			return null;
		}

		return response;
	}
}