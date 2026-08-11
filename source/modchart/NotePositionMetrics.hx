package modchart;

class NotePositionMetrics
{
	public static final defaultReceptorArrowsYStandard:Int = -88;

	public static final defaultReceptorArrowsYReverse:Int = 400;

	public static final defaultFadeDistY:Int = 60;

	public static final defaultPlayFieldX:Int = 195;

	public static final defaultPlayFieldDistance:Int = 576;

	// @:default(deepend.game.playfield.NotePositionMetrics.defaultReceptorArrowsYStandard)
	public var receptorArrowsYStandard:Float = defaultReceptorArrowsYStandard;

	// @:default(deepend.game.playfield.NotePositionMetrics.defaultReceptorArrowsYReverse)
	public var receptorArrowsYReverse:Float = defaultReceptorArrowsYReverse;

	@:jignored
	public var reverseOffset(get, never):Float;

	// @:default(deepend.game.playfield.NotePositionMetrics.defaultFadeDistY)
	public var fadeDistY:Float = defaultFadeDistY;

	// @:default(deepend.game.playfield.NotePositionMetrics.defaultPlayFieldX)
	public var playFieldX:Float = defaultPlayFieldX;

	// @:default(deepend.game.playfield.NotePositionMetrics.defaultPlayFieldDistance)
	public var playFieldDistance:Float = defaultPlayFieldDistance;

	inline function get_reverseOffset():Float
	{
		return receptorArrowsYReverse - receptorArrowsYStandard;
	}

	public function new()
	{
	}
}
