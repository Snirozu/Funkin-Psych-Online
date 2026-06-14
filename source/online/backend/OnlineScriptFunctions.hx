package online.backend;

import psychlua.FunkinLua;

class OnlineScriptFunctions {
	public static function implement(funk:FunkinLua) {
		var lua:State = funk.lua;

		funk.set("sendMessage", function(type:String, message:Dynamic) {
			online.GameClient.send("custom", [type, message]);
		});

		funk.set("sendMessageTo", function(toSID:String, type:String, message:Dynamic) {
			online.GameClient.send("customTo", [toSID, type, message]);
		});

		funk.set("playsAsBF", function() {
			return PlayState.playsAsBF();
		});

		funk.set("isRoomOwner", function() {
			return GameClient.isOwner;
		});

		funk.set("hasRoomPerms", function() {
			return GameClient.hasPerms();
		});

		funk.set("isRoomConnected", function() {
			return GameClient.isConnected();
		});

		funk.set("getRoomState", function() {
			return GameClient.room.state;
		});

		funk.set("listPlayers", function() {
			return [for (sid => player in GameClient.room.state.players) sid];
		});

		funk.set("listPlayersBySide", function(isBf:Bool) {
			var arr = [];
			for (sid => player in GameClient.room.state.players) {
				if (player.bfSide == isBf) {
					arr.push(sid);
				}
			}
			return arr;
		});

		funk.set("getPlayerSelf", function() {
			return GameClient.room.state.players.get(GameClient.room.sessionId);
		});

		funk.set("getPlayerSelfSID", function() {
			return GameClient.room.sessionId;
		});

		funk.set("getPlayer", function(playerSID:String) {
			return GameClient.room.state.players.get(playerSID);
		});

		funk.set("getPlayerAccuracy", function(playerSID:String) {
			return GameClient.getPlayerAccuracyPercent(GameClient.room.state.players.get(playerSID));
		});

		funk.set("getPlayerRating", function(playerSID:String) {
			return GameClient.getPlayerRating(GameClient.room.state.players.get(playerSID));
		});

		// UMM Shit (thanks adrim)
		funk.set('online', GameClient.isConnected());
		funk.set('localPlay', false);
		funk.set('leftSide', GameClient.isConnected() ? !PlayState.playsAsBF() : PlayState.opponentMode);
		funk.set("send", function(message:String, title:String) {
			online.GameClient.send("custom", [title, message]);
		});
		//

		// deprecated
		funk.set("getStateSong", function() {
			return GameClient.room.state.song;
		});
		funk.set("getStateFolder", function() {
			return GameClient.room.state.folder;
		});
		funk.set("getStateDiff", function() {
			return GameClient.room.state.diff;
		});
		funk.set("getStateModDir", function() {
			return GameClient.room.state.modDir;
		});
		funk.set("getStateModURL", function() {
			return GameClient.room.state.modURL;
		});
		funk.set("getStateIsPrivate", function() {
			return GameClient.room.state.isPrivate;
		});
		funk.set("getStateIsStarted", function() {
			return GameClient.room.state.isStarted;
		});
		funk.set("isSwapSides", function() {
			return !PlayState.playsAsBF();
		});
		funk.set("isAnarchyMode", function() {
			return GameClient.room.state.anarchyMode;
		});
	}
}