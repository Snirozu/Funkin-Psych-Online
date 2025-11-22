package online.network;

import haxe.Json;
import haxe.Http;

@:unreflective
class Leaderboard {
	public static var categories:Array<String> = [
		null,
		'week'
	];
	public static var categoryTitles:Array<String> = [
		'All Time',
		'Weekly'
	];

    public static function submitScore(replayData:String) {
		if (!FunkinNetwork.loggedIn)
            return null;

		return FunkinNetwork.requestAPI({
			path: "/api/score/submit",
			headers: [
				"content-type" => "application/json"
			],
			body: replayData,
			post: true
		});
    }

	public static function fetchLeaderboard(page:Int = 0, category:Null<String>, keys:Null<Int>, songID:String, callback:Array<TopScore>->Void) {
		Thread.run(() -> {
			var response = FunkinNetwork.requestAPI("/api/top/song?song=" + StringTools.urlEncode(songID) + "&strum=" + (ClientPrefs.getGameplaySetting('opponentplay') ? 1 : 2) + "&page=" + page + (category != null ? '&category=' + category : '') + (keys != null ? '&keys=' + keys : ''));

			if (response == null || response.isFailed()) {
				callback(null);
				return;
			}

			Waiter.put(() -> {
				callback(cast Json.parse(response.getString()));
			});
		});
	}

	public static function fetchPlayerLeaderboard(page:Int = 0, category:Null<String>, sort:Null<String>, callback:Array<Dynamic>->Void) {
		Thread.run(() -> {
			var response = FunkinNetwork.requestAPI("/api/top/players?page=" + page + (category != null ? '&category=' + category : '') + (sort != null ? '&sort=${sort}' : ''));

			if (response == null || response.isFailed()) {
				callback(null);
				return;
			}

			Waiter.put(() -> {
				callback(Json.parse(response.getString()));
			});
		});
	}

	public static function fetchReplay(scoreID:String) {
		var response = FunkinNetwork.requestAPI("/api/score/replay?id=" + StringTools.urlEncode(scoreID));

		if (response == null || response.isFailed())
			return null;

		return response.getString();
	}

	public static function reportScore(scoreID:String, desc:String) {
		var response = FunkinNetwork.requestAPI({
			path: "/api/score/report",
			headers: ["content-type" => "application/json"],
			body: Json.stringify({content: 'Score #${scoreID}\nReason: ' + desc}),
			post: true
		});

		if (response == null || response.isFailed())
			return null;

		return response.getString();
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
	var modURL:String;
	var sicks:Float;
	var goods:Float;
	var bads:Float;
	var shits:Float;
	var playbackRate:Float;
}