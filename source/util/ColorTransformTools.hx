package util;

import openfl.geom.ColorTransform;
import flixel.util.FlxColor;

using flixel.util.FlxColorTransformUtil;

class ColorTransformTools
{
	public static function copyTo(a:ColorTransform, b:ColorTransform)
	{
		b.setMultipliers(a.redMultiplier, a.greenMultiplier, a.blueMultiplier, a.alphaMultiplier);
		b.setOffsets(a.redOffset, a.greenOffset, a.blueOffset, a.alphaOffset);
	}

	public static function setOffsetColor(a:ColorTransform, color:FlxColor)
	{
		a.setOffsets(color.red, color.green, color.blue, color.alpha);
	}

	public static function setMultColor(a:ColorTransform, color:FlxColor)
	{
		a.setMultipliers(color.redFloat, color.greenFloat, color.blueFloat, color.alphaFloat);
	}

	public static function reset(a:ColorTransform)
	{
		a.setMultipliers(1.0, 1.0, 1.0, 1.0);
		a.setOffsets(0, 0, 0, 0);
	}
}
