package dave.timeline;

/**
 * A timeline event that just runs a function
 */
class FuncEvent extends TimelineEvent
{
	var func:Void->Void;
	//var undoFunc:Void->Void;

	public function new(beat:Float, func:Void->Void) //, ?undoFunc:Void->Void)
	{
		super(beat);

		this.func = func;
		//this.undoFunc = undoFunc;
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
