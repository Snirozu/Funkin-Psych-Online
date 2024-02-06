package online;

import online.states.RequestState;
import openfl.net.URLRequestHeader;
import haxe.Json;
import openfl.Lib;
import sys.thread.Thread;
import sys.net.Socket;
import sys.net.Host;
import haxe.Http;

class GoogleAPI {
	@:unreflective
	private static final CLIENT_ID:String = "622220587393-vs0f932q0hf0alg9fqe82dqgof005nn4.apps.googleusercontent.com";

    public static function authorize(onAuthorize:Void->Void) {
		LoadingScreen.toggle(true);

		var AUTH_CODE = null;

		Thread.create(() -> {
			var server = new Socket();
			try {
				server.bind(new Host("localhost"), 8080);
			}
			catch (exc) {
				trace(exc);
				LoadingScreen.toggle(false);
				return;
			}
			server.listen(100);

			var authUrl = 'https://accounts.google.com/o/oauth2/v2/auth?scope=https://www.googleapis.com/auth/drive.readonly&response_type=code&redirect_uri=http://localhost:8080&client_id=$CLIENT_ID';

			LoadingScreen.toggle(false);
			Waiter.put(() -> {
				RequestState.request("Do you want to link your Google account to download files from Google Drive?", authUrl, _ -> {
					LoadingScreen.toggle(true);

					FlxG.openURL(authUrl);

					Thread.create(() -> {			
						var waitingAuthentication = true;
						while (waitingAuthentication) {
							try {
								var client = server.accept();
								var msg:HTMLRequest = parseHTMLRequest(client.input.readLine());
								var response:String = null;

								if (msg.queries.exists("error")) {
									response = 'Error: ${msg.queries.get("error")}, try again.';
									waitingAuthentication = false;
								}
								else if (msg.queries.exists("code")) {
									AUTH_CODE = msg.queries.get("code");
									response = "Authorized! You can go back to the game now.";
									waitingAuthentication = false;
								}

								if (response == null)
									client.write('HTTP/1.1 404 Not Found');
								else
									client.write('HTTP/1.1 200 OK\nContent-Length: ${response.length}\nContent-Type: text/html\n\n$response');
							}
							catch (e:Dynamic) {
								trace("Caught error: " + e);
								break;
							}
						}

						server.close();
						LoadingScreen.toggle(false);

						Lib.application.window.focus();
						Lib.application.window.minimized = false;

						if (AUTH_CODE != null) {
							authorizeCode(AUTH_CODE, onAuthorize);
						}
						else {
							Alert.alert("Authorization failed!", "Authorization Code was not found");
						}
					});
				}, () -> {}, true);
			});
        });
    }

	static function authorizeCode(authCode:String, onAuthorize:Void->Void) {
		LoadingScreen.toggle(true);

		Thread.create(() -> {
			var http = new Http(GameClient.addressToUrl(GameClient.defaultAddress) + "/api/google/token/auth");
			http.addParameter('code', authCode);

			http.onData = function(data:String) {
				LoadingScreen.toggle(false);

				var json = Json.parse(data);

				Waiter.put(() -> {
					if (json.error != null) {					
						Alert.alert("Failed during authorization!", json.error + ": " + json.error_description);
						return;
					}

					Wrapper.prefGapiRefreshToken = json.refresh_token;
					Wrapper.prefGapiAccessToken = json.access_token;
					Wrapper.prefGapiAccessExpires = Sys.time() + Std.int(json.expires_in);
					ClientPrefs.saveSettings();
					onAuthorize();
				});
			}

			http.onError = function(error) {
				LoadingScreen.toggle(false);

				Waiter.put(() -> {
					Alert.alert("Failed during authorization!", error);
				});
			}

			http.request();
		});
	}

	static function refreshAccess(onSuccess:Void->Void) {
		LoadingScreen.toggle(true);

		Thread.create(() -> {
			var http = new Http(GameClient.addressToUrl(GameClient.defaultAddress) + "/api/google/token/refresh");
			http.addParameter('refresh_token', Wrapper.prefGapiRefreshToken);

			http.onData = function(data:String) {
				LoadingScreen.toggle(false);

				var json = Json.parse(data);

				Waiter.put(() -> {
					if (json.error != null) {
						Alert.alert("Failed during authorization!", json.error + ": " + json.error_description);
						return;
					}

					Wrapper.prefGapiAccessToken = json.access_token;
					Wrapper.prefGapiAccessExpires = Sys.time() + Std.int(json.expires_in);
					ClientPrefs.saveSettings();
					onSuccess();
				});
			}

			http.onError = function(error) {
				LoadingScreen.toggle(false);

				Waiter.put(() -> {
					Alert.alert("Failed during authorization!", error);
				});
			}

			http.request();
		});
	}

	public static function revokeAccess(onSuccess:Void->Void) {
		LoadingScreen.toggle(true);

		Thread.create(() -> {
			var http = new Http('https://oauth2.googleapis.com/revoke?token=${Wrapper.prefGapiRefreshToken}');
			http.addHeader('Content-Length', '0');

			http.onData = function(data:String) {
				LoadingScreen.toggle(false);

				Waiter.put(() -> {
					Wrapper.prefGapiRefreshToken = null;
					Wrapper.prefGapiAccessToken = null;
					Wrapper.prefGapiAccessExpires = 0;
					ClientPrefs.saveSettings();
					onSuccess();
				});
			}

			http.onError = function(error) {
				LoadingScreen.toggle(false);

				Waiter.put(() -> {
					Alert.alert("Failed during authorization!", error);
				});
			}

			http.request(true);
		});
	}

	public static function downloadFromDrive(id:String, onSuccess:String->Void) {
		if (Wrapper.prefGapiRefreshToken == null) {
			authorize(() -> {
				downloadFromDrive(id, onSuccess);
			});
			return;
		}
		if (Sys.time() >= Wrapper.prefGapiAccessExpires) {
			refreshAccess(() -> {
				downloadFromDrive(id, onSuccess);
			});
			return;
		}

		LoadingScreen.toggle(true);

		Thread.create(() -> {
			var http = new Http('https://www.googleapis.com/drive/v3/files/$id');
			http.addHeader("Authorization", 'Bearer ${Wrapper.prefGapiAccessToken}');

			http.onData = function(data:String) {
				LoadingScreen.toggle(false);

				var json = Json.parse(data);

				Waiter.put(() -> {
					if (json.error != null) {
						Alert.alert("Failed during GDrive downloading!", json.error + ": " + json.error_description);
						return;
					}

					if (!FileUtils.isArchiveSupported(json.name)) {
						Waiter.put(() -> {
							Alert.alert("Failed to download!", "Unsupported file archive type!\n(Only ZIP, TAR, TGZ archives are supported!)");
							RequestState.requestURL('https://drive.google.com/file/d/$id', "The following mod needs to be installed from this source", true);
						});
						return;
					}

					OnlineMods.startDownloadMod(json.name, 'https://www.googleapis.com/drive/v3/files/$id?alt=media', null, onSuccess, [
						"Authorization" => 'Bearer ${Wrapper.prefGapiAccessToken}'
					]);
				});
			}

			http.onError = function(error) {
				Waiter.put(() -> {
					LoadingScreen.toggle(false);
					Alert.alert("Couldn't get file from GDrive", error);
				});
			}

			http.request();
		});
    }

	static function parseHTMLRequest(req:String):HTMLRequest {
		//parse "GET / HTML/1.1"
		var content:String = req.substring(req.indexOf("/") + 1, req.lastIndexOf(" "));

		//parse queries
		var parseIndex:Int = 0;
		var _char:String;

		var	reqDest:String = null;
		var _parts:String = "";
		while (reqDest == null) {
			_char = content.charAt(parseIndex);
			if (parseIndex >= content.length || _char == "?") {
				reqDest = _parts;
				parseIndex++;
				break;
			}
			_parts += _char;
			parseIndex++;
		}

		var reqQueries:Map<String, String> = new Map<String, String>();
		var _parts:Array<String> = ["", ""];
		var _inValue:Bool = false;
		while (parseIndex <= content.length) {
			_char = content.charAt(parseIndex);

			if (parseIndex >= content.length || _char == "&") {
				reqQueries.set(_parts[0], _parts[1]);
				_inValue = false;
				_parts = ["", ""];
				parseIndex++;
				if (_char == "&") {
					continue;
				}
				break;
			}

			if (_char == "=") {
				_inValue = true;
				parseIndex++;
				continue;
			}

			_parts[!_inValue ? 0 : 1] += _char;
			parseIndex++;
		}

		return {
			dest: reqDest,
			queries: reqQueries
		};
	}
}

typedef HTMLRequest = {
	var dest:String;
	var queries:Map<String, String>;
}