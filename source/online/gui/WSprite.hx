package online.gui;

import openfl.Lib;

class WSprite extends Sprite {
	var _windowWidth:Float = 0;
	var _windowHeight:Float = 0;
    
    public function new() {
        super();

		_windowWidth = Lib.application.window.width;
		_windowHeight = Lib.application.window.height;

        Lib.application.window.onResize.add((w, h) -> {
			scaleX = w / _windowWidth;
			scaleY = h / _windowHeight;
        });
    }
}