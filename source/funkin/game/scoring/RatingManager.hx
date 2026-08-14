package funkin.game.scoring;

import funkin.game.scoring.*;
import funkin.game.scoring.HitWindowData.WindowPreset;
import flixel.util.FlxSignal;
import haxe.ds.StringMap;

/**
 * Judges note hits and returns a rating.
 */
class RatingManager
{
	public var onRatingAdded:FlxTypedSignal<Rating->Void> = new FlxTypedSignal();
	public var onRatingRemoved:FlxTypedSignal<Rating->Void> = new FlxTypedSignal();

	public var hitWindows:StringMap<Float>;
	public var ratingData:Array<Rating> = [];
	public var lastHitWindow:Float = -1;

	public var vsliceSlope:Bool = true;

	static inline final MAX_SCORE:Int = 500;
	static inline final MIN_SCORE:Int = 5;
	static inline final SCORING_OFFSET:Float = 54.99;
	static inline final SCORING_SLOPE:Float = 0.080;
	static inline final PERFECT_THRESHOLD:Float = 15.0;

	public function new(?preset:WindowPreset):Void
	{
		var usedPreset = preset != null ? preset : WindowPreset.FNF_VSDAVE;
		hitWindows = HitWindowData.getWindows(usedPreset);
		initDefaultData(hitWindows);
	}

	/**
	 * Returns a rating based on a wimdow of time.
	 * @param time The timing window to judge.
	 */
	public function judgeNote(time:Float):Rating
	{
		for (i => rating in ratingData)
		{
			if (rating.hittable && rating.window > -1 && time <= rating.window)
			{
				if (vsliceSlope)
					rating.score = vsliceScore(time);
				return rating;
			}
		}
		return ratingData.last();
	}

	function vsliceScore(time:Float)
	{
		if (time <= PERFECT_THRESHOLD)
			return MAX_SCORE;

		var factor:Float = 1.0 - (1.0 / (1.0 + Math.exp(-SCORING_SLOPE * (time - SCORING_OFFSET))));
		return Math.floor(MAX_SCORE * factor + MIN_SCORE);
	}

	/**
	 * Initializes the default rating data containing the four judgements.
	 * 
	 * "Sick", "Good", "Bad", "Shit"
	 */
	public function initDefaultData(windows:StringMap<Float>)
	{
		inline function getWindow(name:String):Float
		{
			return windows.exists(name) ? windows.get(name) : -1;
		}

		addRating({
			name: "sick",
			window: getWindow("sick"),
			accuracy: 1,
			score: 300,
			splash: true,
			health: 1.5 / 100 * 2,
		});
		addRating({
			name: "good",
			window: getWindow("good"),
			accuracy: 0.75,
			score: 200,
			health: 0.75 / 100 * 2
		});
		addRating({
			name: "bad",
			window: getWindow("bad"),
			accuracy: 0.45,
			score: 100,
			health: 0
		});
		addRating({
			name: "shit",
			window: getWindow("shit"),
			accuracy: 0.25,
			score: 50,
			health: -1.0 / 100 * 2,
			breaksCombo: Flags.SHITS_BREAK_COMBO
		});
	}

	public function addRating(data:Dynamic)
	{
		if (data == null || data.name == null)
			return;

		var name = data.name.toLowerCase();
		var window = data.window != null ? data.window : (hitWindows.exists(name) ? hitWindows.get(name) : -1);

		if (window > lastHitWindow)
			lastHitWindow = window;

		var newRating:Rating = {
			name: name,
			window: window,
			accuracy: data.accuracy != null ? data.accuracy : 1,
			score: data.score != null ? data.score : 0,
			health: data.health != null ? data.health : 0.023,
			splash: data.splash == true,
			breaksCombo: data.breaksCombo == true,
			hittable: data.hittable != null ? data.hittable : true
		};

		var existingIndex = -1;
		for (i in 0...ratingData.length)
			if (ratingData[i].name == name)
				existingIndex = i;

		if (existingIndex >= 0)
			ratingData[existingIndex] = newRating;
		else
			ratingData.push(newRating);

		ratingData.sort((a, b) -> Reflect.compare(a.window, b.window));
		onRatingAdded.dispatch(newRating);
	}

	public function removeRating(name:String):Void
	{
		if (name == null)
			return;
		name = name.toLowerCase();
		var toRemove = ratingData.filter(r -> r.name == name);
		for (rating in toRemove)
		{
			ratingData.remove(rating);
			onRatingRemoved.dispatch(rating);
		}
	}

	public function getHitWindow(name:String):Float
	{
		return hitWindows.exists(name) ? hitWindows.get(name) : -1;
	}
}

@:structInit
final class Rating
{
	/**
	 * Name of rating.
	 * 
	 * Also used for the image file name of the rating.
	 */
	public var name:String = "unknown";

	/**
	 * Amount of accuracy given when earning this rating.
	 */
	public var accuracy:Float = 0.0;

	/**
	 * MS Timing Window to hit the rating.
	 */
	public var window:Float = -1;

	/**
	 * Amount of score given when earning this rating.
	 */
	public var score:Int = 0;

	/**
	 * Amount of health given when earning this rating.
	 */
	public var health:Float = 0.023;

	/**
	 * If this rating was hit, a note splash will appear.
	 */
	@:optional public var splash:Bool = false;

	/**
	 * Whether the rating will break your combo or not.
	 */
	@:optional public var breaksCombo:Bool = false;

	/**
	 * Whether the rating is hittable or not.
	 */
	@:optional public var hittable:Bool = true;
}
