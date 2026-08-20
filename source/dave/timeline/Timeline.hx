package dave.timeline;

import funkin.backend.system.Conductor;
import flixel.util.FlxSort;

/**
 * A timeline class can scrub through a group of events
 */
class Timeline extends flixel.FlxBasic
{
	public var events:Vector<TimelineEvent> = new Vector<TimelineEvent>();

	static var garbage:Vector<TimelineEvent> = new Vector<TimelineEvent>();

	var conductor:Conductor;

	public static function sortByBeat(a:TimelineEvent, b:TimelineEvent):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, a.beat, b.beat);
	}

	public function new()
	{
		this.conductor = Conductor.instance;
		super();
	}

	/**
	 * Adds an upcoming event
	 * @param event 
	 * @return Timeline
	 */
	public function add(event:TimelineEvent):Timeline
	{
		events.push(event);
		return this;
	}

	public function remove(event:TimelineEvent):Timeline
	{
		garbage.push(event);
		return this;
	}

	public function sort():Timeline
	{
		events.sort(sortByBeat);
		return this;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		run(conductor.curBeatFloat);
	}

	public function run(beat:Float)
	{
		for (event in events)
		{
			if (beat >= event.beat)
			{
				#if debug
				var ret = false;
				try
				{
					ret = event.run(beat);
				}
				catch (e)
				{
					trace("event ereror :(", e.stack, e.details());
					ret = true;
				}
				#else
				final ret = event.run(beat);
				#end

				if (ret)
				{
					garbage.push(event);
					continue;
				}
			}
			else
			{
				break;
			}
		}

		clearGarbage();
	}

	inline function clearGarbage()
	{
		while (garbage.length > 0)
		{
			final event = garbage.shift();
			events.removeAt(events.indexOf(event));
		}
	}

	override function destroy()
	{
	}

	// simple events

	public function func(beat:Float, func:Void->Void)
	{
		if (func == null)
		{
			#if debug
			trace('[Timeline] Func Null', func);
			#end

			return;
		}

		add(new FuncEvent(beat, func));
	}

	public function funcEase(beat:Float, length:Float, ease:EaseFunction, beginPercent:Float, endPercent:Float, func:Float->Void)
	{
		if (ease == null || func == null)
		{
			#if debug
			trace('[Timeline] Ease and/or Func Null', ease, func);
			#end

			return;
		}

		add(new FuncEaseEvent(beat, length, ease, beginPercent, endPercent, func));
	}

	public function perframe(beat:Float, length:Float, func:Float->Void)
	{
		if (func == null)
		{
			#if debug
			trace('[Timeline] Func Null', func);
			#end

			return;
		}

		add(new PerframeEvent(beat, length, func));
	}
}
