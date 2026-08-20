package dave.timeline;

/**
 * A timeline event that just runs a function
 */
class FuncEvent extends TimelineEvent
{
	var func:Void->Void;

	public function new(beat:Float, func:Void->Void)
	{
		super(beat);

		this.func = func;
	}

	override function run(beat:Float)
	{
		if (beat >= this.beat)
		{
			func();
			return true;
		}

		return false;
	}
}
