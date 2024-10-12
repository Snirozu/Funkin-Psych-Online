package online.substates;

import online.network.FunkinNetwork;
import openfl.filters.BlurFilter;
import online.network.Leaderboard;

class TopPlayerSubstate extends MusicBeatSubstate {
	var topShit:Scoreboard = new Scoreboard(FlxG.width - 300, 35, 15, ["PLAYER", "POINTS"]);

	var blurFilter:BlurFilter;
	var coolCam:FlxCamera;

    var curPage:Int = 0;
    var curSelected:Int = 0;

	override function create() {
		super.create();

		blurFilter = new BlurFilter();
		for (cam in FlxG.cameras.list) {
			if (cam.filters == null)
				cam.filters = [];
			cam.filters.push(blurFilter);
		}

		coolCam = new FlxCamera();
		coolCam.bgColor.alpha = 0;
		FlxG.cameras.add(coolCam, false);

		cameras = [coolCam];
        
		topShit.screenCenter(XY);
		LoadingScreen.toggle(true);
		if (leaderboardTimer != null)
			leaderboardTimer.cancel();
		leaderboardTimer = new FlxTimer().start(0.5, t -> { generateLeaderboard(); });
		add(topShit);
    }

    var top:Array<Dynamic> = [];
	var leaderboardTimer:FlxTimer;
	function generateLeaderboard() {
		topShit.clearRows();
		topShit.selectRow(curSelected = 0);

		try {
			Leaderboard.fetchPlayerLeaderboard(curPage, top -> {
				LoadingScreen.toggle(false);
				if (!topShit.exists)
					return;

                this.top = top ?? [];

				if (top == null) {
                    close();
                    return;
                }

				var coolColor:Null<FlxColor> = null;
				for (i in 0...top.length) {
					if (curPage == 0) {
						switch (i) {
							case 0:
								coolColor = FlxColor.ORANGE;
							default:
								coolColor = null;
						}
					}
					topShit.setRow(i, [(i + 1 + curPage * 15) + ". " + top[i].player, top[i].points], coolColor);
				}
			});
		}
		catch (e:Dynamic) {
			LoadingScreen.toggle(false);
		}
	}

	override function destroy() {
		super.destroy();

		if (leaderboardTimer != null)
			leaderboardTimer.cancel();

		for (cam in FlxG.cameras.list) {
			if (cam?.filters != null)
				cam.filters.remove(blurFilter);
		}
		FlxG.cameras.remove(coolCam);
	}

    override function update(elapsed) {
        super.update(elapsed);

        if (controls.UI_LEFT_P && curPage != 0) {
            curPage--;
            if (curPage < 0)
                curPage = 0;

			LoadingScreen.toggle(true);
			if (leaderboardTimer != null)
				leaderboardTimer.cancel();
			leaderboardTimer = new FlxTimer().start(0.5, t -> { generateLeaderboard(); });
        }
        else if (controls.UI_RIGHT_P) {
            curPage++;

			LoadingScreen.toggle(true);
			if (leaderboardTimer != null)
				leaderboardTimer.cancel();
			leaderboardTimer = new FlxTimer().start(0.5, t -> { generateLeaderboard(); });
        }
		else if (controls.UI_UP_P) {
			curSelected--;
			if (curSelected < 0)
				curSelected = 14;
			topShit.selectRow(curSelected);
		}
		else if (controls.UI_DOWN_P) {
			curSelected++;
			if (curSelected > 14)
				curSelected = 0;
			topShit.selectRow(curSelected);
		}
        else if (controls.BACK) {
			LoadingScreen.toggle(false);
            close();
        }
        else if (controls.ACCEPT) {
			if (top[curSelected] != null)
				FlxG.openURL(FunkinNetwork.client.getURL("/network/user/" + top[curSelected].player));
        }
    }
}