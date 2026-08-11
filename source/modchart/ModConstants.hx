package modchart;

import openfl.Vector;
import modchart.ArrowEffects;

// add later: this but to the noteskin metrics file as an instance or something
#if !modchart_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
final class ModConstants
{
	inline static function dimVec(v = .0)
	{
		return new Vector(num_dim, true, [v, v, v]);
	}

	public static inline final FrameWidthEffectsPixelsPerSecond = 400;
	public static inline final FrameWidthEffectsMinMultiplier = 0.5;
	public static inline final FrameWidthEffectsMaxMultiplier = 1.2;
	public static inline final FrameWidthLockEffectsToOverlapping = false;
	public static inline final FrameWidthLockEffectsTweenPixels = 25;
	public static inline final ArrowSpacing = 64;
	public static inline final BlinkModFrequency = 0.3333;
	public static inline final BoostModMinClamp = -400;
	public static inline final BoostModMaxClamp = 400;
	public static inline final BrakeModMinClamp = -400;
	public static inline final BrakeModMaxClamp = 400;
	public static inline final WaveModMagnitude = 20;
	public static inline final WaveModHeight = 38;
	public static inline final BoomerangPeakPercentage = 0.75;
	public static inline final ExpandMultiplierFrequency = 3;
	public static inline final ExpandMultiplierScaleFromLow = -1;
	public static inline final ExpandMultiplierScaleFromHigh = 1;
	public static inline final ExpandMultiplierScaleToLow = 0.75;
	public static inline final ExpandMultiplierScaleToHigh = 1.75;
	public static inline final ExpandSpeedScaleFromLow = 0;
	public static inline final ExpandSpeedScaleFromHigh = 1;
	public static inline final ExpandSpeedScaleToLow = 1;
	public static inline final TipsyTimerFrequency = 1.2;
	public static inline final TipsyColumnFrequency = 1.8;
	public static inline final TipsyArrowMagnitude = 0.4;
	public static inline final TipsyOffsetTimerFrequency = 1.2;
	public static inline final TipsyOffsetColumnFrequency = 2;
	public static inline final TipsyOffsetArrowMagnitude = 0.4;
	public static final TornadoPositionScaleToLow = dimVec(-1);
	public static final TornadoPositionScaleToHigh = dimVec(1);
	public static final TornadoOffsetScaleFromLow = dimVec(-1);
	public static final TornadoOffsetScaleFromHigh = dimVec(1);
	public static final TornadoOffsetFrequency = dimVec(6);
	public static inline final DrunkColumnFrequency = 0.2;
	public static inline final DrunkOffsetFrequency = 10;
	public static inline final DrunkArrowMagnitude = 0.5;
	public static inline final DrunkZColumnFrequency = 0.2;
	public static inline final DrunkZOffsetFrequency = 10;
	public static inline final DrunkZArrowMagnitude = 0.5;
	public static inline final BeatOffsetHeight = 15;
	public static inline final BeatPIHeight = 2;
	public static inline final BeatYOffsetHeight = 15;
	public static inline final BeatYPIHeight = 2;
	public static inline final BeatZOffsetHeight = 15;
	public static inline final BeatZPIHeight = 2;
	public static inline final MiniPercentBase = 0.5;
	public static inline final MiniPercentGate = 1;
	public static inline final TinyPercentBase = 0.5;
	public static inline final TinyPercentGate = 1;
	public static inline final QuantizeArrowYPosition = false;
	public static inline final FadeBeforeTargetsPercent = 0;
	public static inline final DrawDistanceBeforeTargetsPixels = 400;
}
