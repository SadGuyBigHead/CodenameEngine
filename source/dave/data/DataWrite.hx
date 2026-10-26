package dave.data;

import openfl.utils.Object;
import flixel.util.FlxColor;
import haxe.ds.Either;
import hxjsonast.Json;
import hxjsonast.Printer;

/**
 * `json2object` has an annotation `@:jcustomwrite` which allows for custom serialization of values to be written to JSON.
 *
 * Functions must be of the signature `(T) -> String`, where `T` is the type of the property.
 *
 * NOTE: Result must include quotation marks if the value is a string! json2object will not add them for you!
 */
// @:nullSafety // no
class DataWrite
{
	static final JSON_FORMAT:String = "    ";

	// ======================
	// GENERAL
	// =====================

	@:nullSafety(Off)
	public static function stringArray(val:Array<String>):String
	{
		if (val == null)
			return null;
		return Printer.print(stringArrayJson(val), JSON_FORMAT);
	}

	/**
	 * Returns a json string array, or just a string if the array length is one
	 * @param val 
	 * @return Json
	 */
	static function stringArrayJson(val:Array<String>):Json
	{
		return {
			value: val.length == 1 ? JString(val[0]) : JArray([for (i in val) {value: JString(i), pos: null}]),
			pos: null,
		}
	}

	public static function string(v:Null<String>):Null<String>
	{
		return v != null ? '"$v"' : null;
	}

	static function map<K, V>(map:Map<K, V>):String
	{
		if (map == null)
			return null;
		final obj = new Object();
		for (k => v in map)
			Reflect.setField(obj, '$k', v);
		return dynamicValue(obj);
	}

	/**
	 * `@:jcustomwrite(funkin.data.DataWrite.dynamicValue)`
	 * @param value
	 * @return String
	 */
	public static function dynamicValue(value:Dynamic):String
	{
		if (value == null)
			return null;
		// Is this cheating? Yes. Do I care? No.
		return SerializerUtil.toJSON(value);
	}

	/**
	 * `@:jcustomwrite(funkin.data.DataWrite.eitherFloatOrFloats)`
	 */
	public static function eitherFloatOrFloats(value:Null<Either<Float, Array<Float>>>):String
	{
		switch (value)
		{
			case null:
				return '${1.0}';
			case Left(inner):
				return '$inner';
			case Right(inner):
				return dynamicValue(inner);
		}
	}

	// ======================
	// SPRITE STUFF
	// =====================

	@:nullSafety(Off)
	public static function color(val:Null<FlxColor>):String
	{
		return string(val?.toWebString());
	}

	@:nullSafety(Off)
	public static function point(value:FlxPoint):String
	{
		if (value == null)
			return null;
		final arr = [value.x, value.y];
		while (arr.length > 0 && arr[arr.length - 1] == 0.0)
			arr.pop();
		if (arr.length == 0)
			return null;
		return Printer.print({value: JArray([for (i in arr) {value: JNumber('$i'), pos: null}]), pos: null}, JSON_FORMAT);
	}

	@:nullSafety(Off)
	public static function scalePoint(value:FlxPoint):String
	{
		if (value == null)
			return null;
		if (value.x == value.y)
			return '${value.x}';
		final arr = [value.x, value.y];
		while (arr.length > 0 && arr[arr.length - 1] == 0.0)
			arr.pop();
		if (arr.length == 0)
			return null;
		return Printer.print({value: JArray([for (i in arr) {value: JNumber('$i'), pos: null}]), pos: null}, JSON_FORMAT);
	}

	public static function indices(value:Array<Int>):String
	{
		if (value == null)
			return null;
		// check for single
		if (value.length == 1)
			return '${value[0]}';
		// check for range
		var range = true;
		for (i in 1...value.length)
		{
			if (FlxMath.absInt(value[i] - value[i - 1]) > 1)
			{
				range = false;
				break;
			}
		}
		if (range)
		{
			// make [[start, end]] syntax
			return Printer.print({
				value: JArray([
					{
						value: JArray([
							{value: JNumber('${value[0]}'), pos: null},
							{value: JNumber('${value.last()}'), pos: null},
						]),
						pos: null,
					}
				]),
				pos: null,
			}, JSON_FORMAT);
		}

		// simple :)
		return Printer.print({value: JArray([for (i in value) {value: JNumber('$i'), pos: null}]), pos: null}, JSON_FORMAT);
	}
}
