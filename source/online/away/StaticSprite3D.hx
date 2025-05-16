package online.away;

import away3d.textfield.RectangleBitmapTexture;
import away3d.textures.Anisotropy;
import away3d.primitives.PlaneGeometry;
import away3d.entities.Mesh;
import away3d.materials.TextureMaterial;
import openfl.display.BitmapData;

class StaticSprite3D extends Mesh {
	public var graphic:BitmapData;

	public function new(props:SpriteProps, ?bitmap:BitmapData) {
		if (props.image == null && bitmap == null)
			throw 'Bitmap not provided and is null!';

		if (bitmap == null) {
			bitmap = Paths.image(props.image /*, null, false*/).bitmap;
		}

		this.graphic = bitmap;
		
		props ??= {};
		props.completeSize ??= true;
		props.bothSides ??= false;
		props.repeat ??= false;
		props.scaleUV ??= 1.0;
		props.antialiasing ??= true;

		var material = new TextureMaterial(new RectangleBitmapTexture(bitmap)); // the .png
		material.mipmap = false; // otherwise the texture wont render
		material.alphaThreshold = 1;
		material.repeat = props.repeat;
		material.anisotropy = Anisotropy.NONE;
		material.smooth = props.antialiasing;

		// the mesh size will be of the whole spritesheet size, (if it is a completeSize) 
		var geom = new PlaneGeometry(
			props.geomWidth ?? (props.completeSize ? bitmap.width * props.scaleUV : 1), 
			props.geomHeight ?? (props.completeSize ? bitmap.height * props.scaleUV : 1),
			1, 1, false, props.bothSides
		);
		if (props.scaleUV != 1.0)
			geom.scaleUV(geom.width / (bitmap.width * props.scaleUV), geom.height / (bitmap.height * props.scaleUV));

		super(geom, material);
		if (!props.completeSize) {
			if (props.geomWidth == null)
				this.scaleX = bitmap.width;
			if (props.geomHeight == null)
				this.scaleY = bitmap.height;
        }
	}

	public static function toNextPowerOf(value:Float, power:Float):Float {
		return Math.pow(power, Math.ceil(Math.log(value) / Math.log(power)));
	}
}