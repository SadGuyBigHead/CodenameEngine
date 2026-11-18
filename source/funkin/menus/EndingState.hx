package funkin.menus;

import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import dave.DaveBitmapText;
import haxe.Json;

using StringTools;

class EndingState extends MusicBeatState
{
	var weekName:String = "dave";
	var weekAcc:Float = 1;

	var endingName:String = "good";
	var endingSprite:String = "dave/good";
	var endingTrack:String = "good";
	var endingTitle:String = "AHHHHHHH";
	var endingDesc:String = "AHHHHHHH";

	var canPress:Bool = true;

	var endingGraphic:FlxSprite;
	var titleText:DaveBitmapText;
	var descText:DaveBitmapText;

	public function new(week:String, acc:Float):Void
	{
		weekName = week;
		weekAcc = acc;
		super();
	}

	override function create()
	{
		pickEnding();

		CoolUtil.playMusic(Paths.music("endings/" + endingTrack));

		var bg = new FlxSprite().makeSolid(FlxG.width * 8, FlxG.height * 8, FlxColor.BLACK);
		bg.screenCenter();
		add(bg);

		endingGraphic = new FlxSprite();
		endingGraphic.frames = Paths.getSparrowAtlas("endings/" + endingSprite);
		endingGraphic.animation.addByPrefix(endingName, endingName, 12, true);
		endingGraphic.animation.play(endingName, true);
		endingGraphic.antialiasing = Options.antialiasing;
		endingGraphic.scale.set(0.5, 0.5);
		endingGraphic.updateHitbox();
		endingGraphic.screenCenter();
		endingGraphic.y -= 100;
		add(endingGraphic);

		titleText = new DaveBitmapText(0, 0, endingTitle, 64 * .9, "perep");
		titleText.letterSpacing = 2;
		titleText.screenCenter();
		titleText.y += 155;
		titleText.alignment = FlxTextAlign.CENTER;
		titleText.antialiasing = Options.antialiasing;
		add(titleText);

		descText = new DaveBitmapText(0, 0, endingDesc, 64 * .5, "perep");
		descText.letterSpacing = 2;
		descText.screenCenter();
		descText.y += 230;
		descText.alignment = FlxTextAlign.CENTER;
		descText.antialiasing = Options.antialiasing;
		add(descText);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (canPress)
		{
			if (controls.ACCEPT || controls.BACK)
			{
				canPress = false;

				CoolUtil.playMenuSFX(CONFIRM, 0.7);
				FlxG.sound.music.fadeOut(0.9, 0);
				FlxTween.tween(endingGraphic, {alpha: 0}, 0.9, {ease: FlxEase.quintOut});
				FlxTween.tween(titleText, {alpha: 0}, 0.9, {ease: FlxEase.quintOut});
				FlxTween.tween(descText, {alpha: 0}, 0.9, {ease: FlxEase.quintOut});

				var timTim = new FlxTimer().start(1, function ddd(f:FlxTimer)
				{
					if (FlxG.sound.music != null)
					{
						FlxG.sound.music.stop();
					}

					FlxG.switchState(new StoryMenuState());
				});
			}
		}
	}

	function pickEnding()
	{
		var weekdata = cast Json.parse(Assets.getText(Paths.json("endings/" + weekName)));

		var ind:Int = weekdata.endings.length;
		var foundit:Bool = false;
		while (!foundit)
		{
			ind--;

			if (weekdata.endings[ind][1] <= weekAcc)
			{
				foundit = true;
			}
			else if (ind == 0)
			{
				foundit = true;
			}
		}

		endingName = Std.string(weekdata.endings[ind][0]);

		if (FlxG.save.data.endingOverride != null)
		{
			endingName = FlxG.save.data.endingOverride;
			FlxG.save.data.endingOverride = null;
		}

		var data = cast Json.parse(Assets.getText(Paths.json("endings/" + weekName + "/" + endingName)));

		endingSprite = data.sprite;
		endingTrack = data.song;
		endingTitle = data.name;
		endingDesc = data.text;
	}
}
