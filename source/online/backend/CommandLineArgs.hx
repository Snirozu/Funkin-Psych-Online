package online.backend;

import online.network.Leaderboard;
import online.network.URI;

class CommandLineArgs
{
	public static function init():Void
	{
		var args:Array<String> = Sys.args();

		while(args.length > 0)
		{
			switch(args.shift())
			{
				case '--replay':
					var replayID:Null<String> = args.shift();

					var replayDataContent:String = Leaderboard.fetchReplay(replayID);
					var replayData:Dynamic = haxe.Json.parse(replayDataContent);

					flixel.addons.transition.FlxTransitionableState.skipNextTransIn = true;
					flixel.addons.transition.FlxTransitionableState.skipNextTransOut = true;
					states.TitleState.playFreakyMusic(0);

					try {
						ReplayPlayer.loadReplay(replayData, replayID, true);
					} catch(e:haxe.Exception) {
						if(e.message == 'Could not find the mod by URL, does it need to be installed?')
						{
							online.mods.OnlineMods.downloadMod(replayData.mod_url, true, (modName:String) -> {
							Mods.updatedOnState = false;
								try {
									ReplayPlayer.loadReplay(replayData, replayID, true);
									LoadingState.loadAndSwitchState(new PlayState());
								} catch(e:haxe.Exception) {
									online.gui.Alert.alert('Error while loading Replay!', e.message);
									FlxG.switchState(new states.TitleState());
								}
							});

							FlxG.switchState(()->new MusicBeatState());
						}
						else
						{
							online.gui.Alert.alert('Error while loading Replay!', e.message);
						}
						return;
					}

					LoadingState.loadAndSwitchState(new PlayState());
			}
		}
	}
}