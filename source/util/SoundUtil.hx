package util;

import flixel.sound.FlxSound;

class SoundUtil
{
	/**
	 * Stupid? idk but it makes resyncs just sorta good
	 * @param sound 
	 * @return Int
	 */
	public static inline function getSourceTime(sound:FlxSound):Float
	{
		return sound.source.currentTime + sound.source.offset;
	}

	/**
	 * Makes it all awesome and stuff
	 * @param sound 
	 * @param time 
	 * @return Int
	 */
	public static function setSourceTime(sound:FlxSound, time:Float):Float
	{
		sound.play();
		if (getSourceTime(sound) != time)
		{
			sound.source.currentTime = time - sound.source.offset; // no idea what the offset is lol
		}
		return time;
	}
}
