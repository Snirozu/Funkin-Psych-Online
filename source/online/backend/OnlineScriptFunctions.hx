package online.backend;

import psychlua.FunkinLua;

class OnlineScriptFunctions {
	public static function implement(funk:FunkinLua) {
		var lua:State = funk.lua;

		Lua_helper.add_callback(lua, "sendMessage", function(type:String, message:Dynamic) {
			online.GameClient.send("custom", [type, message]);
		});

		Lua_helper.add_callback(lua, "sendMessageTo", function(toSID:String, type:String, message:Dynamic) {
			online.GameClient.send("customTo", [toSID, type, message]);
		});

		Lua_helper.add_callback(lua, "playsAsBF", function() {
			return PlayState.playsAsBF();
		});

		Lua_helper.add_callback(lua, "isRoomOwner", function() {
			return GameClient.isOwner;
		});

		Lua_helper.add_callback(lua, "hasRoomPerms", function() {
			return GameClient.hasPerms();
		});

		Lua_helper.add_callback(lua, "isRoomConnected", function() {
			return GameClient.isConnected();
		});

		Lua_helper.add_callback(lua, "getRoomState", function() {
			return GameClient.room.state;
		});

		Lua_helper.add_callback(lua, "listPlayers", function() {
			return [for (sid => player in GameClient.room.state.players) sid];
		});

		Lua_helper.add_callback(lua, "listPlayersBySide", function(isBf:Bool) {
			var arr = [];
			for (sid => player in GameClient.room.state.players) {
				if (player.bfSide == isBf) {
					arr.push(sid);
				}
			}
			return arr;
		});

		Lua_helper.add_callback(lua, "getPlayerSelf", function() {
			return GameClient.room.state.players.get(GameClient.room.sessionId);
		});

		Lua_helper.add_callback(lua, "getPlayerSelfSID", function() {
			return GameClient.room.sessionId;
		});

		Lua_helper.add_callback(lua, "getPlayer", function(playerSID:String) {
			return GameClient.room.state.players.get(playerSID);
		});

		Lua_helper.add_callback(lua, "getPlayerAccuracy", function(playerSID:String) {
			return GameClient.getPlayerAccuracyPercent(GameClient.room.state.players.get(playerSID));
		});

		Lua_helper.add_callback(lua, "getPlayerRating", function(playerSID:String) {
			return GameClient.getPlayerRating(GameClient.room.state.players.get(playerSID));
		});

		// UMM Shit (thanks adrim)
		funk.set('online', GameClient.isConnected());
		funk.set('localPlay', false);
		funk.set('leftSide', GameClient.isConnected() ? !PlayState.playsAsBF() : PlayState.opponentMode);
		Lua_helper.add_callback(lua, "send", function(message:String, title:String) {
			online.GameClient.send("custom", [title, message]);
		});
		//

		// deprecated
		Lua_helper.add_callback(lua, "getStateSong", function() {
			return GameClient.room.state.song;
		});
		Lua_helper.add_callback(lua, "getStateFolder", function() {
			return GameClient.room.state.folder;
		});
		Lua_helper.add_callback(lua, "getStateDiff", function() {
			return GameClient.room.state.diff;
		});
		Lua_helper.add_callback(lua, "getStateModDir", function() {
			return GameClient.room.state.modDir;
		});
		Lua_helper.add_callback(lua, "getStateModURL", function() {
			return GameClient.room.state.modURL;
		});
		Lua_helper.add_callback(lua, "getStateIsPrivate", function() {
			return GameClient.room.state.isPrivate;
		});
		Lua_helper.add_callback(lua, "getStateIsStarted", function() {
			return GameClient.room.state.isStarted;
		});
		Lua_helper.add_callback(lua, "isSwapSides", function() {
			return !PlayState.playsAsBF();
		});
		Lua_helper.add_callback(lua, "isAnarchyMode", function() {
			return GameClient.room.state.anarchyMode;
		});
	}
}