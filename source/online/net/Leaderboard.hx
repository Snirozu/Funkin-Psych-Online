package online.net;

import haxe.Json;
import haxe.Http;

@:unreflective
class Leaderboard {
    public static function submitScore(replayData:String) {
		if (!FunkinNetwork.loggedIn)
            return null;

		return FunkinNetwork.requestAPI({
			path: "/api/network/score/submit",
			headers: [
				"authorization" => FunkinNetwork.getAuthHeader(),
				"content-type" => "application/json"
			],
			body: replayData,
			post: true
		});
    }

	public static function fetchLeaderboard(page:Int = 0, songID:String, callback:Array<TopScore>->Void) {
		Thread.run(() -> {
			var response = FunkinNetwork.requestAPI({
				path: "/api/network/top/song?song=" + songID + "&strum=" + (ClientPrefs.getGameplaySetting('opponentplay') ? 1 : 2) + "&page=" + page,
				headers: ["authorization" => FunkinNetwork.getAuthHeader()]
			});

			if (response == null) {
				callback(null);
				return;
			}

			Waiter.put(() -> {
				callback(cast Json.parse(response.body));
			});
		});
	}

	public static function fetchPlayerLeaderboard(page:Int = 0, callback:Array<Dynamic>->Void) {
		Thread.run(() -> {
			var response = FunkinNetwork.requestAPI({
				path: "/api/network/top/players?page=" + page,
				headers: ["authorization" => FunkinNetwork.getAuthHeader()]
			});

			if (response == null) {
				callback(null);
				return;
			}

			Waiter.put(() -> {
				callback(Json.parse(response.body));
			});
		});
	}

	public static function fetchReplay(scoreID:String) {
		var response = FunkinNetwork.requestAPI({
			path: "/api/network/score/replay?id=" + scoreID,
			headers: ["authorization" => FunkinNetwork.getAuthHeader()]
		});

		if (response == null)
			return null;

		return response.body;
	}

	public static function reportScore(scoreID:String) {
		var response = FunkinNetwork.requestAPI({
			path: "/api/network/score/report",
			headers: ["authorization" => FunkinNetwork.getAuthHeader(), "content-type" => "application/json"],
			body: Json.stringify({content: 'Score #${scoreID}'}),
			post: true
		});

		if (response == null)
			return null;

		return response.body;
	}
}

typedef TopScore = {
	var score:Float;
	var accuracy:Float;
	var points:Float;
	var player:String;
	var submitted:String;
	var id:String;
	var misses:Float;
}