package online.substates;

import flixel.util.FlxStringUtil;
import online.network.FunkinNetwork;
import openfl.filters.BlurFilter;
import online.network.Leaderboard;

class TopPlayerSubstate extends MusicBeatSubstate {
	var topShit:Scoreboard = new Scoreboard(FlxG.width - 300, 35, 15, ["PLAYER", "POINTS"]);

	var blurFilter:BlurFilter;
	var coolCam:FlxCamera;

    var curPage:Int = 0;
    var curSelected(default, set):Int = -2;
	var curCategory:Int = 0;
	var curKeys:Int = 4;

	var categoryTxt:FlxText;
	var keysTxt:FlxText;

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

		categoryTxt = new FlxText(0, 20);
		categoryTxt.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(categoryTxt);

		keysTxt = new FlxText(0, 50);
		keysTxt.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(keysTxt);
    }

    var top:Array<Dynamic> = [];
	var leaderboardTimer:FlxTimer;
	function generateLeaderboard() {
		topShit.clearRows();
		topShit.selectRow(curSelected = (curSelected < 0 ? curSelected : 0));

		categoryTxt.text = '< ${Leaderboard.categoryTitles[curCategory]} >';
		categoryTxt.screenCenter(X);

		keysTxt.text = '< ${curKeys}k >';
		keysTxt.screenCenter(X);

		try {
			var sortProp = 'points${curKeys}k';
			Leaderboard.fetchPlayerLeaderboard(curPage, Leaderboard.categories[curCategory], sortProp, top -> {
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
					topShit.setRow(i, [
						(i + 1 + curPage * 15) + ". " + top[i].player,
						FlxStringUtil.formatMoney(Reflect.field(top[i], sortProp), false)
					], coolColor);
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

		if (controls.UI_LEFT_P && (curSelected < 0 || curPage != 0)) {
			if (curSelected == -2) {
				curPage = 0;
				curCategory--;
				if (curCategory < 0)
					curCategory = Leaderboard.categories.length - 1;
			}
			else if (curSelected == -1) {
				curPage = 0;
				curKeys--;
				if (curKeys < 4)
					curKeys = 9;
			}
			else 
            	curPage--;
            if (curPage < 0)
                curPage = 0;

			LoadingScreen.toggle(true);
			if (leaderboardTimer != null)
				leaderboardTimer.cancel();
			leaderboardTimer = new FlxTimer().start(0.5, t -> { generateLeaderboard(); });
        }
        else if (controls.UI_RIGHT_P) {
			if (curSelected == -2) {
				curPage = 0;
				curCategory++;
				if (curCategory >= Leaderboard.categories.length)
					curCategory = 0;
			}
			else if (curSelected == -1) {
				curPage = 0;
				curKeys++;
				if (curKeys > 9)
					curKeys = 4;
			}
			else
				curPage++;

			LoadingScreen.toggle(true);
			if (leaderboardTimer != null)
				leaderboardTimer.cancel();
			leaderboardTimer = new FlxTimer().start(0.5, t -> { generateLeaderboard(); });
        }
		else if (controls.UI_UP_P || FlxG.mouse.wheel > 0) {
			curSelected--;
			if (curSelected < -2)
				curSelected = 14;
			topShit.selectRow(curSelected);
		}
		else if (controls.UI_DOWN_P || FlxG.mouse.wheel < 0) {
			curSelected++;
			if (curSelected > 14)
				curSelected = -2;
			topShit.selectRow(curSelected);
		}
        else if (controls.BACK) {
			LoadingScreen.toggle(false);
            close();
        }
        else if (controls.ACCEPT || FlxG.mouse.justPressed) {
			if (top[curSelected] != null)
				online.gui.sidebar.tabs.ProfileTab.view(top[curSelected].player);
        }
    }

	function set_curSelected(v) {
		categoryTxt.alpha = v == -2 ? 1 : 0.7;
		keysTxt.alpha = v == -1 ? 1 : 0.7;
		return curSelected = v;
	}
}