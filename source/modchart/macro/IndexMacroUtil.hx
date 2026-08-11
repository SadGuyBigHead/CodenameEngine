package modchart.macro;

/**
 * Util for indexable objects (Arrays, Vectors, etc)
 */
class IndexMacroUtil
{
	/**
	 * Sets an indexable objects value from a bunch of arguments
	 * ```haxe
	 * final array = [1, 2, 3];
	 * array.setRest(2, 3, 4, 5);
	 * trace(array); // [2, 3, 4, 5]
	 * ```
	 * @param arr 
	 * @param values 
	 */
	public static macro function setRest(arr:haxe.macro.Expr, values:Array<haxe.macro.Expr>)
	{
		final exprs = [];
		for (i => value in values)
			exprs.push(macro $arr[$v{i}] = $value);
		return macro
		{$b{exprs}}
	}

	/**
	 * Same as setRest but the first argument is an offset
	 * @param arr 
	 * @param offset Has to be a constant value
	 * @param values 
	 */
	public static macro function setRestOffset(arr:haxe.macro.Expr, offset:haxe.macro.Expr, values:Array<haxe.macro.Expr>)
	{
		final exprs = [];
		for (i => value in values)
			exprs.push(macro $arr[$v{i} + $offset] = $value);
		return macro
		{$b{exprs}}
	}

	/**
	 * This sort of thing sometimes compiles weirdly so this is a fix around that without manually writing it out every time
	 * The last argument is the value you want to set it to, the rest are indices
	 * @param value 
	 * @param args 
	 */
	public static macro function setVector(vector:haxe.macro.Expr, value:haxe.macro.Expr, args:Array<haxe.macro.Expr>)
	{
		final exprs = [macro final __value = ${args[args.length - 1]}];
		for (i in 0...args.length - 1)
			exprs.push(macro $vector[${args[i]}] = __value);
		return macro
		{$b{exprs}}
	}

	public static macro function pushr(arr:haxe.macro.Expr, values:Array<haxe.macro.Expr>)
	{
		final exprs = [for (value in values) macro $arr.push($value)];
		return macro $b{exprs}
	}
}
