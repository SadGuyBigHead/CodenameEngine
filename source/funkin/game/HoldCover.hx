package funkin.game;

class HoldCover extends FlxSprite
{
	static final noteColors:Array<String> = ['Purple', 'Blue', 'Green', 'Red'];

	public var timer:Float;

	var endLength:Float;

	public function new(col:Int)
	{
		super();
		ID = col;
		frames = Paths.getSparrowAtlas('game/notes/default');
		animation.addByPrefix('start', "holdCoverStart" + noteColors[col], 24, false);
		animation.addByPrefix('hold', "holdCover" + noteColors[col], 24, true);
		animation.addByPrefix('end', "holdCoverEnd" + noteColors[col], 48, false);
		final endAnim = animation.getByName('end');
		endLength = endAnim.numFrames * (1 / endAnim.frameRate) * .25;
		animation.onFinish.add(onAnimFinish);
		scale.set(.85, 1);
		updateHitbox();
		// offset.x += 106;
		// offset.y += 100;
		active = false;
		visible = false;
	}

	public function start(timer:Float)
	{
		this.timer = timer;
		active = true;
		visible = true;
		animation.play("start");
	}

	public function cancel()
	{
		timer = 0;
	}

	override function update(elapsed:Float)
	{
		timer -= elapsed;
		if (timer <= endLength)
			animation.play("end");
		super.update(elapsed);
		centerOffsets();
		centerOrigin();
		offset.x += 10 * scale.x;
		offset.y += 20;
	}

	function onAnimFinish(name:String)
	{
		switch name
		{
			case "start":
				animation.play("hold");
			case "end":
				active = false;
				visible = false;
		}
	}
}
