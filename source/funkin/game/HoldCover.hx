package funkin.game;

class HoldCover extends StrumLineSprite
{
	static final noteColors:Array<String> = ['Purple', 'Blue', 'Green', 'Red'];

	public var timer:Float;

	public final noteSkin:NoteSkin;

	var endLength:Float;

	public function new(col:Int, noteSkin:NoteSkin)
	{
		super();
		ID = col;
		this.noteSkin = noteSkin;
		frames = Paths.getSparrowAtlas(noteSkin.covers.asset);

		final anims = noteSkin.covers.anims[col];

		animation.addByPrefix('start', anims.start.name, anims.start.fps ?? 24, false);
		animation.addByPrefix('hold', anims.hold.name, anims.hold.fps ?? 24, true);
		animation.addByPrefix('end', anims.end.name, anims.end.fps ?? 48, false);
		final endAnim = animation.getByName('end');
		endLength = endAnim.numFrames * (1 / endAnim.frameRate) * .25;
		animation.onFinish.add(onAnimFinish);
		scale.copyFrom(noteSkin.covers.scale);
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
		centerSprite();
		offset.x += noteSkin.covers.offset.x * scale.x;
		offset.y += noteSkin.covers.offset.y * scale.y;
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
