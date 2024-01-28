package online;

import states.MainMenuState;
import openfl.geom.Rectangle;
import openfl.display.GraphicsShader;
import openfl.display.Shader;
import openfl.filters.ShaderFilter;
import openfl.utils.Assets;
import openfl.text.TextFormat;
import openfl.text.TextField;
import openfl.Lib;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.display.Sprite;

class LoadingScreen extends Sprite {
    static var instance:LoadingScreen;
    var bg:Bitmap;
	var roseCirc:Sprite;
	var roseCirc1:Sprite;
	var roseCirc2:Sprite;
	var roseCirc3:Sprite;
    //var coolShader:CoolShader;
    public var targetAlpha:Float = 0;

	public static var loadingTime:Float = 0;
	public static var loading:Bool = false;

    public static function toggle(bool:Bool) {
		loading = bool;
        instance.targetAlpha = bool ? 1 : 0;
    }
    
	public function new() {
		super();

        alpha = 0;

		instance = this;

		bg = new Bitmap(new BitmapData(Lib.application.window.width, Lib.application.window.height, true, 0xFF000000));
		bg.alpha = 0.6;
		addChild(bg);

		roseCirc = new Sprite();
		roseCirc.graphics.beginFill(0xFCFCFC);
		roseCirc.graphics.drawCircle(0, 0, 5);
		roseCirc.graphics.endFill();
		addChild(roseCirc);

		roseCirc1 = new Sprite();
		roseCirc1.graphics.beginFill(0xFCFCFC);
		roseCirc1.graphics.drawCircle(0, 0, 5);
		roseCirc1.graphics.endFill();
		addChild(roseCirc1);

		roseCirc2 = new Sprite();
		roseCirc2.graphics.beginFill(0xFCFCFC);
		roseCirc2.graphics.drawCircle(0, 0, 5);
		roseCirc2.graphics.endFill();
		addChild(roseCirc2);

		roseCirc3 = new Sprite();
		roseCirc3.graphics.beginFill(0xFCFCFC);
		roseCirc3.graphics.drawCircle(0, 0, 5);
		roseCirc3.graphics.endFill();
		addChild(roseCirc3);

		//roseCirc.shader = coolShader = new CoolShader();
    }

    var theta:Float = 0; // angle degrees controlled by delta
    var petals:Float = 5; // petals[squared]

    var rekt:Rectangle = new Rectangle(0, 0, 10, 10);

    function thetaAngle(skip:Int) {
		return (theta + skip * 90) * Math.PI / 180;
    }

	override function __enterFrame(delta) {
		super.__enterFrame(delta);

		loadingTime += delta / 1000;
		if (!loading)
			loadingTime = 0;
		if (loadingTime >= 10 && GameClient.isConnected()) {
			toggle(false);
			GameClient.leaveRoom("Timed out!");
			MusicBeatState.switchState(new MainMenuState());
		}

		alpha = FlxMath.lerp(alpha, targetAlpha, delta * 0.01);

        if (alpha == 0)
            return;

		theta += delta * 0.1;
		if (theta > 360)
            theta = 0;

        //spaghetti code ahead

		var thetaSin = 50 * Math.sin(petals * thetaAngle(0));
		var thetaSin2 = 50 * Math.sin(petals * thetaAngle(1));
		var thetaCos = 50 * Math.cos(petals * thetaAngle(2));
		var thetaCos2 = 50 * Math.cos(petals * thetaAngle(3));

		roseCirc.graphics.clear();
		roseCirc.graphics.beginFill(0xFCFCFC);
		roseCirc.graphics.drawCircle(
            Lib.application.window.width / 2 + thetaSin * Math.cos(thetaAngle(0)), 
			Lib.application.window.height / 2 + thetaSin * Math.sin(thetaAngle(0)), 
            5
        );
		roseCirc.graphics.endFill();
		//coolShader.update(delta);

		roseCirc1.graphics.clear();
		roseCirc1.graphics.beginFill(0xFCFCFC);
		roseCirc1.graphics.drawCircle(
            Lib.application.window.width / 2 + thetaCos * Math.sin(thetaAngle(2)), 
			Lib.application.window.height / 2 + thetaCos * Math.cos(thetaAngle(2)), 
            5
        );
		roseCirc1.graphics.endFill();

        roseCirc2.graphics.clear();
		roseCirc2.graphics.beginFill(0xFCFCFC);
		roseCirc2.graphics.drawCircle(
            Lib.application.window.width / 2 + thetaSin2 * Math.sin(thetaAngle(1)), 
			Lib.application.window.height / 2 + thetaSin2 * Math.cos(thetaAngle(1)), 
            5
        );
		roseCirc2.graphics.endFill();

        roseCirc3.graphics.clear();
		roseCirc3.graphics.beginFill(0xFCFCFC);
		roseCirc3.graphics.drawCircle(
            Lib.application.window.width / 2 + thetaCos2 * Math.cos(thetaAngle(3)), 
			Lib.application.window.height / 2 + thetaCos2 * Math.sin(thetaAngle(3)), 
            5
        );
		roseCirc3.graphics.endFill();
    }
}

// i give on trails
// class CoolShader extends GraphicsShader {
// 	@:glFragmentSource('
//     #pragma header
//     vec2 uv = openfl_TextureCoordv.xy;
//     vec2 fragCoord = openfl_TextureCoordv*openfl_TextureSize;
//     vec2 iResolution = openfl_TextureSize;
//     uniform float iTime;
//     #define iChannel0 bitmap
//     #define texture texture2D
//     #define fragColor gl_FragColor
//     #define mainImage main
//     ')
//     // @:glVertexSource('
//     // ')
// 	public function new() {
// 		super();
// 		iTime.value = [0];
// 	}

// 	public function update(elapsed:Float) {
// 		iTime.value[0] += elapsed;
//     }
// }