package funkin.game;

import modchart.ArrowEffects;
import flixel.tweens.FlxTween;
import funkin.game.scoring.RatingManager;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.group.FlxContainer;
import flixel.system.FlxAssets.FlxShader;

class JudgementDisplay extends FlxContainer
{
	public var judgement:FlxSprite;
	public var combo:FlxTypedContainer<FlxSprite>;

	public var ratings:RatingManager;

	public var judgementScale:Float = 0.5;

	public var comboNumScale:Float = 0.3;

	public var bumpTweenScale:Float = 1.1;

	public var asset(default, set):String;

	function set_asset(asset:String)
	{
		if (this.asset != asset)
		{
			assetFrames = Paths.getSparrowAtlas(asset);
			// find widest number frame
			for (frame in assetFrames.frames)
			{
				if (frame.name.startsWith("num"))
					comboNumWidth = Math.max(comboNumWidth, frame.sourceSize.x) * comboNumScale;
			}
			judgement = constructJudgement(judgement);
			allocateCombo(3);
		}

		return this.asset = asset;
	}

	public var yOffset:Float = 490.0;

	var assetFrames:FlxFramesCollection;

	var comboNumWidth:Float;

	var tweens:Array<FlxTween> = [];

	public function new(ratings:RatingManager)
	{
		super();

		this.ratings = ratings;

		combo = new FlxTypedContainer<FlxSprite>();

		asset = "game/judgement";
		add(combo);
	}

	public function display(strumLine:StrumLine, rating:String, comboNum:Int):Void
	{
		var x:Float = FlxG.width * .5;
		var y:Float = FlxG.height * .5;
		var shader:FlxShader = null;

		if (strumLine != null)
		{
			cameras = strumLine.cameras;

			if (PlayState.instance?.noteRenderer.mods.active)
			{
				final renderer = PlayState.instance.noteRenderer;
				final ofsY:Float = yOffset;
				shader = renderer.judgementShaders[strumLine.ID];
				x = .001; // i really gotta get rid of this weird ass shader stuff
				y = -renderer.mods.position.reverseOffset * .5;
				if ((PlayState.instance?.downscroll ?? Options.downscroll))
				{
					y -= ofsY;
				}
				else
				{
					y += ofsY;
				}
			}
			else
			{
				final size:Float = ArrowEffects.ARROW_SIZE * (strumLine.strumScale ?? 1.0) * (strumLine.data.strumSpacing ?? 1.0);
				final lanes:Int = strumLine.data.keyCount ?? 4;
				final ofsY:Float = yOffset + (ArrowEffects.ARROW_SIZE * .5);

				x = strumLine.startingPos.x + (size * (lanes * .5) * .5) + (size * .5);
				y = strumLine.startingPos.y;

				if ((PlayState.instance?.downscroll ?? Options.downscroll))
				{
					y -= ofsY;
				}
				else
				{
					y += ofsY;
				}
			}
		}
		else
		{
			cameras = (PlayState.instance != null ? [PlayState.instance.camHUD] : null);
		}

		judgement = constructJudgement(judgement.exists ? judgement : null);
		judgement.revive();
		judgement.animation.play(rating);
		judgement.updateHitbox();
		judgement.alpha = 1.0;
		judgement.x = x - judgement.width * .5;
		judgement.y = y - judgement.height;
		judgement.shader = shader;
		tween(judgement);

		if (comboNum < 5)
		{
			for (spr in combo.members)
				spr?.kill();
			return;
		}

		final comboStr:String = '$comboNum';
		final comboWidth:Float = comboStr.length * comboNumWidth;
		final comboLeft:Float = x - comboWidth * .5;
		allocateCombo(comboStr.length);
		for (i in 0...comboStr.length)
		{
			final digit:String = comboStr.charAt(i);
			final digitSpr:FlxSprite = combo.members[i];
			digitSpr.revive();
			digitSpr.animation.play(digit);
			digitSpr.updateHitbox();
			digitSpr.alpha = 1.0;
			digitSpr.x = comboLeft + i * comboNumWidth;
			digitSpr.y = y;
			digitSpr.shader = shader;
			tween(digitSpr);
		}
	}

	function tween(spr:FlxSprite)
	{
		FlxTween.cancelTweensOf(spr);
		final scaleX:Float = spr.scale.x;
		final scaleY:Float = spr.scale.y;
		spr.scale.scale(bumpTweenScale);

		FlxTween.tween(spr.scale, {x: scaleX, y: scaleY}, .1, {ease: FlxEase.sineOut})
			.then(FlxTween.tween(spr, {alpha: 0}, .2, {ease: FlxEase.sineOut, startDelay: .5, onComplete: _ -> spr.kill()}));
	}

	function constructJudgement(?spr:FlxSprite):FlxSprite
	{
		spr ??= new FlxSprite();
		if (spr.frames != assetFrames)
		{
			spr.frames = assetFrames;
			for (rating in ratings.ratingData)
				spr.animation.addByPrefix(rating.name, rating.name, 24);
			spr.animation.addByPrefix("miss", "miss", 24);
		}
		spr.antialiasing = Options.antialiasing;
		spr.scale.set(judgementScale, judgementScale);
		spr.updateHitbox();
		spr.kill();
		add(spr);
		return spr;
	}

	function constructNumber(?spr:FlxSprite):FlxSprite
	{
		spr ??= new FlxSprite();
		if (spr.frames != assetFrames)
		{
			spr.frames = assetFrames;
			for (num in 0...10)
				spr.animation.addByPrefix('$num', 'num$num', 24);
		}
		spr.scale.set(comboNumScale, comboNumScale);
		spr.antialiasing = Options.antialiasing;
		spr.updateHitbox();
		spr.kill();
		return spr;
	}

	function allocateCombo(digits:Int):Void
	{
		while (combo.length < digits)
			combo.add(constructNumber());
		for (i in 0...combo.length)
			combo.members[i] = constructNumber(combo.members[i]?.exists ? combo.members[i] : null);
	}
}
