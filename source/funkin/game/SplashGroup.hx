package funkin.game;

import funkin.backend.scripting.events.splash.SplashShowEvent;
import haxe.xml.Access;

final class SplashGroup extends FlxTypedGroup<Splash>
{
	public function new()
	{
		super();
	}

	public var grp = new FlxTypedGroup();

	function splashFactory()
	{
		final spr = new Splash();
		spr.frames = Paths.getSparrowAtlas('game/notes/splash');
		spr.animation.addByPrefix("1", "splash1", 18, false);
		spr.animation.addByPrefix("2", "splash2", 18, false);
		spr.animation.onFinish.add(_ ->
		{
			PlayState.instance.noteRenderer.splashKilled(spr);
			spr.kill();
		});
		return spr;
	}

	public function splash(event:SplashShowEvent)
	{
		final strumScale = event.strum.strumLine.strumScale;
		final spr = recycle(null, splashFactory);
		spr.ID = event.strum.ID;
		spr.strum = event.strum;
		spr.animation.play(Std.string(FlxG.random.int(1, 2)), true);
		spr.angle = FlxG.random.float(-360, 360);
		spr.updateHitbox();
		spr.centerOffsets();
		spr.centerOrigin();
		spr.offset.x += 160 * .7 * .5;
		spr.offset.x += 13;
		spr.offset.y += 160 * .7 * .5;
		spr.offset.y += 11;
		spr.offset.x *= strumScale;
		spr.offset.y *= strumScale;
		return spr;
	}
}
