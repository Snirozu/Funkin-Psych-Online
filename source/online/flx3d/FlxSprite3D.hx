package online.flx3d;

import flixel.math.FlxAngle;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.graphics.frames.FlxFrame.FlxFrameType;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import sys.FileSystem;
import openfl.Assets;
import away3d.containers.ObjectContainer3D;
import openfl.Vector;
import away3d.materials.passes.MaterialPassBase;
import openfl.display3D.Context3DProgramType;
import away3d.core.base.SubMesh;
import away3d.materials.MaterialBase;
import away3d.cameras.Camera3D;
import away3d.core.base.IRenderable;
import away3d.core.managers.Stage3DProxy;
import away3d.textfield.RectangleBitmapTexture;
import away3d.primitives.PlaneGeometry;
import away3d.entities.Mesh;
import away3d.materials.TextureMaterial;
import openfl.display.BitmapData;
import away3d.animators.*;
import flixel.math.FlxPoint;

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

    public function update(elapsed:Float) {
		sprite.update(elapsed);
		updateTexture(sprite.frame?.parent);

		flipX = (sprite.frame.flipX ? !sprite.flipX : sprite.flipX);
		flipY = (sprite.frame.flipY ? !sprite.flipY : sprite.flipY);
		mesh.rotationZ = -sprite.angle - Std.int(sprite.frame.angle) * (flipX ? -1 : 1);
		material.alpha = !sprite.visible ? 0 : sprite.alpha;
		scaleX = sprite.scale.x;
		scaleY = sprite.scale.y;
		animator.updateOffset();
    }

	override function dispose() {
		super.dispose();

		while (numChildren > 0)
			getChildAt(0).dispose();
		
		sprite.destroy();
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

@:access(flixel.FlxSprite)
class FlxSprite3DAnimator extends AnimatorBase implements IAnimator {
    var sprite3D:FlxSprite3D;
	var _vectorFrame:Vector<Float>;
    //var _animOffset:Vector<Float>;
    var _lastFrameIndex:Int = -2;

	public function new(sprite3D:FlxSprite3D) {
		super(new SpriteSheetAnimationSet()); // for some reason this is needed?
		_vectorFrame = new Vector<Float>(4, true);
		//_animOffset = new Vector<Float>(2, true, [0, 0]);

		this.sprite3D = sprite3D;
    }

	var _angle:Float = 0;
	var _origin:Array<Float> = [0, 0];

	public function updateOffset() {
		final spriteFlx = sprite3D.sprite;

		// if (spriteFlx.animation.frameIndex == _lastFrameIndex)
        //     return;

		// _lastFrameIndex = spriteFlx.animation.frameIndex;

		sprite3D.mesh.x = 0;
		sprite3D.mesh.y = 0;

		// uv to the frame from the spritesheet
		if (spriteFlx.frame != null) {
			final frame = spriteFlx.frame;

			sprite3D.planeGeom.width = frame.frame.width;
			sprite3D.planeGeom.height = frame.frame.height;

			_vectorFrame[0] = frame.frame.x / sprite3D.texture.bitmapData.width;
			_vectorFrame[1] = frame.frame.y / sprite3D.texture.bitmapData.height;
			_vectorFrame[2] = frame.frame.width / sprite3D.texture.bitmapData.width;
			_vectorFrame[3] = frame.frame.height / sprite3D.texture.bitmapData.height;
		}

		// haxeflixel crap there from FlxSprite.draw
		spriteFlx.checkEmptyFrame();

		if (spriteFlx.alpha == 0 || spriteFlx._frame.type == FlxFrameType.EMPTY)
			return;

		if (spriteFlx.dirty) // rarely
			spriteFlx.calcFrame(spriteFlx.useFramePixels);

		if (FlxScriptedState3D.dispatch("updateOffset", [this]) != null) {
			return;
		}

		// code based mainly on FlxSprite.drawFrameComplex
		// FIXME: doesn't work properly with spritesheets that have rotated frames
		final frame = spriteFlx.frame;
		if (frame != null) {
			final frame = spriteFlx.frame;
			final matrix = spriteFlx._matrix;
			final flipX = spriteFlx.checkFlipX();
			final flipY = spriteFlx.checkFlipY();

			// calc new mesh width and height based on its rotation
			final radians:Float = sprite3D.mesh.rotationZ * FlxAngle.TO_RAD;
			final rotatedWidth = frame.frame.width * Math.abs(Math.cos(radians)) + frame.frame.height * Math.abs(Math.sin(radians));
			final rotatedHeight = frame.frame.height * Math.abs(Math.cos(radians)) + frame.frame.width * Math.abs(Math.sin(radians));

			// prepare the initial matrix for frame positioning from the spritesheet data
			frame.prepareMatrix(matrix, 0, flipX, flipY);

			// for rotated frames in spritesheets; true if sparrow atlas subtexture has rotated key set to true
			if (frame.angle == -90)
				matrix.translate(0, -frame.sourceSize.y);
			// this line was not tested lol
			else if (frame.angle == 90)
				matrix.translate(-frame.sourceSize.x, 0);

			matrix.translate(-spriteFlx.origin.x, -spriteFlx.origin.y);
			matrix.scale(spriteFlx.scale.x, spriteFlx.scale.y);

			if (spriteFlx.bakedRotationAngle <= 0) {
				spriteFlx.updateTrig();

				if (spriteFlx.angle != 0)
					matrix.rotateWithTrig(spriteFlx._cosAngle, spriteFlx._sinAngle);
			}

			// now add the position from flxsprite to the frame position
			if (spriteFlx._point == null)
				spriteFlx._point = FlxPoint.get();
			spriteFlx._point.set(spriteFlx.x, spriteFlx.y);
			spriteFlx._point.set(spriteFlx._point.x - spriteFlx.offset.x, spriteFlx._point.y - spriteFlx.offset.y);
			spriteFlx._point.set(spriteFlx._point.x + spriteFlx.origin.x, spriteFlx._point.y + spriteFlx.origin.y);
			matrix.translate(spriteFlx._point.x, spriteFlx._point.y);

			// the mesh is always centered to the center of the frame so we have to revert that
			matrix.translate(rotatedWidth * 0.5 * (flipX ? -1 : 1), rotatedHeight * 0.5 * (flipY ? -1 : 1));

			sprite3D.mesh.x = matrix.tx;
			sprite3D.mesh.y = -matrix.ty; // away3d has reversed Y direction
		}
    }

	public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, vertexConstantOffset:Int, vertexStreamOffset:Int, camera:Camera3D) {
		var material:MaterialBase = renderable.material;
		if (material == null || !Std.isOfType(material, TextureMaterial))
			return;

		var subMesh:SubMesh = cast(renderable, SubMesh);
		if (subMesh == null)
			return;

		@:privateAccess
        stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, vertexConstantOffset, _vectorFrame);
    }

    public function testGPUCompatibility(pass:MaterialPassBase) {

    }

    public function clone():IAnimator {
		return new FlxSprite3DAnimator(sprite3D);
    }
}