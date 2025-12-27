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
			final scale = Math.min(w / _windowWidth, h / _windowHeight);
			scaleX = scale;
			scaleY = scale;
			x = w / 2 - _windowWidth * scale / 2;
			y = h / 2 - _windowHeight * scale / 2;
        });
    }
}