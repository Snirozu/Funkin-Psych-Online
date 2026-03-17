package flx3d;

import away3d.containers.ObjectContainer3D;
import away3d.entities.Mesh;
import away3d.materials.TextureMaterial;
import away3d.primitives.PlaneGeometry;
import away3d.textfield.RectangleBitmapTexture;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flx3d.animators.FlxSprite3DAnimator;
import openfl.Assets;
import openfl.display.BitmapData;
import sys.FileSystem;

class FlxSprite3D extends ObjectContainer3D {
    public var sprite:FlxSprite;

    public var mesh:Mesh;
	public var material:TextureMaterial;
	public var texture:RectangleBitmapTexture;
	public var planeGeom:PlaneGeometry;
	public var animator:FlxSprite3DAnimator;

	var _bitmapKey:String;

	public var flipX(get, set):Bool;
	public var flipY(get, set):Bool;

    public function new(sprite:FlxSprite) {
        super();

        this.sprite = sprite;

		_bitmapKey = sprite.graphic.key;

		loadGraphic(sprite.graphic);
		if (sprite.frames is FlxAtlasFrames) {
			var frames:FlxAtlasFrames = cast sprite.frames;
			for (graphic in @:privateAccess frames.usedGraphics) {
				loadGraphic(graphic);
			}
		}

		material = new TextureMaterial(texture = new RectangleBitmapTexture(usedBitmaps.get(_bitmapKey))); // the .png
		material.mipmap = false; // otherwise the texture wont render
		//material.alphaBlending = true; // supports images with alpha channel fully but the render messes up drawing order
		material.alphaThreshold = 0.7; // WARNING this does not support sprites with colors that have alpha, they will either be empty or set to alpha 255!
		material.smooth = sprite.antialiasing;

		planeGeom = new PlaneGeometry(
		    texture.bitmapData.width, texture.bitmapData.height, 1, 1, false, true
		);

		mesh = new Mesh(planeGeom, material);
		mesh.animator = animator = new FlxSprite3DAnimator(this);
		animator.updateOffset();
        addChild(mesh);
    }

	function get_flipX() {
		return mesh.rotationY == 180;
	}
	function get_flipY() {
		return mesh.rotationX == 180;
	}
	function set_flipX(v) {
		mesh.rotationY = v ? 180 : 0;
		return get_flipX();
	}
	function set_flipY(v) {
		mesh.rotationX = v ? 180 : 0;
		return get_flipY();
	}

	public var followVisibility:Bool = true;

    public function update(elapsed:Float) {
		if (!sprite.active)
			sprite.update(elapsed);
		updateTexture(sprite.frame?.parent);

		flipX = (sprite.frame.flipX ? !sprite.flipX : sprite.flipX);
		flipY = (sprite.frame.flipY ? !sprite.flipY : sprite.flipY);
		mesh.rotationZ = -sprite.angle - Std.int(sprite.frame.angle) * (flipX ? -1 : 1);
		material.alpha = (sprite.visible || !followVisibility) ? sprite.alpha : 0;
		// avoid using that!!!!!!
		// scaleX = sprite.scale.x;
		// scaleY = sprite.scale.y;
		animator.updateOffset();
    }

	override function dispose() {
		super.dispose();

		while (numChildren > 0)
			getChildAt(0).dispose();
		
		// sprite.destroy();
		if (usedBitmaps != null)
			for (bitmap in usedBitmaps) {
				bitmap.dispose();
			}
		usedBitmaps = null;
	} 
	
	var usedBitmaps:Map<String, BitmapData> = new Map();

	// fetch from storage instead from memory, if a bitmap gets disposed by flixel it will be blank in away3d
	function loadGraphic(graphic:FlxGraphic) {
		if (usedBitmaps.exists(graphic.key)) {
			return usedBitmaps.get(graphic.key);
		}

		var bitmap:BitmapData = null;
		try {
			bitmap = Assets.getBitmapData(graphic.key, false);
		}
		catch (exc) {}
		if (bitmap == null && FileSystem.exists(graphic.key)) {
			bitmap = BitmapData.fromFile(graphic.key);
		}
		usedBitmaps.set(graphic.key, bitmap ?? sprite.pixels);
		return bitmap;
	}

	function updateTexture(graphic:FlxGraphic) {
		if (graphic == null || _bitmapKey == sprite.frame?.parent?.key) {
			return;
		}
		_bitmapKey = graphic.key;
		
		texture.bitmapData = loadGraphic(graphic);
	}
}