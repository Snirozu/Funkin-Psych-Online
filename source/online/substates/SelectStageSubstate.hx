package online.substates;

import openfl.filters.BlurFilter;

class SelectStageSubstate extends MusicBeatSubstate {
    var blurFilter:BlurFilter;
	public var coolCam:FlxCamera;

    public var options:FlxTypedGroup<StageText>;
    public var optionsDetails:FlxTypedGroup<FlxText>;
    public var curSelected:Int;

    var stageNames:Array<String>;
    var stageMods:Array<String>;

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

        var bg = new FlxSprite();
		bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg.scrollFactor.set(0, 0);
		bg.alpha = 0.7;
		add(bg);

        var stages = Mods.listStages(true);
        stageNames = stages[0];
        stageMods = stages[1];

        stageNames.unshift('(default)');
        stageMods.unshift('');

        add(options = new FlxTypedGroup<StageText>());
        add(optionsDetails = new FlxTypedGroup<FlxText>());

        var endScrollY:Float = FlxG.height;
        for (i in 0...stageNames.length) {
            var text = new StageText(this, 50, 50 + 50 * i, stageNames[i]);
            if (stageNames[i] == "(default)")
                text.createDetails('Default option uses the stage of the currently selected song');
            else {
                if (stageMods[i] != '') {
                    text.createDetails(' from ' + stageMods[i].substr(0, 40) + (stageMods[i].length > 40 ? '...' : ''));
                }
                else {
                    text.createDetails(' from Vanilla');
                }
            }
			text.ID = i;
			text.setFormat("VCR OSD Mono", 25, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
            text.cameras = [coolCam];
            endScrollY = text.y + text.height + 50;
            text.updateText();
			options.add(text);
        }

        coolCam.setScrollBounds(FlxG.width, FlxG.width, 0, endScrollY > FlxG.height ? endScrollY : FlxG.height);
    }

    var holdUp = 0.0;
    var holdDown = 0.0;
    override function update(elapsed) {
        super.update(elapsed);

        Conductor.songPosition = FlxG.sound.music.time;

        if (controls.BACK) {
            close();
        }

        if (controls.UI_UP)
            holdUp += elapsed;
        else
            holdUp = 0;

        if (controls.UI_DOWN)
            holdDown += elapsed;
        else
            holdDown = 0;

        if (controls.UI_UP_P || FlxG.mouse.wheel == 1) {
            curSelected -= FlxG.keys.pressed.SHIFT ? 3 : 1;
            updateSelection();
        }

        if (controls.UI_DOWN_P || FlxG.mouse.wheel == -1) {
            curSelected += FlxG.keys.pressed.SHIFT ? 3 : 1;
            updateSelection();
        }

        if (controls.ACCEPT || (FlxG.mouse.justPressed && FlxG.mouse.overlaps(options.members[curSelected], camera))) {
            if (stageNames[curSelected] == "(default)") {
                Alert.alert("Stage set to default!");
                GameClient.send("setStage", ['', '', '']);
                close();
            }

            var stageURL = '';
            if (stageMods[curSelected] != "") {
                stageURL = OnlineMods.getModURL(stageMods[curSelected]);
            }
            GameClient.send("setStage", [stageNames[curSelected], stageMods[curSelected], stageURL]);
            Alert.alert("Stage set to " + stageNames[curSelected] + "!");
            close();
        }
    }

    function updateSelection() {
        if (curSelected < 0)
            curSelected = options.length - 1;
    
        if (curSelected > options.length - 1)
            curSelected = 0;

        for (option in options) option.updateText();
    }

    override function destroy() {
		super.destroy();

		for (cam in FlxG.cameras.list) {
			if (cam?.filters != null)
				cam.filters.remove(blurFilter);
		}
		FlxG.cameras.remove(coolCam);
	}

    override function stepHit() {
        super.stepHit();

        if (holdUp > 0.5) {
            curSelected -= FlxG.keys.pressed.SHIFT ? 3 : 1;
            updateSelection();
        }

        if (holdDown > 0.5) {
            curSelected += FlxG.keys.pressed.SHIFT ? 3 : 1;
            updateSelection();
        }
    }
}

class StageText extends FlxText {
	public var parent:SelectStageSubstate;
    public var ogText:String;
    public var details:FlxText;

	public function new(parent:SelectStageSubstate, x:Float, y:Float, text:String) {
        super(x, y, 0, ogText = text);

        this.parent = parent;
        updateText();
    }

    override function update(elapsed) {
        if ((FlxG.mouse.justPressed || FlxG.mouse.justMoved) && FlxG.mouse.overlaps(this, camera)) {
            parent.curSelected = ID;
            for (option in parent.options) option.updateText();
        }
    }

    public function createDetails(content:String) {
        var details = new FlxText(x, y, 0, content);
        details.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        details.cameras = [parent.coolCam];
        details.color = FlxColor.GRAY;
        details.y = y + 25;
        parent.optionsDetails.add(details);
    }

    public function updateText() {
        if (parent.curSelected == ID) {
            text = "> " + ogText;
            camera.follow(this, null, 0.1);
        }
        else {
            text = ogText;
        }
    }
}