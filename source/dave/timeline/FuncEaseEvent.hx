package dave.timeline;

import flixel.tweens.FlxEase.EaseFunction;

/**
 * A timeline event that takes a function that has an eased input
 */
class FuncEaseEvent extends TimelineEvent
{
	var length:Float;
	var ease:EaseFunction;
	var beginPercent:Float;
	var endPercent:Float;
	var func:Float->Void;

	public function new(beat:Float, length:Float, ease:EaseFunction, beginPercent:Float, endPercent:Float, func:Float->Void)
	{
		super(beat);
		this.length = length;
		this.beginPercent = beginPercent;

		this.endPercent = endPercent;
		this.func = func;
		this.ease = ease;
	}

	override function run(time:Float):Bool
	{
		if (time >= beat)
		{
			final t = Math.min(1.0, (time - beat) / length);
			func(FlxMath.lerp(beginPercent, endPercent, ease(t)));
			return t >= 1;
		}
		return false;
	}
}
