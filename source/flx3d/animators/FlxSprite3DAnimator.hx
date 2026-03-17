package flx3d.animators;

import away3d.animators.*;
import away3d.cameras.Camera3D;
import away3d.core.base.IRenderable;
import away3d.core.base.SubMesh;
import away3d.core.managers.Stage3DProxy;
import away3d.materials.MaterialBase;
import away3d.materials.TextureMaterial;
import away3d.materials.passes.MaterialPassBase;
import flixel.graphics.frames.FlxFrame.FlxFrameType;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import openfl.Vector;
import openfl.display3D.Context3DProgramType;

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

			sprite3D.planeGeom.width = frame.frame.width * spriteFlx.scale.x;
			sprite3D.planeGeom.height = frame.frame.height * spriteFlx.scale.y;

			_vectorFrame[0] = frame.frame.x / sprite3D.texture.bitmapData.width;
			_vectorFrame[1] = frame.frame.y / sprite3D.texture.bitmapData.height;
			_vectorFrame[2] = frame.frame.width / sprite3D.texture.bitmapData.width;
			_vectorFrame[3] = frame.frame.height / sprite3D.texture.bitmapData.height;
		}

		// haxeflixel crap there from FlxSprite.draw
		spriteFlx.checkEmptyFrame();

		if (spriteFlx.dirty) // rarely
			spriteFlx.calcFrame(spriteFlx.useFramePixels);

		// code based mainly on FlxSprite.drawFrameComplex
		final frame = spriteFlx.frame;
		if (frame != null) {
			// if (DebugScript.self.call('updateOffset', [spriteFlx, sprite3D])?.returnValue == true)
			// 	return;

			final frame = spriteFlx.frame;
			final matrix = spriteFlx._matrix;
			final flipX = spriteFlx.checkFlipX();
			final flipY = spriteFlx.checkFlipY();

			// calc new mesh width and height based on its rotation
			final radians:Float = frame.angle * FlxAngle.TO_RAD;
			final rotatedWidth = sprite3D.planeGeom.width * Math.abs(Math.cos(radians)) + sprite3D.planeGeom.height * Math.abs(Math.sin(radians));
			final rotatedHeight = sprite3D.planeGeom.height * Math.abs(Math.cos(radians)) + sprite3D.planeGeom.width * Math.abs(Math.sin(radians));

			// prepare the initial matrix for frame positioning from the spritesheet data
			frame.prepareMatrix(matrix, 0, flipX, flipY);

			// for rotated frames in spritesheets; true if sparrow atlas subtexture has rotated key set to true
			if (frame.angle == -90)
				matrix.translate(0, -rotatedHeight);
			// this line was not tested, lmk if this line works (someone)
			else if (frame.angle == 90)
				matrix.translate(-rotatedWidth, 0);

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

			// apply2DMatrixToMatrix3D(matrix);
		}
    }

	// public function apply2DMatrixToMatrix3D(matrix:Matrix) {
	// 	var delta = matrix.a * matrix.d - matrix.b * matrix.c;

	// 	var translation = [matrix.tx, matrix.ty];
	// 	var rotation = 0.0;
	// 	var scale = [0.0, 0.0];
	// 	var skew = [0.0, 0.0];

	// 	if (matrix.a != 0 || matrix.b != 0) {
	// 		var r = Math.sqrt(matrix.a * matrix.a + matrix.b * matrix.b);
	// 		rotation = matrix.b > 0 ? Math.acos(matrix.a / r) : -Math.acos(matrix.a / r);
	// 		scale = [r, delta / r];
	// 		skew = [Math.atan((matrix.a * matrix.c + matrix.b * matrix.d) / (r * r)), 0];
	// 	}
	// 	else if (matrix.c != 0 || matrix.d != 0) {
	// 		var s = Math.sqrt(matrix.c * matrix.c + matrix.d * matrix.d);
	// 		rotation = Math.PI / 2 - (matrix.d > 0 ? Math.acos(-matrix.c / s) : -Math.acos(matrix.c / s));
	// 		scale = [delta / s, s];
	// 		skew = [0, Math.atan((matrix.a * matrix.c + matrix.b * matrix.d) / (s * s))];
	// 	}

	// 	sprite3D.mesh.transform.identity();
	// 	sprite3D.mesh.transform.appendScale(scale[0], scale[1], 0);
	// 	sprite3D.mesh.transform.appendRotation(rotation * FlxAngle.TO_DEG, Vector3D.Z_AXIS);
	// 	sprite3D.mesh.transform.appendTranslation(matrix.tx, -matrix.ty, 0);
	// 	sprite3D.mesh.transform = sprite3D.mesh.transform;
	// 	sprite3D.mesh.rotationZ = -rotation;
	// }


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