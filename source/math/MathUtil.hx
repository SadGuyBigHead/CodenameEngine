package math;

// stolen fron base fnf muahahahahahha

/**
 * Utilities for performing mathematical operations.
 */
@:keep class MathUtil
{
	/**
	 * Euler's constant and the base of the natural logarithm.
	 * Math.E is not a constant in Haxe, so we'll just define it ourselves.
	 */
	public static final E:Float = 2.71828182845904523536;

	/**
	 * Get the logarithm of a value with a given base.
	 * @param base The base of the logarithm.
	 * @param value The value to get the logarithm of.
	 * @return `log_base(value)`
	 */
	public static function logBase(base:Float, value:Float):Float
	{
		return Math.log(value) / Math.log(base);
	}

	public static function easeInOutCirc(x:Float):Float
	{
		if (x <= 0.0)
			return 0.0;
		if (x >= 1.0)
			return 1.0;
		var result:Float = (x < 0.5) ? (1 - Math.sqrt(1 - 4 * x * x)) / 2 : (Math.sqrt(1 - 4 * (1 - x) * (1 - x)) + 1) / 2;
		return (result == Math.NaN) ? 1.0 : result;
	}

	public static function easeInOutBack(x:Float, ?c:Float = 1.70158):Float
	{
		if (x <= 0.0)
			return 0.0;
		if (x >= 1.0)
			return 1.0;
		var result:Float = (x < 0.5) ? (2 * x * x * ((c + 1) * 2 * x - c)) / 2 : (1 - 2 * (1 - x) * (1 - x) * ((c + 1) * 2 * (1 - x) - c)) / 2;
		return (result == Math.NaN) ? 1.0 : result;
	}

	public static function easeInBack(x:Float, ?c:Float = 1.70158):Float
	{
		if (x <= 0.0)
			return 0.0;
		if (x >= 1.0)
			return 1.0;
		return (1 + c) * x * x * x - c * x * x;
	}

	public static function easeOutBack(x:Float, ?c:Float = 1.70158):Float
	{
		if (x <= 0.0)
			return 0.0;
		if (x >= 1.0)
			return 1.0;
		return 1 + (c + 1) * Math.pow(x - 1, 3) + c * Math.pow(x - 1, 2);
	}

	/**
	 * Get the base-2 exponent of a value.
	 * @param x value
	 * @return `2^x`
	 */
	public static function exp2(x:Float):Float
	{
		return Math.pow(2, x);
	}

	/**
	 * Helper function to get the fractional part of a value.
	 * @param x value
	 * @return `x - floor(x)`
	 */
	public static function fract(x:Float):Float
	{
		return x - Math.floor(x);
	}

	/**
	 * Linear interpolation.
	 *
	 * @param base The starting value, when `alpha = 0`.
	 * @param target The ending value, when `alpha = 1`.
	 * @param alpha The percentage of the interpolation from `base` to `target`. Forms a "line" intersecting the two.
	 *
	 * @return The interpolated value.
	 */
	public static function lerp(base:Float, target:Float, alpha:Float):Float
	{
		if (alpha == 0)
			return base;
		if (alpha == 1)
			return target;
		return base + alpha * (target - base);
	}

	/**
	 * Exponential decay interpolation.
	 *
	 * Framerate-independent because the rate-of-change is proportional to the difference, so you can
	 * use the time elapsed since the last frame as `deltaTime` and the function will be consistent.
	 *
	 * Equivalent to `smoothLerpPrecision(base, target, deltaTime, halfLife, 0.5)`.
	 *
	 * @param base The starting or current value.
	 * @param target The value this function approaches.
	 * @param deltaTime The change in time along the function in seconds.
	 * @param halfLife Time in seconds to reach halfway to `target`.
	 *
	 * @see https://twitter.com/FreyaHolmer/status/1757918211679650262
	 *
	 * @return The interpolated value.
	 */
	public static function smoothLerpDecay(base:Float, target:Float, deltaTime:Float, halfLife:Float):Float
	{
		if (deltaTime == 0)
			return base;
		if (base == target)
			return target;
		return lerp(target, base, exp2(-deltaTime / halfLife));
	}

	/**
	 * Exponential decay interpolation.
	 *
	 * Framerate-independent because the rate-of-change is proportional to the difference, so you can
	 * use the time elapsed since the last frame as `deltaTime` and the function will be consistent.
	 *
	 * Equivalent to `smoothLerpDecay(base, target, deltaTime, -duration / logBase(2, precision))`.
	 *
	 * @param base The starting or current value.
	 * @param target The value this function approaches.
	 * @param deltaTime The change in time along the function in seconds.
	 * @param duration Time in seconds to reach `target` within `precision`, relative to the original distance.
	 * @param precision Relative target precision of the interpolation. Defaults to 1% distance remaining.
	 *
	 * @see https://twitter.com/FreyaHolmer/status/1757918211679650262
	 *
	 * @return The interpolated value.
	 */
	public static function smoothLerpPrecision(base:Float, target:Float, deltaTime:Float, duration:Float, precision:Float = 1 / 100):Float
	{
		if (deltaTime == 0)
			return base;
		if (base == target)
			return target;
		return lerp(target, base, Math.pow(precision, deltaTime / duration));
	}

	/**
	 * Snap a value to another if it's within a certain distance (inclusive).
	 *
	 * Helpful when using functions like `smoothLerpPrecision` to ensure the value actually reaches the target.
	 *
	 * @param base The base value to conditionally snap.
	 * @param target The target value to snap to.
	 * @param threshold Maximum distance between the two for snapping to occur.
	 *
	 * @return `target` if `base` is within `threshold` of it, otherwise `base`.
	 */
	public static function snap(base:Float, target:Float, threshold:Float):Float
	{
		return Math.abs(base - target) <= threshold ? target : base;
	}

	public static function floorDecimal(value:Float, decimals:Int):Float
	{
		if (decimals < 1)
		{
			return Math.floor(value);
		}

		var tempMult:Float = Math.pow(10, decimals);
		var newValue:Float = Math.floor(value * tempMult);
		return newValue / tempMult;
	}

	@:noUsing
	public inline static function fastTan(rad:Float)
	{
		return FlxMath.fastSin(rad) / FlxMath.fastCos(rad);
	}

	@:noUsing
	public static function boundInt(value:Int, min:Int, max:Int)
	{
		return FlxMath.maxInt(FlxMath.minInt(value, max), min);
	}

	@:noUsing
	public static function parseFloat(str:String, nan:Float = 0.0):Float
	{
		if (str == null)
			return nan;
		final num = Std.parseFloat(str);
		if (Math.isNaN(num))
			return nan;
		return num;
	}

	@:noUsing
	public static function parseInt(str:String, nan:Int = 0):Int
	{
		if (str == null)
			return nan;
		return Std.parseInt(str) ?? nan;
	}

	@:noUsing
	public static function getFloat(val:Any, nan:Float = 0.0):Float
	{
		if (Std.isOfType(val, Float) || Std.isOfType(val, Int))
			return cast val;
		else if (Std.isOfType(val, String))
			return parseFloat(val, nan);
		return nan;
	}

	@:noUsing
	public static function getInt(val:Any, nan:Int = 0):Int
	{
		if (Std.isOfType(val, Int) || Std.isOfType(val, Float))
			return cast val;
		else if (Std.isOfType(val, String))
			return parseInt(val, nan);
		return nan;
	}

	@:noUsing
	public static function wrapf(value:Float, min:Float, max:Float)
	{
		if (value < min)
			value += max;
		else if (value > max)
			value -= max;
		return value;
	}

	@:noUsing
	public static function approach(a:Float, b:Float, x:Float):Float
	{
		if (a > b)
		{
			return Math.max(a - x, b);
		}
		else
		{
			return Math.min(a + x, b);
		}
	}
}
