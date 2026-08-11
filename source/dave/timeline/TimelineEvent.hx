package dave.timeline;

/**
 * The base timeline event
 * Runs `run` and the event is over when it returns true
 */
class TimelineEvent implements IFlxDestroyable
{
	public var beat:Float;

	@:allow(apple.timeline)
	public var state(default, null):TimelineEventState = UPCOMING;

	public function new(beat:Float)
	{
		this.beat = beat;
	}

	/**
	 * Runs this event
	 * @param beat The current beat
	 * @return Bool `true` if the event is over
	 */
	public function run(time:Float):Bool
	{
		return true;
	}

	/**
	 * Undos this event (sometimes the same as running if its like an ease or something)
	 * @param beat 
	 * @return Bool `true` if the event has been undone
	 */
	public function undo(time:Float):Bool
	{
		return true;
	}

	public function destroy()
	{
	}
}
