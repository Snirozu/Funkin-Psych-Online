package online.states;

import flixel.util.FlxSpriteUtil;
import flixel.effects.FlxFlicker;
import sys.FileSystem;
import objects.Character;
import online.schema.Player;

class ResultsScreen extends MusicBeatState {
	public static var gainedPoints:Float = 0;

    var disableInput = true;

	var win:FlxSprite;
	var lose:FlxSprite;
	var back:FlxSprite;

	var p1Text:Alphabet;
	var p2Text:Alphabet;

	var gainedText:FlxText;

	var p1Accuracy:Float;
	var p2Accuracy:Float;

	var winner:Int;

	var chatBox:ChatBox;

	var p1:Character;
	var p2:Character;

	var dim:FlxSprite;
	var spotlight:FlxSprite;

    override function create() {
        super.create();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Viewing song results.", null, null, false);
		#end
        
        FlxG.sound.music.stop();

		FlxG.sound.playMusic(Paths.music('title'), 0);
		FlxG.sound.music.onComplete = () -> {
			FlxG.sound.playMusic(Paths.music('breakfast'), 0);
			FlxG.sound.music.fadeIn(5, 0, 0.7);
		};
		FlxG.sound.music.fadeIn(5, 0, 0.7);

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xff1f1f1f;
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

		loadCharacter(true);
		loadCharacter(false);

		p1.x = 150 + p1.positionArray[0];
		p1.y = p1.positionArray[1] - 50;
		add(p1);

		p2.x = 680 + p2.positionArray[0];
		p2.y = p2.positionArray[1] - 50;
		add(p2);

		p1.dance();
		p1.animation.finish();
		p2.dance();
		p2.animation.finish();

		var p1Bg = new FlxSprite();
		p1Bg.makeGraphic(1, 1, FlxColor.BLACK);
		p1Bg.alpha = 0.0;
		add(p1Bg);

		var p2Bg = new FlxSprite();
		p2Bg.makeGraphic(1, 1, FlxColor.BLACK);
		p2Bg.alpha = 0.0;
		add(p2Bg);

		p1Text = new Alphabet(0, 0, "", false);
		p1Text.antialiasing = ClientPrefs.data.antialiasing;
		p1Text.screenCenter(X);
		p1Text.scaleX = 0.5;
		p1Text.scaleY = 0.5;
		p1Text.alpha = 0;
		add(p1Text);

		p2Text = new Alphabet(0, 0, "", false);
		p2Text.antialiasing = ClientPrefs.data.antialiasing;
		p2Text.screenCenter(X);
		p2Text.scaleX = 0.5;
		p2Text.scaleY = 0.5;
		p2Text.alpha = 0;
		add(p2Text);

		win = new FlxSprite();
		win.antialiasing = ClientPrefs.data.antialiasing;
		win.frames = Paths.getSparrowAtlas('onlineJudges');
		win.animation.addByPrefix('idle', "weiner", 24);
		win.animation.play('idle');
		win.scale.set(0.65, 0.65);
		win.updateHitbox();
		win.y = 20;
        win.alpha = 0;
		add(win);

		lose = new FlxSprite();
		lose.antialiasing = ClientPrefs.data.antialiasing;
		lose.frames = Paths.getSparrowAtlas('onlineJudges');
		lose.animation.addByPrefix('idle', "loser", 24);
		lose.animation.play('idle');
		lose.scale.set(0.6, 0.6);
		lose.updateHitbox();
		lose.y = win.y + 10;
		lose.alpha = 0;
		add(lose);

		back = new FlxSprite();
		back.antialiasing = ClientPrefs.data.antialiasing;
		back.frames = Paths.getSparrowAtlas('backspace');
		back.animation.addByPrefix('idle', "backspace to exit white", 24);
		back.animation.addByPrefix('black', "backspace to exit0", 24);
		back.animation.addByPrefix('press', "backspace PRESSED", 24);
		back.animation.play('idle');
		back.scale.set(0.5, 0.5);
		back.updateHitbox();
		back.x = 30;
		back.y = FlxG.height - back.height - 30;
		back.alpha = 0;
		add(back);

		gainedText = new FlxText(0, 0, 0, '+ ${gainedPoints}FP');
		gainedText.setFormat(null, 40, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		//gainedText.setPosition(FlxG.width - gainedText.width - 20, FlxG.height - gainedText.height - 20);
		gainedText.setPosition(30, FlxG.height - gainedText.height - 25);
		gainedText.visible = false;
		add(gainedText);

		if (!GameClient.isConnected()) {
			GameClient.clearOnMessage();
			FlxG.switchState(() -> new OnlineState());
			return;
		}

		p1Accuracy = GameClient.getPlayerAccuracyPercent(GameClient.room.state.player1);
		p2Accuracy = GameClient.getPlayerAccuracyPercent(GameClient.room.state.player2);

		if (p1Accuracy >= p2Accuracy)
			winner = 0;
        else
			winner = 1;

		var winnerPlayer = winner == 0 ? p1 : p2;
		var loserPlayer = winner == 0 ? p2 : p1;
		
		var p1Name = GameClient.room.state.player1.name ?? "(none)";
		if (p1Name.trim() == "")
			p1Name = "(none)";
		var p2Name = GameClient.room.state.player2.name ?? "(none)";
		if (p2Name.trim() == "")
			p2Name = "(none)";

		p1Text.text = '${p1Name}\nAccuracy: ${p1Accuracy}% - ${getCoolRating(GameClient.room.state.player1)}\nMisses: ${GameClient.room.state.player1.misses}\nScore: ${GameClient.room.state.player1.score}';
		p2Text.text = '${p2Name}\nAccuracy: ${p2Accuracy}% - ${getCoolRating(GameClient.room.state.player2)}\nMisses: ${GameClient.room.state.player2.misses}\nScore: ${GameClient.room.state.player2.score}';

		p1Text.x = 176;
		p2Text.x = 702;
		p1Text.y = 120;
		p2Text.y = 120;

		p1Bg.scale.set(p1Text.width + 50, p1Text.height + 25);
		p2Bg.scale.set(p2Text.width + 50, p2Text.height + 25);
		p1Bg.updateHitbox();
		p2Bg.updateHitbox();
		p1Bg.setPosition(p1Text.x - 25, p1Text.y + 15);
		p2Bg.setPosition(p2Text.x - 25, p2Text.y + 15);

		win.x = (winner == 0 ? p1Bg : p2Bg).getMidpoint().x - win.width / 2;
		lose.x = (winner == 0 ? p2Bg : p1Bg).getMidpoint().x - lose.width / 2;

		for (letter in p1Text.letters) {
			if (letter != null) {
				letter.colorTransform.redOffset = 230;
				letter.colorTransform.greenOffset = 230;
				letter.colorTransform.blueOffset = 230;
			}
        }
		for (letter in p2Text.letters) {
			if (letter != null) {
				letter.colorTransform.redOffset = 230;
				letter.colorTransform.greenOffset = 230;
				letter.colorTransform.blueOffset = 230;
            }
		}

		dim = new FlxSprite(0, 0);
		dim.makeGraphic(Std.int(FlxG.width), Std.int(FlxG.height), FlxColor.BLACK);
		dim.scrollFactor.set(0, 0);
		dim.alpha = 1;
		dim.visible = true;
		add(dim);

		Paths.setCurrentLevel('week1');
		spotlight = new FlxSprite(0, -250).loadGraphic(Paths.image('spotlight'));
		spotlight.alpha = 0.375;
		spotlight.blend = ADD;
		spotlight.visible = false;
		spotlight.x = winnerPlayer.getMidpoint().x - spotlight.width / 2;
		add(spotlight);

		chatBox = new ChatBox(camera);
		add(chatBox);

		FlxTween.tween(dim, {alpha: 0.25}, 2, {ease: FlxEase.quadInOut});
		FlxTween.tween(back, {alpha: 1}, 1, {ease: FlxEase.quartInOut, startDelay: 4.0});

		new FlxTimer().start(5, (t) -> {
			disableInput = false;
		});

		new FlxTimer().start(2, (t) -> {

			winnerPlayer.playAnim("hey");
			loserPlayer.playAnim("hurt");

			FlxTween.tween(p1Text, {alpha: 1}, 1, {ease: FlxEase.quartInOut, startDelay: 1});
			FlxTween.tween(p2Text, {alpha: 1}, 1, {ease: FlxEase.quartInOut, startDelay: 1});
			FlxTween.tween(p1Bg, {alpha: 0.5}, 1, {ease: FlxEase.quartInOut, startDelay: 1});
			FlxTween.tween(p2Bg, {alpha: 0.5}, 1, {ease: FlxEase.quartInOut, startDelay: 1});

			FlxTween.tween(win, {alpha: 1}, 0.5, {ease: FlxEase.quadInOut});
			FlxTween.tween(lose, {alpha: 1, angle: 3}, 0.5, {ease: FlxEase.quadInOut});
			FlxTween.tween(lose, {angle: 0}, 0.2, {ease: FlxEase.quadInOut});

			if (gainedPoints > 0) {
				gainedText.visible = true;
				FlxG.sound.play(Paths.sound('fap'));
				if (ClientPrefs.data.flashing)
					FlxFlicker.flicker(gainedText, 0.4, 0.05, true);
				FlxTween.tween(gainedText, {alpha: 0.2}, 2, {ease: FlxEase.quadInOut});

				new FlxTimer().start(2, (t) -> {
					FlxTween.tween(gainedText, {x: back.x, y: back.y - 50, size: 25}, 1, {ease: FlxEase.quartOut});
				});
			}

			gainedPoints = 0;

			if (ClientPrefs.data.flashing) {
				flickerLoop();
				return;
			}
			spotlight.visible = true;

		});

		GameClient.send("status", "Viewing results");

		GameClient.room.onMessage("charPlay", function(message:Array<Dynamic>) {
			Waiter.put(() -> {
				if (message == null || message[0] == null)
					return;

				(GameClient.isOwner ? p2 : p1).playAnim(message[0], true);
			});
		});
    }

	function flickerLoop() {
		FlxFlicker.flicker(spotlight, 0.2, 0.05, true);
		new FlxTimer().start(FlxG.random.int(3, 12), (t) -> {
			if (!destroyed) {
				flickerLoop();
			}
		});
	}

	override function update(elapsed) {
        super.update(elapsed);

		if (!disableInput) {
			if (back.animation.curAnim.name != "press")
				back.animation.play('idle');

			if (!chatBox.focused && (!FlxG.keys.justPressed.TAB && controls.BACK || FlxG.keys.justPressed.BACKSPACE || FlxG.keys.justPressed.ENTER)) {
				FlxG.sound.music.stop();
				FlxG.sound.play(Paths.sound('cancelMenu'));

				disableInput = true;
				back.animation.play('press');
				back.offset.set(80, 50);
				if (gainedText.visible)
					FlxTween.tween(gainedText, {alpha: 0}, 0.2, {ease: FlxEase.quadInOut});
                new FlxTimer().start(0.5, (t) -> {
					GameClient.clearOnMessage();
					FlxG.switchState(() -> new Room());
                });
            }

			if (!chatBox.focused && controls.TAUNT) {
				(GameClient.isOwner ? p1 : p2).playAnim('taunt', true);
				if (GameClient.isConnected())
					GameClient.send("charPlay", ["taunt"]);
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

	function loadCharacter(isP1:Bool, ?enableDownload:Bool = true) {
		var oldModDir = Mods.currentModDirectory;

		if (isP1) {
			if (p1 != null)
				p1.destroy();
			p1 = null;

			if (FileSystem.exists(Paths.mods(GameClient.room.state.player1.skinMod))) {
				if (GameClient.room.state.player1.skinMod != null)
					Mods.currentModDirectory = GameClient.room.state.player1.skinMod;

				if (GameClient.room.state.player1.skinName != null)
					p1 = new Character(0, 0, GameClient.room.state.player1.skinName);
			}

			if (p1 == null)
				p1 = new Character(0, 0, "default");
			p1.updateHitbox();
		}
		else {
			if (p2 != null)
				p2.destroy();
			p2 = null;

			if (FileSystem.exists(Paths.mods(GameClient.room.state.player2.skinMod))) {
				if (GameClient.room.state.player2.skinMod != null)
					Mods.currentModDirectory = GameClient.room.state.player2.skinMod;

				if (GameClient.room.state.player2.skinName != null)
					p2 = new Character(0, 0, GameClient.room.state.player2.skinName + "-player", true);
			}

			if (p2 == null)
				p2 = new Character(/*770*/ 0, 0, "default-player", true);
			p2.updateHitbox();
		}

		Mods.currentModDirectory = oldModDir;
	}
}