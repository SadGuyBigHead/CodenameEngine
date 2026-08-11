package dave.timeline;

/**
 * A timeline event that just runs every frame from `beat` for `length` beats
 */
class PerframeEvent extends TimelineEvent
{
	var func:Float->Void;
	var length:Float;

	public function new(beat:Float, length:Float, func:Float->Void)
	{
		super(beat);

		this.func = func;
		this.length = length;
	}

	override function run(time:Float):Bool
	{
		if (time >= beat)
		{
			func(Math.min(beat + length, time));
			return time >= beat + length;
		}
		return false;
	}
}
