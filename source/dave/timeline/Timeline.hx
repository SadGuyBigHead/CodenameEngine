package dave.timeline;

import flixel.util.FlxSort;

/**
 * A timeline class can scrub through a group of events
 */
class Timeline extends flixel.FlxBasic
{
	public var events:Vector<TimelineEvent> = new Vector<TimelineEvent>();

	static var garbage:Vector<TimelineEvent> = new Vector<TimelineEvent>();

	var conductor:DaveConductor;

	public static function sortByBeat(a:TimelineEvent, b:TimelineEvent):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, a.beat, b.beat);
	}

	public function new()
	{
		this.conductor = DaveConductor.instance;
		super();
	}

	/**
	 * Adds an upcoming event
	 * @param event 
	 * @return Timeline
	 */
	public function add(event:TimelineEvent):Timeline
	{
		// if (event.state != UPCOMING)
		//	throw "Only upcoming events can be added";
		// if (event._broken)
		// {
		//	event.destroy();
		//	return this;
		// }
		events.push(event);
		// event.pushed();
		return this;
	}

	public function remove(event:TimelineEvent):Timeline
	{
		garbage.push(event);
		// getEventArray(event.state).remove(event);
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
		run(conductor.currentBeatTime);
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
					// log(['[HAXE ERROR] $e', e.stack, e.details()]);
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
			trace('[EREREROER] FUCUSDFSDFJSDF', func);
			return;
		}
		add(new FuncEvent(beat, func));
	}

	public function funcEase(beat:Float, length:Float, ease:EaseFunction, beginPercent:Float, endPercent:Float, func:Float->Void)
	{
		if (ease == null || func == null)
		{
			trace('[EREREROER] FUCUSDFSDFJSDF', ease, func);
			return;
		}
		add(new FuncEaseEvent(beat, length, ease, beginPercent, endPercent, func));
	}

	public function perframe(beat:Float, length:Float, func:Float->Void)
	{
		if (func == null)
		{
			trace('[EREREROER] FUCUSDFSDFJSDF', func);
			return;
		}
		add(new PerframeEvent(beat, length, func));
	}

	// public function implementToHScript(hscript:HScript)
	// {
	//	hscript.set("func", func);
	//	hscript.set("funcEase", funcEase);
	//	hscript.set("perframe", perframe);
	// }
}
