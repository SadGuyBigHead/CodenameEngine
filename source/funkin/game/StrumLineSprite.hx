package funkin.game;

import flixel.graphics.frames.FlxFrame;

class StrumLineSprite extends FlxSprite
{
	public var column(get, never):Int;

	inline function get_column():Int
	{
		return ID;
	}

	var targetFrame:FlxFrame;
	
	public function centerSprite()
	{
		updateHitbox();
		centerOrigin();

		// wtf lol
		offset.x = (frameWidth * 0.5);
		offset.y = (frameHeight * 0.5);
	}
}