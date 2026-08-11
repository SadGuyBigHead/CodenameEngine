package modchart.macro;

/**
 * Util for ArrowEffects
 */
class ArrowEffectsUtil
{
	/**
	 * Defines an inline function called `accels` with the provided playerState
	 * @param playerState 
	 */
	public static macro function getAccels(playerState:haxe.macro.Expr)
	{
		return MacroUtil.inlineFunction(macro function accels(index:Int)
			return $playerState.fAccels(index));
	}

	/**
	 * Defines an inline function called `effects` with the provided playerState
	 * @param playerState 
	 */
	public static macro function getEffects(playerState:haxe.macro.Expr)
	{
		return MacroUtil.inlineFunction(macro function effects(index:Int)
			return $playerState.fEffects(index));
	}

	/**
	 * Defines an inline function called `appearances` with the provided playerState
	 * @param playerState 
	 */
	public static macro function getAppearances(playerState:haxe.macro.Expr)
	{
		return MacroUtil.inlineFunction(macro function appearances(index:Int)
			return $playerState.fAppearances(index));
	}

	/**
	 * Defines an inline function called `scrolls` with the provided playerState
	 * @param playerState 
	 */
	public static macro function getScrolls(playerState:haxe.macro.Expr)
	{
		return MacroUtil.inlineFunction(macro function scrolls(index:Int)
			return $playerState.fScrolls(index));
	}
}
