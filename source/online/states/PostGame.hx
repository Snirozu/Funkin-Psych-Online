package online.states;

import online.schema.Player;

class PostGame extends MusicBeatState {
    var disableInput = true;

	var win:FlxSprite;
	var winText:Alphabet;
	var lose:FlxSprite;
	var loseText:Alphabet;
	var back:FlxSprite;

	var p1Accuracy:Float;
	var p2Accuracy:Float;

	var winner:Player;
	var loser:Player;
	var winnerAccuracy:Float;
	var loserAccuracy:Float;

	var chatBox:ChatBox;

    override function create() {
        super.create();
        
        FlxG.sound.music.stop();

		FlxG.sound.playMusic(Paths.music('breakfast'), 0);
		FlxG.sound.music.fadeIn(2, 0, 0.5);

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xff353535;
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

		win = new FlxSprite();
		win.antialiasing = ClientPrefs.data.antialiasing;
		win.frames = Paths.getSparrowAtlas('onlineJudges');
		win.animation.addByPrefix('idle', "weiner", 24);
		win.animation.play('idle');
		win.updateHitbox();
		win.screenCenter(X);
		win.y = 25;
        win.alpha = 0;
		add(win);

		winText = new Alphabet(0, 0, "", false);
		winText.antialiasing = ClientPrefs.data.antialiasing;
		winText.screenCenter(X);
		winText.y = win.y + win.height + 10;
		winText.scaleX = 0.55;
		winText.scaleY = 0.55;
		winText.alpha = 0;
		add(winText);

		lose = new FlxSprite();
		lose.antialiasing = ClientPrefs.data.antialiasing;
		lose.frames = Paths.getSparrowAtlas('onlineJudges');
		lose.animation.addByPrefix('idle', "loser", 24);
		lose.animation.play('idle');
		lose.updateHitbox();
		lose.screenCenter(X);
		lose.y = 375;
		lose.alpha = 0;
		add(lose);

		loseText = new Alphabet(0, 0, "", false);
		loseText.antialiasing = ClientPrefs.data.antialiasing;
		loseText.screenCenter(X);
		loseText.y = lose.y + lose.height + 10;
		loseText.scaleX = 0.5;
		loseText.scaleY = 0.5;
		loseText.alpha = 0;
		add(loseText);

		back = new FlxSprite();
		back.antialiasing = ClientPrefs.data.antialiasing;
		back.frames = Paths.getSparrowAtlas('backspace');
		back.animation.addByPrefix('idle', "backspace to exit white", 24);
		back.animation.addByPrefix('black', "backspace to exit0", 24);
		back.animation.addByPrefix('press', "backspace PRESSED", 24);
		back.animation.play('idle');
		back.updateHitbox();
		back.x = 30;
		back.y = FlxG.height - back.height - 30;
		back.alpha = 0;
		add(back);

		chatBox = new ChatBox();
		chatBox.y = FlxG.height - chatBox.height;
		add(chatBox);

		var _p1Accuracy = GameClient.getPlayerAccuracyPercent(GameClient.room.state.player1);
		var _p2Accuracy = GameClient.getPlayerAccuracyPercent(GameClient.room.state.player2);

		if (p1Accuracy >= p2Accuracy) {
			winnerAccuracy = _p1Accuracy;
			loserAccuracy = _p2Accuracy;
			winner = GameClient.room.state.player1;
			loser = GameClient.room.state.player2;
        }
        else {
			winnerAccuracy = _p2Accuracy;
			loserAccuracy = _p1Accuracy;
			winner = GameClient.room.state.player2;
			loser = GameClient.room.state.player1;
        }

		winText.text = '${winner.name}\nAccuracy: ${winnerAccuracy}% - ${getCoolRating(winner)}\nMisses: ${winner.misses}\nScore: ${winner.score}';
		loseText.text = '${loser.name}\nAccuracy: ${loserAccuracy}% - ${getCoolRating(loser)}\nMisses: ${loser.misses}\nScore: ${loser.score}';

		winText.screenCenter(X);
		loseText.screenCenter(X);
		winText.y -= 35;
		loseText.y -= 30;
		for (letter in winText.letters) {
			if (letter != null) {
				letter.colorTransform.redOffset = 230;
				letter.colorTransform.greenOffset = 230;
				letter.colorTransform.blueOffset = 230;
			}
        }
		for (letter in loseText.letters) {
			if (letter != null) {
				letter.colorTransform.redOffset = 230;
				letter.colorTransform.greenOffset = 230;
				letter.colorTransform.blueOffset = 230;
            }
		}

		FlxTween.tween(win, {alpha: 1}, 0.5, {ease: FlxEase.quadInOut});
		FlxTween.tween(winText, {alpha: 1}, 0.5, {ease: FlxEase.quartInOut, startDelay: 1.0});
		FlxTween.tween(lose, {alpha: 1, angle: 3}, 0.5, {ease: FlxEase.quadInOut, startDelay: 2.0});
		FlxTween.tween(lose, {angle: 0}, 0.2, {ease: FlxEase.quadInOut, startDelay: 3.0});
		FlxTween.tween(loseText, {alpha: 1}, 0.5, {ease: FlxEase.quartInOut, startDelay: 3.0});
		FlxTween.tween(back, {alpha: 1}, 1, {ease: FlxEase.quartInOut, startDelay: 4.0});

		new FlxTimer().start(5, (t) -> {
			disableInput = false;
		});
    }

	override function update(elapsed) {
        super.update(elapsed);

		if (!disableInput) {
			if (back.animation.curAnim.name != "press")
				back.animation.play('idle');

			if (!chatBox.focused && !FlxG.keys.justPressed.TAB && controls.ACCEPT || controls.BACK || FlxG.keys.justPressed.BACKSPACE) {
				FlxG.sound.music.stop();
				FlxG.sound.play(Paths.sound('cancelMenu'));

				disableInput = true;
				back.animation.play('press');
				back.offset.set(20, 50);
                new FlxTimer().start(0.5, (t) -> {
					GameClient.clearOnMessage();
					MusicBeatState.switchState(new Room());
                });
            }
        }
        else {
			if (back.animation.curAnim.name != "press")
				back.animation.play('black');
        }
    }

    function getCoolRating(player:Player) {
		var ratingFC = 'Clear';
		if (player.misses < 1) {
			if (player.bads > 0 || player.shits > 0)
				ratingFC = 'FC';
			else if (player.goods > 0)
				ratingFC = 'GFC';
			else if (player.sicks > 0)
				ratingFC = 'SFC';
		}
		else if (player.misses < 10)
			ratingFC = 'SDCB';
		return ratingFC;
    }
}