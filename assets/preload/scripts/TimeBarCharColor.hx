import flixel.util.FlxGradient;

var dadHealthColor:Array<FlxColor> = [];
var boyfriendHealthColor:Array<FlxColor> = [];
var gfHealthColor:Array<FlxColor> = [];

function onCreatePost() {
    gradientTimebar();
}


function onEvent(name, value1, value2) {
    if (name == 'Change Character') {
        reloadHealthBarColors();
        reloadGradientTimeBar();
    }
}

function reloadHealthBarColors() {
    dadHealthColor = game.dad.healthColorArray;
    boyfriendHealthColor = game.boyfriend.healthColorArray;
    if (game.gf != null)
        gfHealthColor = game.gf.healthColorArray;

	setVar('dadHealthColor', dadHealthColor);
	setVar('boyfriendHealthColor', boyfriendHealthColor);
	if (game.gf != null)
		setVar('gfHealthColor', gfHealthColor);
}

function reloadGradientTimeBar() {
    if (game.boyfriend != null)
        final boyColor = FlxColor.fromRGB(game.boyfriend.healthColorArray[0], game.boyfriend.healthColorArray[1], game.boyfriend.healthColorArray[2]);
    if (game.dad != null)
        final oppColor = FlxColor.fromRGB(game.dad.healthColorArray[0], game.dad.healthColorArray[1], game.dad.healthColorArray[2]);

    gradientObject(game.timeBar.leftBar, [boyColor, oppColor], 180);
}

function gradientTimebar(?dadColor:FlxColor, ?bfColor:FlxColor) {
    if (dadColor == null)
        if (game.dad != null)
            dadColor = FlxColor.fromRGB(game.dad.healthColorArray[0], game.dad.healthColorArray[1], game.dad.healthColorArray[2]);
    
    if (bfColor == null)
        if (game.boyfriend != null)
            bfColor = FlxColor.fromRGB(game.boyfriend.healthColorArray[0], game.boyfriend.healthColorArray[1], game.boyfriend.healthColorArray[2]);

    gradientObject(game.timeBar.leftBar, [bfColor, dadColor], 180);
}

function gradientObject(object:FlxSprite, colors:Array<FlxColor>, ?rotate:Int = 90) {
    FlxGradient.overlayGradientOnFlxSprite(object, object.width, object.height, colors, 0, 0, 1, rotate, true);
}
