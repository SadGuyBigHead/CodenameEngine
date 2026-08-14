package funkin.game;

import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxColor;

/**
 * Dumb
 */
class CharacterMissTintShader extends FlxShader
{
	public var tintColor(default, set):FlxColor;

	function set_tintColor(v:FlxColor)
	{
		_tintColor.value[0] = v.redFloat;
		_tintColor.value[1] = v.greenFloat;
		_tintColor.value[2] = v.blueFloat;
		return tintColor = v;
	}

	public var tintMix(default, set):Float;

	function set_tintMix(v:Float)
	{
		_tintColor.value[3] = v;
		return tintMix = v;
	}

	@:glFragmentSource('
		#pragma header
	
		uniform vec4 _tintColor;

		void main()
		{
			vec4 col = flixel_texture2D(bitmap, openfl_TextureCoordv.xy);
			gl_FragColor = vec4(mix(col.rgb, _tintColor.rgb * col.a, _tintColor.a), col.a);
		}')
	public function new()
	{
		super();
		_tintColor.value = [.0, .0, .0, .0];
		tintColor = 0x00;
		tintMix = .5;
	}
}
