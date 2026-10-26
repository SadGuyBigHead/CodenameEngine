package dave.timeline;

import funkin.backend.system.Conductor;
import flixel.util.FlxSort;

/**
 * A timeline class can scrub through a group of events
 */
class Timeline extends flixel.FlxBasic
{
	public var events:Vector<TimelineEvent> = new Vector<TimelineEvent>(0);

	var _events:Array<TimelineEvent>;

	var conductor:Conductor;

	public static function sortByBeat(a:TimelineEvent, b:TimelineEvent):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, a.beat, b.beat);
	}

	public function new()
	{
		this.conductor = Conductor.instance;
		_events = cast events;
		super();
	}

	/**
	 * Adds an upcoming event
	 * @param event 
	 * @return Timeline
	 */
	public function add(event:TimelineEvent):Timeline
	{
		_events.push(event);
		return this;
	}

	public function remove(event:TimelineEvent):Timeline
	{
		_events.remove(event);
		return this;
	}

	public function sort():Timeline
	{
		haxe.ds.ArraySort.sort(_events, sortByBeat);
		return this;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		run(conductor.curBeatFloat);
	}

	public function run(beat:Float)
	{
		var i = 0;
		var len = events.length;
		while (i < len)
		{
			final event = events[i];
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
					_events.splice(i, 1);
					len--;
					continue;
				}
				i++;
			}
			else
			{
				break;
			}
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
