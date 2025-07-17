package objects;

class FlxTweenedSprite extends FlxSprite {
    public var tween(default, set):FlxTween;

    function set_tween(v:FlxTween):FlxTween {
        if (tween != null)
            tween.cancel();
        return tween = v;
    }
}