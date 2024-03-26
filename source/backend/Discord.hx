package backend;

import online.states.Room;
import online.Waiter;
import haxe.crypto.Md5;
import online.GameClient;
import Sys.sleep;
import discord_rpc.DiscordRpc;
import lime.app.Application;

class DiscordClient
{
	public static var isInitialized:Bool = false;
	private static var _defaultID:String = "1185697129717583982";
	public static var clientID(default, set):String = _defaultID;

	private static var _options:DiscordPresenceOptions = {
		details: "In the Menus",
		state: null,
		largeImageKey: 'icon',
		largeImageText: "Psych Engine",
		smallImageKey : null,
		startTimestamp : null,
		endTimestamp : null
	};

	public function new()
	{
		trace("Discord Client starting...");
		DiscordRpc.start({
			clientID: clientID,
			onReady: onReady,
			onError: onError,
			onDisconnected: onDisconnected,
			onRequest: onRequest,
			onJoin: onJoin
		});
		trace("Discord Client started.");

		var localID:String = clientID;
		while (localID == clientID)
		{
			DiscordRpc.process();
			sleep(2);
			//trace('Discord Client Update $localID');
		}

		//DiscordRpc.shutdown();
	}

	static function onRequest(req:Dynamic) {
		DiscordRpc.respond(req.userId, !GameClient.room.state.isPrivate ? Reply.Yes : Reply.No);
	}

	static function onJoin(secret:String) {
		Waiter.put(() -> {
			GameClient.joinRoom(secret, (err) -> {
				if (err != null) {
					return;
				}

				Waiter.put(() -> {
					FlxG.switchState(() -> new Room());
				});
			});
		});
	}

	public static function check()
	{
		if(!ClientPrefs.data.discordRPC)
		{
			if(isInitialized) shutdown();
			isInitialized = false;
		}
		else start();
	}
	
	public static function start()
	{
		if (!isInitialized && ClientPrefs.data.discordRPC) {
			initialize();
			Application.current.window.onClose.add(function() {
				shutdown();
			});
		}
	}

	public static function shutdown()
	{
		DiscordRpc.shutdown();
	}
	
	static function onReady()
	{
		DiscordRpc.presence(_options);
	}

	private static function set_clientID(newID:String)
	{
		var change:Bool = (clientID != newID);
		clientID = newID;

		if(change && isInitialized)
		{
			shutdown();
			isInitialized = false;
			start();
			DiscordRpc.process();
		}
		return newID;
	}

	static function onError(_code:Int, _message:String)
	{
		trace('Error! $_code : $_message');
	}

	static function onDisconnected(_code:Int, _message:String)
	{
		trace('Disconnected! $_code : $_message');
	}

	public static function initialize()
	{
		
		online.Thread.run(() -> {
			new DiscordClient();
		});
		trace("Discord Client initialized");
		isInitialized = true;
	}

	public static function changePresence(details:String, state:Null<String>, ?smallImageKey : String, ?hasStartTimestamp : Bool, ?endTimestamp: Float)
	{
		var startTimestamp:Float = 0;
		if (hasStartTimestamp) startTimestamp = Date.now().getTime();
		if (endTimestamp > 0) endTimestamp = startTimestamp + endTimestamp;

		_options.details = details;
		_options.state = state;
		_options.largeImageKey = 'icon';
		_options.largeImageText = "Engine Version: " + states.MainMenuState.psychEngineVersion + "*";
		_options.smallImageKey = smallImageKey;
		// Obtained times are in milliseconds so they are divided so Discord can use it
		_options.startTimestamp = Std.int(startTimestamp / 1000);
		_options.endTimestamp = Std.int(endTimestamp / 1000);
		updateOnlinePresence();
		//DiscordRpc.presence(_options);

		//trace('Discord RPC Updated. Arguments: $details, $state, $smallImageKey, $hasStartTimestamp, $endTimestamp');
	}

	public static function updateOnlinePresence() {
		if (GameClient.isConnected()) {
			if (!GameClient.room.state.isPrivate) {
				_options.partyID = GameClient.rpcClientRoomID;
				_options.joinSecret = GameClient.getRoomSecret(true);
				_options.state = "In a Public Room";
			}
			else {
				_options.partyID = null;
				_options.joinSecret = null;
				_options.state = "In a Private Room";
			}
			_options.partySize = GameClient.getPlayerCount();
			_options.partyMax = 2;
		}
		else {
			_options.partyID = null;
			_options.joinSecret = null;
			_options.partySize = 0;
			_options.partyMax = 0;
			_options.state = null;
		}
		DiscordRpc.presence(_options);
	}
	
	public static function resetClientID()
		clientID = _defaultID;

	#if MODS_ALLOWED
	public static function loadModRPC()
	{
		var pack:Dynamic = Mods.getPack();
		if(pack != null && pack.discordRPC != null && pack.discordRPC != clientID)
		{
			clientID = pack.discordRPC;
			//trace('Changing clientID! $clientID, $_defaultID');
		}
	}
	#end

	#if LUA_ALLOWED
	public static function addLuaCallbacks(lua:State) {
		Lua_helper.add_callback(lua, "changeDiscordPresence", function(details:String, state:Null<String>, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float) {
			changePresence(details, state, smallImageKey, hasStartTimestamp, endTimestamp);
		});

		Lua_helper.add_callback(lua, "changeDiscordClientID", function(?newID:String = null) {
			if(newID == null) newID = _defaultID;
			clientID = newID;
		});
	}
	#end
}
