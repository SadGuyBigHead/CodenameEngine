package dave;

import funkin.backend.system.Conductor;

/**
 * Lazy way to have a conductor object so i dont have to change a bunch of stufff
 */
final class DaveConductor
{
	public static var instance(get, null):DaveConductor;

	static function get_instance():DaveConductor
	{
		instance ??= new DaveConductor();
		return instance;
	}

	public var songPosition(get, never):Float;

	inline function get_songPosition()
		return Conductor.songPosition;

	public var currentBeat(get, never):Int;

	inline function get_currentBeat()
		return Conductor.curBeat;

	public var currentBeatTime(get, never):Float;

	inline function get_currentBeatTime()
		return Conductor.curBeatFloat;

	public var bpm(get, never):Float;

	inline function get_bpm()
		return Conductor.bpm;

	public function getBeatTimeInMs(beat:Float)
	{
		var tc = Conductor.bpmChangeMap[0];

		for (i in Conductor.bpmChangeMap)
		{
			if (i.beatTime <= beat)
				tc = i;
			else
				break;
		}

		// no idea lol
		// var stopOffset = .0;
		// for (stop in Conductor.stops)
		// {
		//	if (tc.beatTime >= stop.time)
		//		stopOffset += stop.length;
		// }

		return tc.songTime + ((beat - tc.beatTime) * tc.crochet);
	}

	public function getTimeInBeats(time:Float)
	{
		var tc = Conductor.bpmChangeMap[0];

		for (i in Conductor.bpmChangeMap)
		{
			if (i.songTime <= time)
				tc = i;
			else
				break;
		}

		var beatOffset = .0;
		// for (stop in Conductor.stops)
		// {
		//	if (stop.time <= time)
		//	{
		//		final len = stop.length * 1000;
		//		// pretend the time is at the start of the stop if we are in the stop
		//		if (stop.time + len >= time)
		//			time = stop.time;
		//		else
		//			beatOffset += len / stop.crochet;
		//	}
		//	else
		//	{
		//		break;
		//	}
		// }

		return tc.beatTime + ((time - tc.songTime) / tc.crochet) - beatOffset;
	}

	function new()
	{
	}
}
