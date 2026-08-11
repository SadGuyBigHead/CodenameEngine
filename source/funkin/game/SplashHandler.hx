package funkin.game;

import funkin.backend.scripting.events.splash.*;

final class SplashHandler extends FlxTypedGroup<SplashGroup>
{
	/**
	 * Map containing all of the splashes group.
	 */
	public var grpMap:Map<String, SplashGroup> = [];

	public function new()
	{
		super();
	}

	/**
	 * Returns a group of splashes, and creates it if it doesn't exist.
	 * @param path Path to the splashes XML (`Paths.xml('splashes/splash')`)
	 */
	public function getSplashGroup(name:String)
	{
		if (!grpMap.exists(name))
		{
			var grp = new SplashGroup();
			grpMap.set(name, grp);
			add(grp);
		}
		return grpMap.get(name);
	}

	public override function destroy()
	{
		super.destroy();
		for (grp in grpMap)
			grp.destroy();
		grpMap = null;
	}

	public override function draw()
	{
		
	}

	var __grp:SplashGroup;

	public function showSplash(name:String, strum:Strum)
	{
		__grp = getSplashGroup(name);

		var event = EventManager.get(SplashShowEvent).recycle(name, strum, __grp);
		event = PlayState.instance.gameAndCharsEvent("onSplashShown", event);

		if (!event.cancelled)
		{
			PlayState.instance.noteRenderer.splashAdded(__grp.splash(event));
		}
	}
}
