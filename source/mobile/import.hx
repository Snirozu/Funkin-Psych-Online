package mobile.controls;

/* Flixel*/
#if flixel
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;


import flixel.FlxObject;
import flixel.FlxCamera;
import flixel.input.touch.FlxTouch;
import flixel.system.scaleModes.BaseScaleMode;
#end

import mobile.io.File;
import mobile.io.FileSystem;

/* OpenFL */

import openfl.display.Stage;
import openfl.display.StageScaleMode;
import openfl.display.Sprite;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import openfl.geom.ColorTransform;
import openfl.events.Event;
import openfl.events.TouchEvent;
import openfl.events.MouseEvent;
import openfl.Assets;
import openfl.ui.Multitouch;
import openfl.ui.MultitouchInputMode;
import openfl.display.PixelSnapping;

/* Haxe */
import haxe.Json;

using StringTools;