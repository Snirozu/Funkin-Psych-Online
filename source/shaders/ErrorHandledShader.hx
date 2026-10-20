package shaders;

import sys.io.File;
import sys.FileSystem;
import flixel.system.FlxAssets.FlxShader;
import flixel.addons.display.FlxRuntimeShader;
import lime.graphics.opengl.GLProgram;
import lime.app.Application;

class ErrorHandledShader extends FlxShader implements IErrorHandler
{
	public static final FALLBACK_VERTEX:String = "
		attribute float openfl_Alpha;
		attribute vec4 openfl_Position;
		attribute vec2 openfl_TextureCoord;
		varying float openfl_Alphav;
		varying vec2 openfl_TextureCoordv;
		uniform mat4 openfl_Matrix;
		
		void main(void) {
			openfl_Alphav = openfl_Alpha;
			openfl_TextureCoordv = openfl_TextureCoord;
			gl_Position = openfl_Matrix * openfl_Position;
		}
	";

	public static final FALLBACK_FRAGMENT:String = "
		#ifdef GL_ES
		precision mediump float;
		#endif
		varying float openfl_Alphav;
		varying vec2 openfl_TextureCoordv;
		uniform sampler2D bitmap;
		
		void main(void) {
			vec4 color = texture2D(bitmap, openfl_TextureCoordv);
			gl_FragColor = color * openfl_Alphav;
		}
	";

	public var shaderName:String = '';
	public dynamic function onError(error:Dynamic):Void {}
	public function new(?shaderName:String)
	{
		this.shaderName = shaderName;
		super();
	}

	override function __createGLProgram(vertexSource:String, fragmentSource:String):GLProgram
	{
		try
		{
			final res = super.__createGLProgram(vertexSource, fragmentSource);
			return res;
		}
		catch (error)
		{
			ErrorHandledShader.crashSave(this.shaderName, error, onError);
			final res = super.__createGLProgram(ErrorHandledShader.FALLBACK_VERTEX, ErrorHandledShader.FALLBACK_FRAGMENT); // normally causes dissapearance of sprites if returned null
			return res;
		}
	}
	
	public static function crashSave(shaderName:String, error:Dynamic, onError:Dynamic) // prevent the app from dying immediately
	{
		if(shaderName == null) shaderName = 'unnamed';
		var alertTitle:String = 'Error on Shader: "$shaderName"';

		// Save a crash log on Release builds
		var errMsg:String = "";
		var dateNow:String = Date.now().toString().replace(" ", "_").replace(":", "'");

		if (!FileSystem.exists('./crash/'))
			FileSystem.createDirectory('./crash/');

		var crashLogPath:String = './crash/shader_${shaderName}_${dateNow}.txt';
		if (ClientPrefs.isDebug()) {
			File.saveContent(crashLogPath, error);
			Log.error(alertTitle, 'Error log saved at: $crashLogPath');
		}

		onError(error);
	}
}

class ErrorHandledRuntimeShader extends FlxRuntimeShader implements IErrorHandler
{
	public var shaderName:String = '';
	public dynamic function onError(error:Dynamic):Void {}
	public function new(?shaderName:String, ?fragmentSource:String, ?vertexSource:String)
	{
		this.shaderName = shaderName;
		super(fragmentSource, vertexSource);
	}

	override function __createGLProgram(vertexSource:String, fragmentSource:String):GLProgram
	{
		try
		{
			final res = super.__createGLProgram(vertexSource, fragmentSource);
			return res;
		}
		catch (error)
		{
			ErrorHandledShader.crashSave(this.shaderName, error, onError);
			final res = super.__createGLProgram(ErrorHandledShader.FALLBACK_VERTEX, ErrorHandledShader.FALLBACK_FRAGMENT); 
			return res;
		}
	}
}

interface IErrorHandler
{
	public var shaderName:String;
	public dynamic function onError(error:Dynamic):Void;
}