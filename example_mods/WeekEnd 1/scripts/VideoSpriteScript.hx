import psychlua.LuaUtils;

import hxcodec.flixel.FlxVideo;

var cacheList:Array<String> = ['darnellCutscene', '2hotCutscene', 'blazinCutscene'];

function onCreate():Void
{
    while (cacheList.length > 0.0)
    {
        var video:FlxVideo = new FlxVideo();

        video.play(Paths.video(cacheList[0]), false);

        video.stop();

        video.dispose();

        cacheList.shift();
    }

    cacheList = null;
}

var global:Array<{sprite:FlxSprite, video:FlxVideo}> = [];

function makeVideoSprite(tag:String, path:String, ?x:Float = 0.0, ?y:Float = 0.0, ?camera:String = "game", ?shouldLoop:Bool = false):Void
{
    var local:{sprite:FlxSprite, video:FlxVideo} =
    {
        sprite: null,

        video: null,
    };

    var sprite:FlxSprite = new FlxSprite();

    sprite.camera = LuaUtils.cameraFromString(camera);

    sprite.setPosition(x, y);

    game.modchartSprites[tag] = sprite;

    local.sprite = sprite;

    game.add(sprite);

    var video:FlxVideo = new FlxVideo();

    video.alpha = 0.0;

    video.onEndReached.add(() ->
    {
        sprite.destroy();

        video.dispose();

        game.callOnLuas('onVideoFinished', [tag]); //NOTE: That was added by me (Ledonic).
    });

    local.video = video;

    video.play(Paths.video(path), shouldLoop);

    global.push(local);
}

function onUpdate(elapsed:Float):Void
{
    for (i in 0 ... global.length)
    {
        var local:{sprite:FlxSprite, video:FlxVideo} = global[i];

        if (local.video.bitmapData != null)
        {
            local.sprite.loadGraphic(local.video.bitmapData);
        }
    }
}

function onPause():Void
{
    for (i in 0 ... global.length)
    {
        var local:{sprite:FlxSprite, video:FlxVideo} = global[i];

        local.video.pause();
			
        if (FlxG.autoPause)
        {
            if (FlxG.signals.focusGained.has(local.video.resume))
            {
                FlxG.signals.focusGained.remove(local.video.resume);
            }

            if (FlxG.signals.focusLost.has(local.video.pause))
            {
                FlxG.signals.focusLost.remove(local.video.pause);
            }
        }
    }
}

function onResume():Void
{
    for (i in 0 ... global.length)
    {
        var local:{sprite:FlxSprite, video:FlxVideo} = global[i];

        local.video.resume();
            
        if (FlxG.autoPause)
        {
            if (!FlxG.signals.focusGained.has(local.video.resume))
            {
                FlxG.signals.focusGained.add(local.video.resume);
            }

            if (!FlxG.signals.focusLost.has(local.video.pause))
            {
                FlxG.signals.focusLost.add(local.video.pause);
            }
        }
    }
}

function onGameOverStart():Void
{
    for (i in 0 ... global.length)
    {
        var local:{sprite:FlxSprite, video:FlxVideo} = global[i];

        local.video.pause();
            
        if (FlxG.autoPause)
        {
            if (FlxG.signals.focusGained.has(local.video.resume))
            {
                FlxG.signals.focusGained.remove(local.video.resume);
            }

            if (FlxG.signals.focusLost.has(local.video.pause))
            {
                FlxG.signals.focusLost.remove(local.video.pause);
            }
        }
    }
}

function onDestroy():Void
{
    while (global.length > 0.0)
    {
        global[0].video.dispose();

        global.shift();
    }
}

createGlobalCallback("makeVideoSprite", makeVideoSprite);