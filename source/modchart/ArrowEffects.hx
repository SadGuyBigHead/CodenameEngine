package modchart;

import modchart.Modchart;
import math.BezierUtil;
import flixel.tweens.FlxEase;
import math.MathUtil;
import flixel.math.FlxRandom;
import openfl.Vector;
import flixel.math.FlxAngle;
import modchart.Modchart;
import modchart.ModConstants as C;
import flixel.util.FlxPool;
import modchart.macro.ArrowEffectsUtil.getAccels;
import modchart.macro.ArrowEffectsUtil.getEffects;
import modchart.macro.ArrowEffectsUtil.getAppearances;
import modchart.macro.ArrowEffectsUtil.getScrolls;

import funkin.game.PlayState;

#if !modchart_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
final class ArrowEffects extends FlxBasic
{
	public static final ARROW_SIZE = funkin.game.Note.swagWidth;
	public static final ARROW_SIZE_HALF = funkin.game.Note.swagWidth * .5;
	public static final ARROW_SPACING = ARROW_SIZE;
	public static final ROWS_PER_BEAT = 48;

	public var position:NotePositionMetrics;
	public var conductor(get, never):DaveConductor;

	public var playerStates:Vector<PlayerState>;
	public var effectData:Vector<PerPlayerData>;

	// we arent c++
	public var fPeakYOffsetOut:Float;
	public var bIsPastPeakOut:Bool;

	public var curr_options:PlayerState;

	public final players:Int;

	var fShiftOut:Float;
	var fScaleOut:Float;

	var localRandom = new FlxRandom(0);

	public function new(position:NotePositionMetrics, players:Int)
	{
		super();
		this.position = position;
		this.players = players;
		playerStates = new Vector<PlayerState>(players, true, [for (i in 0...players) new PlayerState(i, new PlayField(i))]);
		effectData = new Vector<PerPlayerData>(players, true, [for (i in 0...players) new PerPlayerData(i)]);

		// trace('with lpayers', players, playerStates);

		for (player in 0...players)
			init(player);
	}

	public function init(pn:Int):Void
	{
		final data = effectData[pn];
		final wide_field = false;
		final keyCount = playerStates[pn].keyCount;
		final max_player_col = keyCount - 1;
		for (dimension in 0...num_dim)
		{
			var width = 3;
			if (dimension == 0 && wide_field)
				width = 2;
			for (col_id in 0...keyCount)
			{
				final start_col = MathUtil.boundInt(col_id - width, 0, max_player_col);
				final end_col = MathUtil.boundInt(col_id + width, 0, max_player_col);
				data.minTornado[dimension][col_id] = 9999.;
				data.maxTornado[dimension][col_id] = -9999.;
				for (i in start_col...end_col + 1)
				{
					data.minTornado[dimension][col_id] = Math.min(playerStates[pn].xOffset[i], data.minTornado[dimension][col_id]);
					data.maxTornado[dimension][col_id] = Math.max(playerStates[pn].xOffset[i], data.maxTornado[dimension][col_id]);
				}
			}
		}
	}

	public function pushNodes()
	{
		// trace("PUSHING NODES");
		for (pn in 0...players)
		{
			final playerState = playerStates[pn];
			// update mods from nodes
			for (mod in playerState.nodes)
				mod.callback(pn, false, mod.dirty);
		}
	}

	public function popNodes()
	{
		// trace("POPPING NODES");
		for (pn in 0...players)
		{
			final playerState = playerStates[pn];
			// unupdate mods from nodes
			for (mod in playerState.nodes)
			{
				mod.callback(pn, true, false);
				mod.dirty = false;
			}
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		pushNodes();
		for (pn in 0...players)
		{
			final playerState = playerStates[pn];
			curr_options = playerState;
			final data = effectData[pn];
			getEffects(playerState);
			getAccels(playerState);
			final field_zoom = 1.0;

			switch playerState.modTimerType
			{
				case ModTimerType_Default, ModTimerType_Game:
					playerState.timer += elapsed;
				case ModTimerType_Beat:
					playerState.timer = conductor.currentBeatTime;
				case ModTimerType_Song:
					playerState.timer = conductor.songPosition / 1000;
			}

			var freeze = false;
			var delay = false;
			if (!freeze || delay)
			{
				data.fExpandSeconds += playerState.timer - playerState.lastTime;
				data.fExpandSeconds = mod(data.fExpandSeconds, (Math.PI * 2) / (accels(ACCEL_EXPAND_PERIOD) + 1));
				data.fTanExpandSeconds += playerState.timer - playerState.lastTime;
				data.fTanExpandSeconds = mod(data.fTanExpandSeconds, (Math.PI * 2) / (accels(ACCEL_TAN_EXPAND_PERIOD) + 1));
			}

			for (iColNum in 0...playerState.keyCount)
			{
				final iNumCols = playerState.keyCount;
				final iNumSides = 1;
				final iNumColsPerSide = Std.int(iNumCols / iNumSides);
				final iSideIndex = Std.int(iColNum / iNumColsPerSide);
				final iColOnSide = iColNum % iNumColsPerSide;

				final iColLeftOfMiddle = Std.int((iNumColsPerSide - 1) / 2);
				final iColRightOfMiddle = Std.int((iNumColsPerSide + 1) / 2);

				var iFirstColOnSide = -1;
				var iLastColOnSide = -1;
				if (iColOnSide <= iColLeftOfMiddle)
				{
					iFirstColOnSide = 0;
					iLastColOnSide = iColLeftOfMiddle;
				}
				else if (iColOnSide >= iColRightOfMiddle)
				{
					iFirstColOnSide = iColRightOfMiddle;
					iLastColOnSide = iNumColsPerSide - 1;
				}
				else
				{
					iFirstColOnSide = Std.int(iColOnSide / 2);
					iLastColOnSide = Std.int(iColOnSide / 2);
				}

				final iNewColOnSide = if (iFirstColOnSide == iLastColOnSide) 0; else Std.int(FlxMath.remapToRange(iColOnSide, iFirstColOnSide, iLastColOnSide,
					iLastColOnSide, iFirstColOnSide));
				final iNewCol = iSideIndex * iNumColsPerSide + iNewColOnSide;

				final fOldPixelOffset = playerState.xOffset[iColNum];
				final fNewPixelOffset = playerState.xOffset[iNewCol];
				data.fInvertDistance[iColNum] = fNewPixelOffset - fOldPixelOffset;
			}

			if (effects(EFFECT_TIPSY) != 0)
			{
				updateTipsy(data.tipsy_result, data.tipsy_offset_result, effects(EFFECT_TIPSY_OFFSET), effects(EFFECT_TIPSY_SPEED), false,
					playerState.keyCount);
			}
			else
			{
				for (col in 0...playerState.keyCount)
					data.tipsy_result[col] = 0;
			}

			if (effects(EFFECT_TAN_TIPSY) != 0)
			{
				updateTipsy(data.tan_tipsy_result, data.tan_tipsy_offset_result, effects(EFFECT_TAN_TIPSY_OFFSET), effects(EFFECT_TAN_TIPSY_SPEED), true,
					playerState.keyCount);
			}
			else
			{
				for (col in 0...playerState.keyCount)
					data.tan_tipsy_result[col] = 0;
			}

			updateBeat(dim_x, data, conductor, effects(EFFECT_BEAT_OFFSET), effects(EFFECT_BEAT_MULT));
			updateBeat(dim_y, data, conductor, effects(EFFECT_BEAT_Y_OFFSET), effects(EFFECT_BEAT_Y_MULT));
			updateBeat(dim_z, data, conductor, effects(EFFECT_BEAT_Z_OFFSET), effects(EFFECT_BEAT_Z_MULT));

			if (effects(EFFECT_JIMBLE) != 0)
			{
				for (i in 0...playerState.keyCount)
				{
					data.fJimbleTime[i] = Math.floor((1 + effects(EFFECT_JIMBLE_SPEED)) * (getTime() + (i * effects(EFFECT_JIMBLE_SPREAD))) * 16);
					data.fJimbleTan[i] = playerState.bJimbleUseTan ? selectTanType(data.fJimbleTime[i],
						curr_options.bCosecant) : FlxMath.fastCos(data.fJimbleTime[i] + 2);
					data.fJimbleSin[i] = FlxMath.fastSin(data.fJimbleTime[i]);
					data.fJimbleCos[i] = FlxMath.fastCos(data.fJimbleTime[i]);
				}
			}
			playerState.lastTime = playerState.timer;
		}
		popNodes();
	}

	public function getTime():Float
	{
		return (curr_options.timer + curr_options.modTimerOffset) * (1.0 + curr_options.modTimerMult);
	}

	public function getYOffset(playerState:PlayerState, iCol:Int, fNoteBeat:Float, fNoteMs:Float, ?bAbsolute:Bool, ?basic:Bool):Float
	{
		playerState.curr_dir = iCol + 1;
		final data = effectData[playerState.player];
		fPeakYOffsetOut = Math.POSITIVE_INFINITY;
		bIsPastPeakOut = true;

		var fYOffset = .0;

		if (playerState.fTimeSpacing != 1.0)
		{
			final fSongBeat = conductor.currentBeatTime;
			final fBeatsUntilStep = (fNoteBeat - fSongBeat) + playerState.fScrolls(SCROLL_CENTERED_PATH);
			final fYOffsetBeatSpacing = fBeatsUntilStep * ARROW_SPACING;
			fYOffset += fYOffsetBeatSpacing * (1 - playerState.fTimeSpacing);
		}

		if (playerState.fTimeSpacing != 0.0)
		{
			final fMsUntilStep = .45 * (fNoteMs - DaveConductor.instance.songPosition) + playerState.fScrolls(SCROLL_CENTERED_PATH);
			fYOffset += fMsUntilStep * playerState.fTimeSpacing;
		}

		if (fYOffset < 0 || basic)
			return fYOffset * playerState.fScrollSpeed * playerState.xmod;

		getAccels(playerState);
		getEffects(playerState);

		var fYAdjust = .0;

		if (accels(ACCEL_BOOST) != 0)
		{
			final fNewYOffset = fYOffset * 1.5 / ((fYOffset + FlxG.height / 1.2) / FlxG.height);
			final fAccelYAdjust = accels(ACCEL_BOOST) * (fNewYOffset - fYOffset);
			fYAdjust += FlxMath.bound(fAccelYAdjust, -400, 400);
		}

		if (accels(ACCEL_BRAKE) != 0)
		{
			final fScale = FlxMath.remapToRange(fYOffset, 0, FlxG.height, 0, 1);
			final fNewYOffset = fYOffset * fScale;
			final fBrakeYAdjust = accels(ACCEL_BRAKE) * (fNewYOffset - fYOffset);
			fYAdjust += FlxMath.bound(fBrakeYAdjust, -400, 400);
		}

		if (accels(ACCEL_WAVE) != 0)
			fYAdjust += accels(ACCEL_WAVE) * C.WaveModMagnitude * FlxMath.fastSin(fYOffset / ((accels(ACCEL_WAVE_PERIOD) * C.WaveModHeight) + C.WaveModHeight));

		if (effects(EFFECT_PARABOLA_Y) != 0)
			fYAdjust += effects(EFFECT_PARABOLA_Y) * (fYOffset / ARROW_SIZE) * (fYOffset / ARROW_SIZE);

		fYOffset += fYAdjust;

		if (accels(ACCEL_BOOMERANG) != 0)
		{
			final fOriginalYOffset = fYOffset;

			fYOffset = (-1 * fOriginalYOffset * fOriginalYOffset / FlxG.height) + 1.5 * fOriginalYOffset;
			final fPeakAtYOffset = FlxG.height * .75;
			fPeakYOffsetOut = (-1 * fPeakAtYOffset * fPeakAtYOffset / FlxG.height) + 1.5 * fPeakAtYOffset;
			bIsPastPeakOut = fOriginalYOffset < fPeakAtYOffset;
		}

		var fScrollSpeed = playerState.fScrollSpeed * playerState.xmod;
		if (playerState.fRandomSpeed != 0 && !bAbsolute)
		{
			localRandom.currentSeed = FlxG.random.currentSeed + (Std.int(conductor.currentBeatTime * ROWS_PER_BEAT) << 8) + (iCol * 100);

			final fRandom = localRandom.float(0, 10); // idk
			fScrollSpeed *= FlxMath.remapToRange(fRandom, 0, 1, 1, playerState.fRandomSpeed + 1);
		}

		if (accels(ACCEL_EXPAND) != 0)
		{
			final fExpandMultiplier = FlxMath.remapToRange(FlxMath.fastCos(data.fExpandSeconds * 3), -1, 1, .75, 1.75);
			fScrollSpeed *= FlxMath.remapToRange(accels(ACCEL_EXPAND), 0, 1, 1, fExpandMultiplier);
		}

		if (accels(ACCEL_TAN_EXPAND) != 0)
		{
			final fTanExpandMultiplier = FlxMath.remapToRange(selectTanType(data.fTanExpandSeconds * 3, curr_options.bCosecant), -1, 1, .75, 1.75);
			fScrollSpeed *= FlxMath.remapToRange(accels(ACCEL_TAN_EXPAND), 0, 1, 1, fTanExpandMultiplier);
		}

		fYOffset *= fScrollSpeed;
		fPeakYOffsetOut *= fScrollSpeed;

		return fYOffset;
	}

	public function getYPos(playerState:PlayerState, iCol:Int, yOffset:Float, fYReverseOffsetPixels:Float, withReverse:Bool):Float
	{
		var f = yOffset;

		if (withReverse)
		{
			arrowGetReverseShiftAndScale(playerState, iCol, fYReverseOffsetPixels);

			f *= fScaleOut;
			f += fShiftOut;
		}

		final data = effectData[playerState.player];
		getEffects(playerState);
		f += effects(EFFECT_TIPSY) * data.tipsy_result[iCol];
		f += effects(EFFECT_TAN_TIPSY) * data.tan_tipsy_result[iCol];

		if (effects(EFFECT_ATTENUATE_Y) != 0)
		{
			final fXOffset = playerState.xOffset[iCol];
			f += effects(EFFECT_ATTENUATE_Y) * (yOffset / ARROW_SIZE) * (yOffset / ARROW_SIZE) * (fXOffset / ARROW_SIZE);
		}

		if (effects(EFFECT_BEAT_Y) != 0)
		{
			final fShift = data.fBeatFactor[dim_y] * FlxMath.fastSin(yOffset / ((effects(EFFECT_BEAT_Y_PERIOD) * C.BeatYOffsetHeight) + C.BeatYOffsetHeight)
				+ Math.PI / C.BeatYPIHeight);
			f += effects(EFFECT_BEAT_Y) * fShift;
		}

		if (effects(EFFECT_JIMBLE) != 0)
			f += effects(EFFECT_JIMBLE) * data.fJimbleSin[iCol];

		return f;
	}

	public function getYOffsetFromYPos(playerState:PlayerState, iCol:Int, yPos:Float, fYReverseOffsetPixels:Float):Float
	{
		var f = yPos;

		final data = effectData[playerState.player];
		getEffects(playerState);
		f += effects(EFFECT_TIPSY) * data.tipsy_offset_result[iCol];
		f += effects(EFFECT_TAN_TIPSY) * data.tan_tipsy_offset_result[iCol];

		f += effects(EFFECT_PARABOLA_Y) * (yPos / ARROW_SIZE) * (yPos / ARROW_SIZE);
		f += effects(EFFECT_JIMBLE) * data.fJimbleSin[iCol];

		arrowGetReverseShiftAndScale(playerState, iCol, fYReverseOffsetPixels);

		f -= fShiftOut;
		if (fScaleOut != 0)
			f /= fScaleOut;

		return f;
	}

	public function getXPos(playerState:PlayerState, iColNum:Int, fYOffset:Float)
	{
		var fPixelOffsetFromCenter = .0;

		final data = effectData[playerState.player];
		getEffects(playerState);

		if (effects(EFFECT_TORNADO) != 0)
		{
			fPixelOffsetFromCenter += calculateTornadoOffsetFromMagnitude(playerState, dim_x, iColNum, effects(EFFECT_TORNADO),
				effects(EFFECT_TORNADO_OFFSET), effects(EFFECT_TORNADO_PERIOD), playerState.noteFieldZoom, data, fYOffset, false);
		}

		if (effects(EFFECT_TAN_TORNADO) != 0)
		{
			fPixelOffsetFromCenter += calculateTornadoOffsetFromMagnitude(playerState, dim_x, iColNum, effects(EFFECT_TAN_TORNADO),
				effects(EFFECT_TAN_TORNADO_OFFSET), effects(EFFECT_TAN_TORNADO_PERIOD), playerState.noteFieldZoom, data, fYOffset, true);
		}

		if (effects(EFFECT_BUMPY_X) != 0)
		{
			fPixelOffsetFromCenter += effects(EFFECT_BUMPY_X) * 40 * FlxMath.fastSin(calculateBumpyAngle(fYOffset, effects(EFFECT_BUMPY_X_OFFSET),
				effects(EFFECT_BUMPY_X_PERIOD)));
		}

		if (effects(EFFECT_TAN_BUMPY_X) != 0)
		{
			fPixelOffsetFromCenter += effects(EFFECT_TAN_BUMPY_X) * 40 * selectTanType(calculateBumpyAngle(fYOffset, effects(EFFECT_TAN_BUMPY_X_OFFSET),
				effects(EFFECT_TAN_BUMPY_X_PERIOD)), curr_options.bCosecant);
		}

		if (effects(EFFECT_DRUNK) != 0)
		{
			fPixelOffsetFromCenter += effects(EFFECT_DRUNK) * (FlxMath.fastCos(calculateDrunkAngle(effects(EFFECT_DRUNK_SPEED), iColNum,
				effects(EFFECT_DRUNK_OFFSET), C.DrunkColumnFrequency, fYOffset, effects(EFFECT_DRUNK_PERIOD),
				C.DrunkOffsetFrequency)) * ARROW_SIZE * C.DrunkArrowMagnitude);
		}

		if (effects(EFFECT_TAN_DRUNK) != 0)
		{
			fPixelOffsetFromCenter += effects(EFFECT_TAN_DRUNK) * (selectTanType(calculateDrunkAngle(effects(EFFECT_TAN_DRUNK_SPEED), iColNum,
				effects(EFFECT_TAN_DRUNK_OFFSET), C.DrunkColumnFrequency, fYOffset, effects(EFFECT_TAN_DRUNK_PERIOD), C.DrunkOffsetFrequency),
				curr_options.bCosecant) * ARROW_SIZE * C.DrunkArrowMagnitude);
		}

		if (effects(EFFECT_FLIP) != 0)
		{
			final iFirstCol = 0;
			final iLastCol = playerState.keyCount - 1;
			final iNewCol = Std.int(FlxMath.remapToRange(iColNum, iFirstCol, iLastCol, iLastCol, iFirstCol));
			final fOldPixelOffset = playerState.xOffset[iColNum];
			final fNewPixelOffset = playerState.xOffset[iNewCol];
			final fDistance = fNewPixelOffset - fOldPixelOffset;
			fPixelOffsetFromCenter += fDistance * effects(EFFECT_FLIP);
		}

		if (effects(EFFECT_INVERT) != 0)
			fPixelOffsetFromCenter += data.fInvertDistance[iColNum] * effects(EFFECT_INVERT);

		if (effects(EFFECT_BEAT) != 0)
		{
			final fShift = data.fBeatFactor[dim_x] * FlxMath.fastSin(fYOffset / ((effects(EFFECT_BEAT_PERIOD) * C.BeatOffsetHeight) + C.BeatOffsetHeight)
				+ Math.PI / C.BeatPIHeight);
			fPixelOffsetFromCenter += effects(EFFECT_BEAT) * fShift;
		}

		if (effects(EFFECT_ZIGZAG) != 0)
		{
			final fResult = triangle((Math.PI * (1 / (effects(EFFECT_ZIGZAG_PERIOD) + 1)) * ((fYOffset +
				(100.0 * (effects(EFFECT_ZIGZAG_OFFSET)))) / ARROW_SIZE)));

			fPixelOffsetFromCenter += (effects(EFFECT_ZIGZAG) * ARROW_SIZE / 2) * fResult;
		}

		if (effects(EFFECT_SAWTOOTH) != 0)
		{
			fPixelOffsetFromCenter += (effects(EFFECT_SAWTOOTH) * ARROW_SIZE) * ((0.5 / (effects(EFFECT_SAWTOOTH_PERIOD) + 1) * fYOffset) / ARROW_SIZE
				- Math.floor((0.5 / (effects(EFFECT_SAWTOOTH_PERIOD) + 1) * fYOffset) / ARROW_SIZE));
		}

		if (effects(EFFECT_PARABOLA_X) != 0)
			fPixelOffsetFromCenter += effects(EFFECT_PARABOLA_X) * (fYOffset / ARROW_SIZE) * (fYOffset / ARROW_SIZE);

		if (effects(EFFECT_ATTENUATE_X) != 0)
		{
			final fXOffset = playerState.xOffset[iColNum];
			fPixelOffsetFromCenter += effects(EFFECT_ATTENUATE_X) * (fYOffset / ARROW_SIZE) * (fYOffset / ARROW_SIZE) * (fXOffset / ARROW_SIZE);
		}

		if (effects(EFFECT_DIGITAL) != 0)
		{
			fPixelOffsetFromCenter += (effects(EFFECT_DIGITAL) * ARROW_SIZE * 0.5) * Math.round((effects(EFFECT_DIGITAL_STEPS) +
				1) * FlxMath.fastSin(calculateDigitalAngle(fYOffset, effects(EFFECT_DIGITAL_OFFSET),
					effects(EFFECT_DIGITAL_PERIOD)))) / (effects(EFFECT_DIGITAL_STEPS)
				+ 1);
		}

		if (effects(EFFECT_TAN_DIGITAL) != 0)
		{
			fPixelOffsetFromCenter += (effects(EFFECT_TAN_DIGITAL) * ARROW_SIZE * 0.5) * Math.round((effects(EFFECT_TAN_DIGITAL_STEPS) +
				1) * selectTanType(calculateDigitalAngle(fYOffset, effects(EFFECT_TAN_DIGITAL_OFFSET), effects(EFFECT_TAN_DIGITAL_PERIOD)),
				curr_options.bCosecant)) / (effects(EFFECT_TAN_DIGITAL_STEPS) + 1);
		}

		if (effects(EFFECT_SQUARE) != 0)
		{
			final fResult = square((Math.PI * (fYOffset + (1.0 * (effects(EFFECT_SQUARE_OFFSET)))) / (ARROW_SIZE +
				(effects(EFFECT_SQUARE_PERIOD) * ARROW_SIZE))));

			fPixelOffsetFromCenter += (effects(EFFECT_SQUARE) * ARROW_SIZE * 0.5) * fResult;
		}

		if (effects(EFFECT_BOUNCE) != 0)
		{
			final fBounceAmt = Math.abs(FlxMath.fastSin(((fYOffset + (1.0 * (effects(EFFECT_BOUNCE_OFFSET)))) / (60 + (effects(EFFECT_BOUNCE_PERIOD) * 60)))));

			fPixelOffsetFromCenter += effects(EFFECT_BOUNCE) * ARROW_SIZE * 0.5 * fBounceAmt;
		}

		if (effects(EFFECT_XMODE) != 0)
		{
			if (playerState.player == 1) // plr 2
				fPixelOffsetFromCenter += effects(EFFECT_XMODE) * -(fYOffset);
			else
				fPixelOffsetFromCenter += effects(EFFECT_XMODE) * fYOffset;
		}

		if (effects(EFFECT_JIMBLE) != 0)
			fPixelOffsetFromCenter += effects(EFFECT_JIMBLE) * data.fJimbleTan[iColNum];

		fPixelOffsetFromCenter += (playerState.xOffset[iColNum] * playerState.noteFieldZoom);

		// if (effects(EFFECT_TINY) != 0) {
		//	var fTinyPercent = effects(EFFECT_TINY);
		//	fTinyPercent = Math.min(Math.pow(C.TinyPercentBase, fTinyPercent), C.TinyPercentGate);
		//	fPixelOffsetFromCenter *= fTinyPercent;
		// }

		return fPixelOffsetFromCenter;
	}

	public function getRotationX(playerState:PlayerState, fYOffset:Float, bIsHoldCap:Bool, iCol:Int)
	{
		getEffects(playerState);
		var fRotation = .0;
		if (effects(EFFECT_CONFUSION_X) != 0 || effects(EFFECT_CONFUSION_X_OFFSET) != 0)
			fRotation += receptorGetRotationX(playerState, iCol);
		if (effects(EFFECT_ROLL) != 0 && !bIsHoldCap)
			fRotation += effects(EFFECT_ROLL) * fYOffset / 2;
		return fRotation;
	}

	public function getRotationY(playerState:PlayerState, fYOffset:Float, bIsHoldCap:Bool, iCol:Int)
	{
		getEffects(playerState);
		var fRotation = .0;
		if (effects(EFFECT_CONFUSION_Y) != 0 || effects(EFFECT_CONFUSION_Y_OFFSET) != 0)
			fRotation += receptorGetRotationY(playerState, iCol);
		if (playerState.fEffects(EFFECT_TWIRL) != 0)
			fRotation += playerState.fEffects(EFFECT_TWIRL) * fYOffset / 2;
		return fRotation;
	}

	// this is just angle so it is used
	public function getRotationZ(playerState:PlayerState, fYOffset:Float, bIsHoldCap:Bool, iCol:Int)
	{
		getEffects(playerState);
		var fRotation = .0;
		if (effects(EFFECT_CONFUSION) != 0 || effects(EFFECT_CONFUSION_OFFSET) != 0)
			fRotation += receptorGetRotationZ(playerState, iCol);
		if (playerState.fEffects(EFFECT_DIZZY) != 0)
			fRotation += playerState.fEffects(EFFECT_DIZZY) * fYOffset / 2;
		return fRotation;
	}

	function receptorGetRotationZ(playerState:PlayerState, iCol:Int)
	{
		getEffects(playerState);
		var fRotation = .0;

		if (effects(EFFECT_CONFUSION_OFFSET) != 0)
			fRotation += effects(EFFECT_CONFUSION_OFFSET) * FlxAngle.TO_DEG;

		if (effects(EFFECT_CONFUSION) != 0)
		{
			var fConfRotation = conductor.currentBeatTime;
			fConfRotation *= effects(EFFECT_CONFUSION);
			fConfRotation = mod(fConfRotation, 2 * Math.PI);
			fConfRotation *= -FlxAngle.TO_DEG;
			fRotation += fConfRotation;
		}

		return fRotation;
	}

	function receptorGetRotationX(playerState:PlayerState, iCol:Int)
	{
		getEffects(playerState);
		var fRotation = .0;

		if (effects(EFFECT_CONFUSION_X_OFFSET) != 0)
			fRotation += effects(EFFECT_CONFUSION_X_OFFSET) * FlxAngle.TO_DEG;

		if (effects(EFFECT_CONFUSION_X) != 0)
		{
			var fConfRotation = conductor.currentBeatTime;
			fConfRotation *= effects(EFFECT_CONFUSION_X);
			fConfRotation = mod(fConfRotation, 2 * Math.PI);
			fConfRotation *= -FlxAngle.TO_DEG;
			fRotation += fConfRotation;
		}

		return fRotation;
	}

	function receptorGetRotationY(playerState:PlayerState, iCol:Int)
	{
		getEffects(playerState);
		var fRotation = .0;

		if (effects(EFFECT_CONFUSION_Y_OFFSET) != 0)
			fRotation += effects(EFFECT_CONFUSION_Y_OFFSET) * FlxAngle.TO_DEG;

		if (effects(EFFECT_CONFUSION_Y) != 0)
		{
			var fConfRotation = conductor.currentBeatTime;
			fConfRotation *= effects(EFFECT_CONFUSION_Y);
			fConfRotation = mod(fConfRotation, 2 * Math.PI);
			fConfRotation *= -FlxAngle.TO_DEG;
			fRotation += fConfRotation;
		}

		return fRotation;
	}

	public function getCenterLine()
	{
		final fMiniPercent = curr_options.fEffects(EFFECT_MINI);
		final fZoom = 1 - fMiniPercent * .5;
		return 160 / fZoom;
	}

	function getHiddenSudden(hidden:Float)
	{
		return hidden * hidden;
	}

	function getHiddenEndLine(hidden:Float, hiddenOffset:Float)
	{
		return getCenterLine() + position.fadeDistY * FlxMath.remapToRange(getHiddenSudden(hidden), 0, 1, -1, -1.25) + getCenterLine() * hiddenOffset;
	}

	function getHiddenStartLine(hidden:Float, hiddenOffset:Float)
	{
		return getCenterLine() + position.fadeDistY * FlxMath.remapToRange(getHiddenSudden(hidden), 0, 1, 0, -.25) + getCenterLine() * hiddenOffset;
	}

	function getSuddenEndLine(sudden:Float, suddenOffset:Float)
	{
		return getCenterLine() + position.fadeDistY * FlxMath.remapToRange(getHiddenSudden(sudden), 0, 1, 0, .25) + getCenterLine() * suddenOffset;
	}

	function getSuddenStartLine(sudden:Float, suddenOffset:Float)
	{
		return getCenterLine() + position.fadeDistY * FlxMath.remapToRange(getHiddenSudden(sudden), 0, 1, 1, 1.25) + getCenterLine() * suddenOffset;
	}

	function arrowGetPercentVisible(playerState:PlayerState, hidden:Float, hiddenOffset:Float, sudden:Float, suddenOffset:Float, stealth:Float, blink:Float,
			randomvanish:Float, iCol:Int, fYOffset:Float, fYReverseOffsetPixels:Float):Float
	{
		var fYPos = getYPos(playerState, iCol, fYOffset, fYReverseOffsetPixels, false);

		final fDistFromCenterLine = fYPos - getCenterLine();

		if (fYPos < 0)
			return 1;

		var fVisibleAdjust = .0;

		if (hidden != 0)
		{
			final fHiddenVisibleAdjust = FlxMath.bound(FlxMath.remapToRange(fYPos, getHiddenStartLine(hidden, hiddenOffset),
				getHiddenEndLine(hidden, hiddenOffset), 0, -1), -1, 0);
			fVisibleAdjust += hidden * fHiddenVisibleAdjust;
		}
		if (sudden != 0)
		{
			final fSuddenVisibleAdjust = FlxMath.bound(FlxMath.remapToRange(fYPos, getSuddenStartLine(sudden, suddenOffset),
				getSuddenEndLine(sudden, suddenOffset), -1, 0), -1, 0);
			fVisibleAdjust += sudden * fSuddenVisibleAdjust;
		}

		if (stealth != 0)
			fVisibleAdjust -= stealth;
		if (blink != 0)
		{
			var f = FlxMath.fastSin(getTime() * 10);
			f = quantize(f, 1 / 3);
			fVisibleAdjust += FlxMath.remapToRange(f, 0, 1, -1, 0);
		}
		if (randomvanish != 0)
		{
			final fRealFadeDist = 80;
			fVisibleAdjust += FlxMath.remapToRange(Math.abs(fDistFromCenterLine), fRealFadeDist, 2 * fRealFadeDist, -1, 0) * randomvanish;
		}

		return FlxMath.bound(1 + fVisibleAdjust, 0, 1);
	}

	public function getAlpha(playerState:PlayerState, iCol:Int, fYOffset:Float, fPercentFadeToFail:Float, fYReverseOffsetPixels:Float):Float
	{
		// final fYPosWithoutReverse = getYPos(playerState, iCol, fYOffset, fYReverseOffsetPixels, false);

		getAppearances(playerState);
		var fPercentVisible = arrowGetPercentVisible(playerState, appearances(APPEARANCE_HIDDEN), appearances(APPEARANCE_HIDDEN_OFFSET),
			appearances(APPEARANCE_SUDDEN), appearances(APPEARANCE_SUDDEN_OFFSET), appearances(APPEARANCE_STEALTH), appearances(APPEARANCE_BLINK),
			appearances(APPEARANCE_RANDOMVANISH), iCol, fYOffset, fYReverseOffsetPixels);

		if (fPercentFadeToFail != -1)
			fPercentVisible = 1 - fPercentFadeToFail;

		final fDrawDistanceBeforeTargetsPixels = C.DrawDistanceBeforeTargetsPixels;
		final fFadeInPercentOfDrawFar = C.FadeBeforeTargetsPercent;

		// no idea
		// final fFullAlphaY = fDrawDistanceBeforeTargetsPixels * (1 - fFadeInPercentOfDrawFar);
		// if (fYPosWithoutReverse > fFullAlphaY) {
		//	final f = FlxMath.remapToRange(fYPosWithoutReverse, fFullAlphaY, fDrawDistanceBeforeTargetsPixels, 1.0, 0.0);
		//	return f;
		// }

		return FlxMath.bound(fPercentVisible * 2, 0, 1); // only full diversion from openitg/sm5 code cause alpha kept sfdsf
	}

	public function getGlow(playerState:PlayerState, iCol:Int, fYOffset:Float, fPercentFadeToFail:Float, fYReverseOffsetPixels:Float):Float
	{
		getAppearances(playerState);
		var fPercentVisible = arrowGetPercentVisible(playerState, appearances(APPEARANCE_HIDDEN), appearances(APPEARANCE_HIDDEN_OFFSET),
			appearances(APPEARANCE_SUDDEN), appearances(APPEARANCE_SUDDEN_OFFSET), appearances(APPEARANCE_STEALTH), appearances(APPEARANCE_BLINK),
			appearances(APPEARANCE_RANDOMVANISH), iCol, fYOffset, fYReverseOffsetPixels);

		if (fPercentFadeToFail != -1)
			fPercentVisible = 1 - fPercentFadeToFail;

		final fDistFromHalf = Math.max(0, fPercentVisible - .5); // only OTHER diversion to keep >= .5 full white
		return FlxMath.remapToRange(fDistFromHalf, 0, .5, 1.3, 0);
	}

	public function getRedVisible(playerState:PlayerState, iCol:Int, fYOffset:Float, fPercentFadeToFail:Float, fYReverseOffsetPixels:Float):Float
	{
		getAppearances(playerState);
		return colorVisible(playerState, appearances(APPEARANCE_HIDDEN_RED), appearances(APPEARANCE_HIDDEN_RED_OFFSET), appearances(APPEARANCE_SUDDEN_RED),
			appearances(APPEARANCE_SUDDEN_RED_OFFSET), appearances(APPEARANCE_STEALTH_RED), appearances(APPEARANCE_BLINK_RED),
			appearances(APPEARANCE_RANDOMVANISH_RED), iCol, fYOffset, fPercentFadeToFail, fYReverseOffsetPixels);
	}

	public function getGreenVisible(playerState:PlayerState, iCol:Int, fYOffset:Float, fPercentFadeToFail:Float, fYReverseOffsetPixels:Float):Float
	{
		getAppearances(playerState);
		return colorVisible(playerState, appearances(APPEARANCE_HIDDEN_GREEN), appearances(APPEARANCE_HIDDEN_GREEN_OFFSET),
			appearances(APPEARANCE_SUDDEN_GREEN), appearances(APPEARANCE_SUDDEN_GREEN_OFFSET), appearances(APPEARANCE_STEALTH_GREEN),
			appearances(APPEARANCE_BLINK_GREEN), appearances(APPEARANCE_RANDOMVANISH_GREEN), iCol, fYOffset, fPercentFadeToFail, fYReverseOffsetPixels);
	}

	public function getBlueVisible(playerState:PlayerState, iCol:Int, fYOffset:Float, fPercentFadeToFail:Float, fYReverseOffsetPixels:Float):Float
	{
		getAppearances(playerState);
		return colorVisible(playerState, appearances(APPEARANCE_HIDDEN_BLUE), appearances(APPEARANCE_HIDDEN_BLUE_OFFSET), appearances(APPEARANCE_SUDDEN_BLUE),
			appearances(APPEARANCE_SUDDEN_BLUE_OFFSET), appearances(APPEARANCE_STEALTH_BLUE), appearances(APPEARANCE_BLINK_BLUE),
			appearances(APPEARANCE_RANDOMVANISH_BLUE), iCol, fYOffset, fPercentFadeToFail, fYReverseOffsetPixels);
	}

	inline function colorVisible(playerState:PlayerState, hidden:Float, hiddenOffset:Float, sudden:Float, suddenOffset:Float, stealth:Float, blink:Float,
			randomvanish:Float, iCol:Int, fYOffset:Float, fPercentFadeToFail:Float, fYReverseOffsetPixels:Float):Float
	{
		var fPercentVisible = arrowGetPercentVisible(playerState, hidden, hiddenOffset, sudden, suddenOffset, stealth, blink, randomvanish, iCol, fYOffset,
			fYReverseOffsetPixels);

		if (fPercentFadeToFail != -1)
			fPercentVisible = 1 - fPercentFadeToFail;

		return fPercentVisible;
	}

	public function getBrightness(playerState:PlayerState, fNoteBeat:Float):Float
	{
		final fSongBeat = conductor.currentBeatTime;
		final fBeatsUntilStep = fNoteBeat - fSongBeat;

		final fBrightness = FlxMath.remapToRange(fBeatsUntilStep, 0, -1, 1, 0);
		return FlxMath.bound(fBrightness, 0, 1);
	}

	public function getZPos(playerState:PlayerState, iCol:Int, fYOffset:Float):Float
	{
		var fZPos = .0;

		final data = effectData[playerState.player];
		getEffects(playerState);

		if (effects(EFFECT_TORNADO_Z) != 0)
		{
			fZPos += calculateTornadoOffsetFromMagnitude(playerState, dim_z, iCol, effects(EFFECT_TORNADO_Z), effects(EFFECT_TORNADO_Z_OFFSET),
				effects(EFFECT_TORNADO_Z_PERIOD), playerState.noteFieldZoom, data, fYOffset, false);
		}

		if (effects(EFFECT_TAN_TORNADO_Z) != 0)
		{
			fZPos += calculateTornadoOffsetFromMagnitude(playerState, dim_z, iCol, effects(EFFECT_TAN_TORNADO_Z), effects(EFFECT_TAN_TORNADO_Z_OFFSET),
				effects(EFFECT_TAN_TORNADO_Z_PERIOD), playerState.noteFieldZoom, data, fYOffset, true);
		}

		if (effects(EFFECT_BUMPY) != 0)
		{
			fZPos += effects(EFFECT_BUMPY) * 40 * FlxMath.fastSin(calculateBumpyAngle(fYOffset, effects(EFFECT_BUMPY_OFFSET), effects(EFFECT_BUMPY_PERIOD)));
		}

		if (effects(EFFECT_TAN_BUMPY) != 0)
		{
			fZPos += effects(EFFECT_TAN_BUMPY) * 40 * selectTanType(calculateBumpyAngle(fYOffset, effects(EFFECT_TAN_BUMPY_OFFSET),
				effects(EFFECT_TAN_BUMPY_PERIOD)), curr_options.bCosecant);
		}

		if (effects(EFFECT_ZIGZAG_Z) != 0)
		{
			final fResult = triangle((Math.PI * (1 / (effects(EFFECT_ZIGZAG_Z_PERIOD) + 1)) * ((fYOffset +
				(100.0 * (effects(EFFECT_ZIGZAG_Z_OFFSET)))) / ARROW_SIZE)));

			fZPos += (effects(EFFECT_ZIGZAG_Z) * ARROW_SIZE / 2) * fResult;
		}

		if (effects(EFFECT_SAWTOOTH_Z) != 0)
		{
			fZPos += (effects(EFFECT_SAWTOOTH_Z) * ARROW_SIZE) * ((0.5 / (effects(EFFECT_SAWTOOTH_Z_PERIOD) + 1) * fYOffset) / ARROW_SIZE
				- Math.floor((0.5 / (effects(EFFECT_SAWTOOTH_Z_PERIOD) + 1) * fYOffset) / ARROW_SIZE));
		}

		if (effects(EFFECT_PARABOLA_Z) != 0)
			fZPos += effects(EFFECT_PARABOLA_Z) * (fYOffset / ARROW_SIZE) * (fYOffset / ARROW_SIZE);

		if (effects(EFFECT_ATTENUATE_Z) != 0)
		{
			final fXOffset = playerState.xOffset[iCol];
			fZPos += effects(EFFECT_ATTENUATE_Z) * (fYOffset / ARROW_SIZE) * (fYOffset / ARROW_SIZE) * (fXOffset / ARROW_SIZE);
		}

		if (effects(EFFECT_DRUNK_Z) != 0)
		{
			fZPos += effects(EFFECT_DRUNK_Z) * (FlxMath.fastCos(calculateDrunkAngle(effects(EFFECT_DRUNK_Z_SPEED), iCol, effects(EFFECT_DRUNK_Z_OFFSET),
				C.DrunkZColumnFrequency, fYOffset, effects(EFFECT_DRUNK_Z_PERIOD), C.DrunkZOffsetFrequency)) * ARROW_SIZE * C.DrunkZArrowMagnitude);
		}

		if (effects(EFFECT_TAN_DRUNK_Z) != 0)
		{
			fZPos += effects(EFFECT_TAN_DRUNK_Z) * (selectTanType(calculateDrunkAngle(effects(EFFECT_TAN_DRUNK_Z_SPEED), iCol,
				effects(EFFECT_TAN_DRUNK_Z_OFFSET), C.DrunkZColumnFrequency, fYOffset, effects(EFFECT_TAN_DRUNK_Z_PERIOD), C.DrunkZOffsetFrequency),
				curr_options.bCosecant) * ARROW_SIZE * C.DrunkZArrowMagnitude);
		}

		if (effects(EFFECT_BEAT_Z) != 0)
		{
			final fShift = data.fBeatFactor[dim_z] * FlxMath.fastSin(fYOffset / ((effects(EFFECT_BEAT_Z_PERIOD) * C.BeatZOffsetHeight) + C.BeatZOffsetHeight)
				+ Math.PI / C.BeatZPIHeight);
			return effects(EFFECT_BEAT_Z) * fShift;
		}

		if (effects(EFFECT_DIGITAL_Z) != 0)
		{
			fZPos += (effects(EFFECT_DIGITAL_Z) * ARROW_SIZE * 0.5) * Math.round((effects(EFFECT_DIGITAL_Z_STEPS) +
				1) * FlxMath.fastSin(calculateDigitalAngle(fYOffset, effects(EFFECT_DIGITAL_Z_OFFSET),
					effects(EFFECT_DIGITAL_Z_PERIOD)))) / (effects(EFFECT_DIGITAL_Z_STEPS)
				+ 1);
		}

		if (effects(EFFECT_TAN_DIGITAL_Z) != 0)
		{
			fZPos += (effects(EFFECT_TAN_DIGITAL_Z) * ARROW_SIZE * 0.5) * Math.round((effects(EFFECT_TAN_DIGITAL_Z_STEPS) +
				1) * selectTanType(calculateDigitalAngle(fYOffset, effects(EFFECT_TAN_DIGITAL_Z_OFFSET), effects(EFFECT_TAN_DIGITAL_Z_PERIOD)),
				curr_options.bCosecant)) / (effects(EFFECT_TAN_DIGITAL_Z_STEPS) + 1);
		}

		if (effects(EFFECT_SQUARE_Z) != 0)
		{
			final fResult = square((Math.PI * (fYOffset + (1.0 * (effects(EFFECT_SQUARE_Z_OFFSET)))) / (ARROW_SIZE
				+ (effects(EFFECT_SQUARE_Z_PERIOD) * ARROW_SIZE))));

			fZPos += (effects(EFFECT_SQUARE_Z) * ARROW_SIZE * 0.5) * fResult;
		}

		if (effects(EFFECT_BOUNCE_Z) != 0)
		{
			final fBounceAmt = Math.abs(FlxMath.fastSin(((fYOffset + (1.0 * (effects(EFFECT_BOUNCE_Z_OFFSET)))) / (60 +
				(effects(EFFECT_BOUNCE_Z_PERIOD) * 60)))));

			fZPos += effects(EFFECT_BOUNCE_Z) * ARROW_SIZE * 0.5 * fBounceAmt;
		}

		if (effects(EFFECT_JIMBLE) != 0)
			fZPos += effects(EFFECT_JIMBLE) * data.fJimbleCos[iCol] * (.25 * (1 + effects(EFFECT_JIMBLE_Z)));

		return fZPos;
	}

	public function needZBuffer(playerState:PlayerState)
	{
		getEffects(playerState);

		// We also need to use the Z buffer if twirl is in play, because of
		// hold modulation. -vyhd (OpenITG r623)
		if (effects(EFFECT_BUMPY) != 0 || effects(EFFECT_TWIRL) != 0)
		{
			return true;
		}
		if (effects(EFFECT_BEAT_Z) != 0 || effects(EFFECT_DIGITAL_Z) != 0)
		{
			return true;
		}
		if (effects(EFFECT_ZIGZAG_Z) != 0 || effects(EFFECT_SAWTOOTH_Z) != 0)
		{
			return true;
		}
		if (effects(EFFECT_PARABOLA_Z) != 0 || effects(EFFECT_SQUARE_Z) != 0)
		{
			return true;
		}
		if (curr_options.bZBuffer || effects(EFFECT_ATTENUATE_Z) != 0)
		{
			return true;
		}
		if (effects(EFFECT_BOUNCE_Z) != 0)
		{
			return true;
		}
		return false;
	}

	static final wavyEffects:Array<Effect> = [
		// causes y offset x offsets (lol)
		EFFECT_TORNADO,
		EFFECT_TAN_TORNADO, //
		EFFECT_BUMPY_X,
		EFFECT_TAN_BUMPY_X, //
		EFFECT_DRUNK,
		EFFECT_TAN_DRUNK, //
		EFFECT_BEAT,
		EFFECT_ZIGZAG,
		EFFECT_SAWTOOTH,
		EFFECT_PARABOLA_X,
		EFFECT_ATTENUATE_X,
		EFFECT_DIGITAL,
		EFFECT_TAN_DIGITAL,
		EFFECT_SQUARE,
		EFFECT_BOUNCE,
		EFFECT_XMODE,
		// causes y offset z offsets (not as funny the second time)
		EFFECT_TORNADO_Z,
		EFFECT_TAN_TORNADO_Z,
		EFFECT_BUMPY,
		EFFECT_TAN_BUMPY,
		EFFECT_ZIGZAG_Z,
		EFFECT_SAWTOOTH_Z,
		EFFECT_PARABOLA_Z,
		EFFECT_ATTENUATE_Z,
		EFFECT_DRUNK_Z,
		EFFECT_TAN_DRUNK_Z,
		EFFECT_BEAT_Z,
		EFFECT_DIGITAL_Z,
		EFFECT_TAN_DIGITAL_Z,
		EFFECT_SQUARE_Z,
		EFFECT_BOUNCE_Z,
		// causes zoom stuff who cares
		EFFECT_PULSE_INNER,
		EFFECT_PULSE_OUTER,
		EFFECT_SHRINK_TO_MULT,
		EFFECT_SHRINK_TO_LINEAR,
		// causes y offset rotations
		EFFECT_TWIRL,
		EFFECT_CONFUSION_Y,
		EFFECT_CONFUSION_Y_OFFSET,
	];

	// since most appearance mods need wavy holds
	static final wavyAppearances:Array<Appearance> = [
		for (appearance in 0...NUM_APPEARANCES)
		{
			if (![
				APPEARANCE_STEALTH,
				APPEARANCE_STEALTH_RED,
				APPEARANCE_STEALTH_GREEN,
				APPEARANCE_STEALTH_BLUE,
				APPEARANCE_BLINK,
				APPEARANCE_BLINK_RED,
				APPEARANCE_BLINK_GREEN,
				APPEARANCE_BLINK_BLUE,
			].contains(appearance)) appearance;
		}
	];

	public function needWavyHolds(playerState:PlayerState)
	{
		getEffects(playerState);
		getAppearances(playerState);

		for (effect in wavyEffects)
		{
			if (Math.abs(effects(effect)) > FlxMath.EPSILON)
				return true;
		}

		for (appearance in wavyAppearances)
		{
			if (Math.abs(appearances(appearance)) > FlxMath.EPSILON)
				return true;
		}

		return false;
	}

	public function getZoom(playerState:PlayerState, fYOffset:Float, iCol:Int)
	{
		var fZoom = 1.0;

		fZoom = getZoomVariable(playerState, fYOffset, iCol, fZoom);
		var fTinyPercent = playerState.fEffects(EFFECT_TINY);
		if (fTinyPercent != 0)
		{
			fZoom *= getTinyZoom(fTinyPercent);
		}
		return fZoom;
	}

	// brand new friends
	public function getZoomX(playerState:PlayerState, fYOffset:Float, iCol:Int)
	{
		var fZoom = 1.0;

		var fTinyPercent = playerState.fEffects(EFFECT_TINY_X);
		if (fTinyPercent != 0)
		{
			fZoom *= getTinyZoom(fTinyPercent);
		}
		return fZoom;
	}

	public function getZoomY(playerState:PlayerState, fYOffset:Float, iCol:Int)
	{
		var fZoom = 1.0;

		var fTinyPercent = playerState.fEffects(EFFECT_TINY_Y);
		if (fTinyPercent != 0)
		{
			fZoom *= getTinyZoom(fTinyPercent);
		}
		return fZoom;
	}

	public function getZoomZ(playerState:PlayerState, fYOffset:Float, iCol:Int)
	{
		var fZoom = 1.0;

		var fTinyPercent = playerState.fEffects(EFFECT_TINY_Z);
		if (fTinyPercent != 0)
		{
			fZoom *= getTinyZoom(fTinyPercent);
		}
		return fZoom;
	}

	inline function getTinyZoom(tiny:Float):Float
	{
		if (tiny != 0)
			return FlxMath.remapToRange(tiny, 0, 1, 1, .5);
		return 1.0;
	}

	public function getZoomVariable(playerState:PlayerState, fYOffset:Float, iCol:Int, fCurZoom:Float)
	{
		getEffects(playerState);
		var fZoom = fCurZoom;
		if (effects(EFFECT_PULSE_INNER) != 0 || effects(EFFECT_PULSE_OUTER) != 0)
		{
			final sine = FlxMath.fastSin(((fYOffset + (100.0 * effects(EFFECT_PULSE_OFFSET))) / (0.4 * (ARROW_SIZE
				+ (effects(EFFECT_PULSE_PERIOD) * ARROW_SIZE)))));

			fZoom *= (sine * (effects(EFFECT_PULSE_OUTER) * 0.5)) + getPulseInner(playerState);
		}
		if (effects(EFFECT_SHRINK_TO_MULT) != 0 && fYOffset >= 0)
			fZoom *= 1 / (1 + (fYOffset * (effects(EFFECT_SHRINK_TO_MULT) / 100.0)));

		if (effects(EFFECT_SHRINK_TO_LINEAR) != 0 && fYOffset >= 0)
			fZoom += fYOffset * (0.5 * effects(EFFECT_SHRINK_TO_LINEAR) / ARROW_SIZE);
		return fZoom;
	}

	public function getSkewX(playerState:PlayerState, fYOffset:Float, iCol:Int)
	{
		var skew = .0;

		getEffects(playerState);
		final data = effectData[playerState.player];
		if (effects(EFFECT_JIMBLE) != 0)
			skew += effects(EFFECT_JIMBLE) * data.fJimbleSin[iCol] * 11.25;

		return skew;
	}

	public function getSkewY(playerState:PlayerState, fYOffset:Float, iCol:Int)
	{
		var skew = .0;

		getEffects(playerState);
		final data = effectData[playerState.player];
		if (effects(EFFECT_JIMBLE) != 0)
			skew += effects(EFFECT_JIMBLE) * data.fJimbleCos[iCol];

		return skew;
	}

	function getPulseInner(playerState:PlayerState):Float
	{
		var fPulseInner = 1.0;
		getEffects(playerState);
		if (effects(EFFECT_PULSE_INNER) != 0 || effects(EFFECT_PULSE_OUTER) != 0)
		{
			fPulseInner = ((effects(EFFECT_PULSE_INNER) * 0.5) + 1);
			if (fPulseInner == 0)
				fPulseInner = 0.01;
		}
		return fPulseInner;
	}

	function arrowGetReverseShiftAndScale(playerState:PlayerState, iCol:Int, fYReverseOffsetPixels:Float)
	{
		final fMiniPercent = playerState.fEffects(EFFECT_MINI);
		var fZoom = 1 - fMiniPercent * .5;

		if (Math.abs(fZoom) < .01)
			fZoom = .01;

		final fPercentReverse = playerState.getReversePercentForColumn(iCol);
		fShiftOut = FlxMath.remapToRange(fPercentReverse, 0, 1, -fYReverseOffsetPixels / fZoom / 2, fYReverseOffsetPixels / fZoom / 2);
		final fPercentScrollCentered = playerState.fScrolls(SCROLL_CENTERED);
		fShiftOut = FlxMath.remapToRange(fPercentScrollCentered, 0, 1, fShiftOut, .5);

		fScaleOut = FlxMath.remapToRange(fPercentReverse, 0, 1, 1, -1);
	}

	function calculateTornadoOffsetFromMagnitude(playerState:PlayerState, dimension:Int, col_id:Int, magnitude:Float, effect_offset:Float, period:Float,
			field_zoom:Float, data:PerPlayerData, y_offset:Float, is_tan:Bool):Float
	{
		final real_pixel_offset = playerState.xOffset[col_id];
		final position_between = FlxMath.remapToRange(real_pixel_offset, data.minTornado[dimension][col_id] * field_zoom,
			data.maxTornado[dimension][col_id] * field_zoom, C.TornadoPositionScaleToLow[dimension], C.TornadoPositionScaleToHigh[dimension]);
		var rads = Math.acos(position_between);
		final frequency = C.TornadoOffsetFrequency[dimension];
		rads += (y_offset + effect_offset) * ((period * frequency) + frequency) / FlxG.height;
		final processed_rads = is_tan ? selectTanType(rads, curr_options.bCosecant) : FlxMath.fastCos(rads);

		final adjusted_pixel_offset = FlxMath.remapToRange(processed_rads, C.TornadoOffsetScaleFromLow[dimension], C.TornadoOffsetScaleFromHigh[dimension],
			data.minTornado[dimension][col_id] * field_zoom, data.maxTornado[dimension][col_id] * field_zoom);

		return (adjusted_pixel_offset - real_pixel_offset) * magnitude;
	}

	function calculateDrunkAngle(speed:Float, col:Int, offset:Float, col_frequency:Float, y_offset:Float, period:Float, offset_frequency:Float):Float
	{
		final time = getTime();
		return time * (1 + speed)
			+ col * ((offset * col_frequency) + col_frequency)
			+ y_offset * ((period * offset_frequency) + offset_frequency) / FlxG.height;
	}

	function calculateBumpyAngle(y_offset:Float, offset:Float, period:Float):Float
	{
		return (y_offset + (100.0 * offset)) / ((period * 16.0) + 16.0);
	}

	function calculateDigitalAngle(y_offset:Float, offset:Float, period:Float):Float
	{
		return Math.PI * (y_offset + (1.0 * offset)) / (ARROW_SIZE + (period * ARROW_SIZE));
	}

	function updateBeat(dimension:Int, data:PerPlayerData, position:DaveConductor, beat_offset:Float, beat_mult:Float)
	{
		final fAccelTime = .2, fTotalTime = .5;
		var fBeat = ((position.currentBeatTime + fAccelTime + beat_offset) * (beat_mult + 1));

		final bEvenBeat = (Std.int(fBeat) % 2) != 0;

		data.fBeatFactor[dimension] = 0;
		if (fBeat < 0)
			return;
		fBeat -= trunc(fBeat);
		fBeat += 1;
		fBeat -= trunc(fBeat);

		if (fBeat >= fTotalTime)
			return;

		if (fBeat < fAccelTime)
		{
			data.fBeatFactor[dimension] = FlxMath.remapToRange(fBeat, 0.0, fAccelTime, 0.0, 1.0);
			data.fBeatFactor[dimension] *= data.fBeatFactor[dimension];
		}
		else
		{
			data.fBeatFactor[dimension] = FlxMath.remapToRange(fBeat, fAccelTime, fTotalTime, 1.0, 0.0);
			data.fBeatFactor[dimension] = 1 - (1 - data.fBeatFactor[dimension]) * (1 - data.fBeatFactor[dimension]);
		}

		if (bEvenBeat)
			data.fBeatFactor[dimension] *= -1;
		data.fBeatFactor[dimension] *= 20;
	}

	function updateTipsy(tipsy_result:Vector<Float>, tipsy_offset_result:Vector<Float>, offset:Float, speed:Float, is_tan:Bool, keyCount:Int)
	{
		final time = getTime();
		final time_times_timer = time * ((speed * C.TipsyTimerFrequency) + C.TipsyTimerFrequency);
		final arrow_times_mag = ARROW_SIZE * C.TipsyArrowMagnitude;
		final time_times_offset_timer = time * C.TipsyOffsetTimerFrequency;
		final arrow_times_offset_mag = ARROW_SIZE * C.TipsyOffsetArrowMagnitude;
		for (col in 0...keyCount)
		{
			if (is_tan)
			{
				tipsy_result[col] = selectTanType(time_times_timer + (col * ((offset * C.TipsyColumnFrequency) + C.TipsyColumnFrequency)),
					curr_options.bCosecant) * arrow_times_mag;
				tipsy_offset_result[col] = selectTanType(time_times_offset_timer + (col * C.TipsyOffsetColumnFrequency),
					curr_options.bCosecant) * arrow_times_offset_mag;
			}
			else
			{
				tipsy_result[col] = FlxMath.fastCos(time_times_timer + (col * ((offset * C.TipsyColumnFrequency) + C.TipsyColumnFrequency))) * arrow_times_mag;
				tipsy_offset_result[col] = FlxMath.fastCos(time_times_offset_timer + (col * C.TipsyOffsetColumnFrequency)) * arrow_times_offset_mag;
			}
		}
	}

	function selectTanType(angle:Float, is_cosec:Bool)
	{
		if (is_cosec)
			return fastCsc(angle);
		else
			return fastTan(angle);
	}

	// rage stuff or other stuff
	static inline function trunc(inp:Float):Int
		return Math.floor(Math.abs(inp)) * FlxMath.signOf(inp);

	static inline function quantize(f:Float, fRoundInterval:Float):Int
		return Std.int(((f + fRoundInterval / 2) / fRoundInterval) * fRoundInterval);

	static inline function fastCsc(x:Float)
		return 1 / FlxMath.fastSin(x);

	static inline function fastTan(x:Float)
		return MathUtil.fastTan(x);

	/**
	 * Performs a modulo operation to calculate the remainder of `a` divided by `b`.
	 * 
	 * The definition of "remainder" varies by implementation;
	 * this one is similar to GLSL or Python in that it uses Euclidean division, which always returns positive,
	 * while Haxe's `%` operator uses signed truncated division.
	 * 
	 * For example, `-5 % 3` returns `-2` while `mod(-5, 3)` returns `1`.
	 * 
	 * @param a The dividend.
	 * @param b The divisor.
	 * @return `a mod b`.
	 */
	public static inline function mod(a:Float, b:Float):Float
	{
		b = Math.abs(b);
		return a - b * Math.floor(a / b);
	}

	static inline function square(angle:Float)
	{
		var fAngle = mod(angle, Math.PI * 2);
		if (fAngle < 0.01)
			fAngle += Math.PI * 2;
		return fAngle >= Math.PI ? -1.0 : 1.0;
	}

	static inline function triangle(angle:Float)
	{
		var fAngle = mod(angle, Math.PI * 2);
		if (fAngle < 0.0)
			fAngle += Math.PI * 2.0;
		final result = fAngle * (1 / Math.PI);
		if (result < .5)
			return result * 2.0;
		else if (result < 1.5)
			return 1.0 - ((result - .5) * 2.0);
		else
			return -4.0 + (result * 2.0);
	}

	public function setValue(mod:String, value:Float, player = -1)
	{
		if (player == -1)
		{
			for (i in 0...players)
				setValue(mod, value, i);
		}
		else
		{
			playerStates[player].mods.get(mod).value = value;
		}
	}

	inline function get_conductor():DaveConductor
	{
		return DaveConductor.instance;
	}
}

#if !modchart_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
final class PlayerState
{
	final MOD_LENGTH:Int;

	@:pure
	@:inline
	@:noDebug
	public inline function fAccels(i:Int):Float
	{
		return _accels[i * MOD_LENGTH] + _accels[i * MOD_LENGTH + curr_dir];
	}

	@:pure
	@:inline
	@:noDebug
	public inline function fEffects(i:Int):Float
	{
		return _effects[i * MOD_LENGTH] + _effects[i * MOD_LENGTH + curr_dir];
	}

	@:pure
	@:inline
	@:noDebug
	public inline function fAppearances(i:Int):Float
	{
		return _appearances[i * MOD_LENGTH] + _appearances[i * MOD_LENGTH + curr_dir];
	}

	@:pure
	@:inline
	@:noDebug
	public inline function fScrolls(i:Int):Float
	{
		return _scrolls[i * MOD_LENGTH] + _scrolls[i * MOD_LENGTH + curr_dir];
	}

	public final bTurns = new Vector<Bool>(NUM_TURNS, true);
	public final bTransforms = new Vector<Bool>(NUM_TURNS, true);

	public var timer:Float;

	// public var options = new PlayerOptions();
	public var fDark = .0;
	public var fBlind = .0;
	public var fCover = .0;
	public var fSpiralHolds = 0.;
	public var fStraightHolds = 0.;
	public var fGayHolds = 0.;

	public var fScrollSpeed(get, never):Float;

	public var xmod = 1.0;

	public var fTimeSpacing = 1.0;

	public var fRandomSpeed = .0;

	public var fGrain = Options.quality == 0 ? 64. : 16.;

	public var fArrowPath = .0;
	public var fArrowPathWidth = .0;

	public var bJimbleUseTan:Bool = true;

	public var noteFieldZoom = 1.0;

	public var bCosecant:Bool;

	public var modTimerType:ModTimerType = ModTimerType_Game;

	public var modTimerMult:Float;

	public var modTimerOffset:Float;

	public var bZBuffer:Bool;

	public var xOffset:Vector<Float>;

	public var player:Int;
	public var playField:PlayField;
	public var keyCount(default, null):Int;

	// only used for default reference PlayerStates
	public var x:Float;
	public var y:Float;
	public var z:Float;
	public var rotationX:Float;
	public var rotationY:Float;
	public var rotationZ:Float;
	public var zoom:Float = 1.0;
	public var zoomx:Float = 1.0;
	public var zoomy:Float = 1.0;
	public var zoomz:Float = 1.0;

	// 100: NOTE_SIZE pixels
	public var moveX:Float;
	public var moveY:Float;
	public var moveZ:Float;

	public var skewx:Float;
	public var skewy:Float;

	inline function colVec():Vector<Float>
	{
		return new Vector<Float>(keyCount, true);
	}

	public var colDark:Vector<Float>;

	public var colMoveX:Vector<Float>;
	public var colMoveY:Vector<Float>;
	public var colMoveZ:Vector<Float>;

	public var colRotationX:Vector<Float>;
	public var colRotationY:Vector<Float>;
	public var colRotationZ:Vector<Float>;

	public var colArrowPath:Vector<Float>;
	public var colArrowPathWidth:Vector<Float>;

	public var splines:ModSplineHandler;

	public var mods:Map<String, Modifier> = [];

	public var auxes:Map<String, NodeModifier> = [];

	public var nodes = new Vector<ModNode>();

	public var curr_dir:Int;

	@:allow(modchart.Modchart)
	var _allMods = new Vector<Modifier>();

	@:allow(modchart.ArrowEffects)
	var lastTime:Float;

	@:noCompletion
	public var _def:PlayerState;

	final _accels:Vector<Float>;
	final _effects:Vector<Float>;
	final _appearances:Vector<Float>;
	final _scrolls:Vector<Float>;

	public function new(player:Int, playField:PlayField, ?def:Bool)
	{
		this.player = player;
		this.playField = playField;
		keyCount = playField.strumLine.data.keyCount ?? 4;
		MOD_LENGTH = keyCount + 1;
		
		_accels = new Vector<Float>(NUM_ACCELS * MOD_LENGTH, true);
		_effects = new Vector<Float>(NUM_EFFECTS * MOD_LENGTH, true);
		_appearances = new Vector<Float>(NUM_APPEARANCES * MOD_LENGTH, true);
		_scrolls = new Vector<Float>(NUM_SCROLLS * MOD_LENGTH, true);

		splines = new ModSplineHandler(keyCount);

		xOffset = new Vector<Float>(keyCount, true, [
			for (i in 0...keyCount)
				((i - (y / 2)) * ArrowEffects.ARROW_SIZE) + ArrowEffects.ARROW_SIZE_HALF
		]);

		colDark = colVec();

		colMoveX = colVec();
		colMoveY = colVec();
		colMoveZ = colVec();

		colRotationX = colVec();
		colRotationY = colVec();
		colRotationZ = colVec();

		colArrowPath = colVec();
		colArrowPathWidth = colVec();

		if (!def)
			_def = new PlayerState(player, playField, true);

		for (i in 0...NUM_ACCELS)
			_addArrMod((i : Accel).toString(), _accels, i);
		for (i in 0...NUM_EFFECTS)
			_addArrMod((i : Effect).toString(), _effects, i);
		for (i in 0...NUM_APPEARANCES)
			_addArrMod((i : Appearance).toString(), _appearances, i);
		for (i in 0...NUM_SCROLLS)
			_addArrMod((i : Scroll).toString(), _scrolls, i);

		for (i in 0...keyCount)
		{
			addMod(new ArrayModifier('rotationX$i', this, colRotationX, i, false));
			addMod(new ArrayModifier('rotationY$i', this, colRotationY, i, false));
			addMod(new ArrayModifier('rotationZ$i', this, colRotationZ, i, false));

			addMod(new ArrayModifier('MoveX$i', this, colMoveX, i));
			addMod(new ArrayModifier('MoveY$i', this, colMoveY, i));
			addMod(new ArrayModifier('MoveZ$i', this, colMoveZ, i));

			addMod(new ArrayModifier('ArrowPath$i', this, colArrowPath, i));
			addMod(new ArrayModifier('ArrowPathWidth$i', this, colArrowPathWidth, i));
		}

		// noobs
		if (def)
		{
			addMod(new ModifierX("x", this, false));
			addMod(new ModifierY("y", this, false));
			addMod(new ModifierZ("z", this, false));
			addMod(new ModifierRotationX("rotationX", this, false));
			addMod(new ModifierRotationY("rotationY", this, false));
			addMod(new ModifierRotationZ("rotationZ", this, false));
			addMod(new ModifierZoom("zoom", this));
			addMod(new ModifierZoomX("zoomx", this));
			addMod(new ModifierZoomY("zoomy", this));
			addMod(new ModifierZoomZ("zoomz", this));
		}
		else
		{
			addMod(new ModifierPlayFieldX("x", this, false));
			addMod(new ModifierPlayFieldY("y", this, false));
			addMod(new ModifierPlayFieldZ("z", this, false));
			addMod(new ModifierPlayFieldRotationX("rotationX", this, false));
			addMod(new ModifierPlayFieldRotationY("rotationY", this, false));
			addMod(new ModifierPlayFieldRotationZ("rotationZ", this, false));
			addMod(new ModifierPlayFieldZoom("zoom", this));
			addMod(new ModifierPlayFieldZoomX("zoomx", this));
			addMod(new ModifierPlayFieldZoomY("zoomy", this));
			addMod(new ModifierPlayFieldZoomZ("zoomz", this));
		}
		addMod(new ModifierMoveX("MoveX", this));
		addMod(new ModifierMoveY("MoveY", this));
		addMod(new ModifierMoveZ("MoveZ", this));
		addMod(new ModifierSkewX("skewx", this, false));
		addMod(new ModifierSkewY("skewy", this, false));
		addMod(new ModifierDark("Dark", this));
		addMod(new ModifierBlind("Blind", this));
		addMod(new ModifierCover("Cover", this));
		// addMod(new ModifierJudgeScale("JudgeScale", this));
		addMod(new ModifierRandomSpeed("RandomSpeed", this, false));
		addMod(new ModifierArrowPath("ArrowPath", this));
		addMod(new ModifierArrowPathWidth("ArrowPathWidth", this));
		addMod(new ModifierXmod("xmod", this, false));
		addMod(new ModifierSpiralHolds("SpiralHolds", this));
		addMod(new ModifierStraightHolds("StraightHolds", this));
		addMod(new ModifierGayHolds("GayHolds", this));
		addMod(new ModifierGrain("Grain", this));
		addMod(new ModifierJimbleUseTan("JimbleUseTan", this));
		addMod(new ModifierZBuffer("ZBuffer", this));
		addMod(new ModifierCosecant("Cosecant", this));
	}

	public function resetAll(exclude:Array<String>)
	{
		exclude = [for (str in (exclude ?? [])) str.toLowerCase()];
		for (i in 0..._allMods.length)
		{
			final mod = _allMods[i];
			if (!exclude.contains(mod.id.toLowerCase()))
				mod.value = _def._allMods[i].value;
		}
	}

	public inline function addMod(mod:Modifier):Modifier
	{
		_allMods.push(mod);
		mods.set(mod.id.toLowerCase(), mod);
		return mod;
	}

	public function getReversePercentForColumn(iCol:Int):Float
	{
		var f = .0;
		final iNumCols = keyCount;

		f += fScrolls(SCROLL_REVERSE);

		if (iCol >= iNumCols / 2)
			f += fScrolls(SCROLL_SPLIT);

		if (iCol % 2 == 1)
			f += fScrolls(SCROLL_ALTERNATE);

		final iFirstCrossCol = iNumCols / keyCount;
		final iLastCrossCol = iNumCols - 1 - iFirstCrossCol;
		if (iCol >= iFirstCrossCol && iCol <= iLastCrossCol)
			f += fScrolls(SCROLL_CROSS);

		if (f > 2)
			f = ArrowEffects.mod(f, 2.0);
		if (f > 1)
			f = FlxMath.remapToRange(f, 1, 2, 1, 0);
		return f;
	}

	/**
	 * Returns 0 if there is no centered path, to prevent stupid calculations
	 * @return Null<Float>
	 */
	public function getZeroYOffset():Null<Float>
	{
		if (fScrolls(SCROLL_CENTERED_PATH) != 0)
			return null;
		return 0;
	}

	inline function _addArrMod(id:String, arr:Vector<Float>, index:Int)
	{
		addMod(new ArrayModifier(id, this, arr, index * MOD_LENGTH));
		for (i in 0...keyCount)
			addMod(new ArrayModifier('$id$i', this, arr, index * MOD_LENGTH + i + 1));
	}

	@:allow(modchart.Modchart)
	function getModTimerType(v:String)
	{
		modTimerType = v;
	}

	@:allow(modchart.Modchart)
	function setModTimerType(v:String)
	{
		modTimerType = v;
	}

	inline function get_fScrollSpeed():Float
	{
		return PlayState.instance.scrollSpeed;
	}
}

// thank you openitg

enum abstract Accel(Int) from Int to Int
{
	static final _str:Vector<String> = new Vector<String>(NUM_ACCELS, true, [
		for (i in 0...NUM_ACCELS)
		{
			switch (i : Accel)
			{
				case ACCEL_BOOST:
					"Boost";
				case ACCEL_BRAKE:
					"Brake";
				case ACCEL_WAVE:
					"Wave";
				case ACCEL_WAVE_PERIOD:
					"WavePeriod";
				case ACCEL_EXPAND:
					"Expand";
				case ACCEL_EXPAND_PERIOD:
					"ExpandPeriod";
				case ACCEL_TAN_EXPAND:
					"TanExpand";
				case ACCEL_TAN_EXPAND_PERIOD:
					"TanExpandPeriod";
				case ACCEL_BOOMERANG:
					"Boomerang";
				case NUM_ACCELS:
					throw "Num Accels";
			}
		}
	]);

	var ACCEL_BOOST; /**< The arrows start slow, then zoom towards the targets. */

	var ACCEL_BRAKE; /**< The arrows start fast, then slow down as they approach the targets. */

	var ACCEL_WAVE;

	var ACCEL_WAVE_PERIOD;
	var ACCEL_EXPAND;
	var ACCEL_EXPAND_PERIOD;
	var ACCEL_TAN_EXPAND;
	var ACCEL_TAN_EXPAND_PERIOD;
	var ACCEL_BOOMERANG; /**< The arrows start from above the targets, go down, then come back up. */

	var NUM_ACCELS;

	@:to
	public function toString():String
	{
		return _str[this];
	}
}

enum abstract Effect(Int) from Int to Int
{
	static final _str:Vector<String> = new Vector<String>(NUM_EFFECTS, true, [
		for (i in 0...NUM_EFFECTS)
		{
			switch (i : Effect)
			{
				case EFFECT_DRUNK:
					"Drunk";
				case EFFECT_DRUNK_SPEED:
					"DrunkSpeed";
				case EFFECT_DRUNK_OFFSET:
					"DrunkOffset";
				case EFFECT_DRUNK_PERIOD:
					"DrunkPeriod";
				case EFFECT_TAN_DRUNK:
					"TanDrunk";
				case EFFECT_TAN_DRUNK_SPEED:
					"TanDrunkSpeed";
				case EFFECT_TAN_DRUNK_OFFSET:
					"TanDrunkOffset";
				case EFFECT_TAN_DRUNK_PERIOD:
					"TanDrunkPeriod";
				case EFFECT_DRUNK_Z:
					"DrunkZ";
				case EFFECT_DRUNK_Z_SPEED:
					"DrunkZSpeed";
				case EFFECT_DRUNK_Z_OFFSET:
					"DrunkZOffset";
				case EFFECT_DRUNK_Z_PERIOD:
					"DrunkZPeriod";
				case EFFECT_TAN_DRUNK_Z:
					"TanDrunkZ";
				case EFFECT_TAN_DRUNK_Z_SPEED:
					"TanDrunkZSpeed";
				case EFFECT_TAN_DRUNK_Z_OFFSET:
					"TanDrunkZOffset";
				case EFFECT_TAN_DRUNK_Z_PERIOD:
					"TanDrunkZPeriod";
				case EFFECT_SHRINK_TO_LINEAR:
					"ShrinkLinear";
				case EFFECT_SHRINK_TO_MULT:
					"ShrinkMult";
				case EFFECT_PULSE_INNER:
					"PulseInner";
				case EFFECT_PULSE_OUTER:
					"PulseOuter";
				case EFFECT_PULSE_PERIOD:
					"PulsePeriod";
				case EFFECT_PULSE_OFFSET:
					"PulseOffset";
				case EFFECT_ATTENUATE_X:
					"AttenuateX";
				case EFFECT_ATTENUATE_Y:
					"AttenuateY";
				case EFFECT_ATTENUATE_Z:
					"AttenuateZ";
				case EFFECT_DIZZY:
					"Dizzy";
				case EFFECT_CONFUSION:
					"Confusion";
				case EFFECT_CONFUSION_OFFSET:
					"ConfusionOffset";
				case EFFECT_CONFUSION_X:
					"ConfusionX";
				case EFFECT_CONFUSION_X_OFFSET:
					"ConfusionXOffset";
				case EFFECT_CONFUSION_Y:
					"ConfusionY";
				case EFFECT_CONFUSION_Y_OFFSET:
					"ConfusionYOffset";
				case EFFECT_BOUNCE:
					"Bounce";
				case EFFECT_BOUNCE_PERIOD:
					"BouncePeriod";
				case EFFECT_BOUNCE_OFFSET:
					"BounceOffset";
				case EFFECT_BOUNCE_Z:
					"BounceZ";
				case EFFECT_BOUNCE_Z_PERIOD:
					"BounceZPeriod";
				case EFFECT_BOUNCE_Z_OFFSET:
					"BounceZOffset";
				case EFFECT_MINI:
					"Mini";
				case EFFECT_TINY:
					"Tiny";
				case EFFECT_TINY_X:
					"TinyX";
				case EFFECT_TINY_Y:
					"TinyY";
				case EFFECT_TINY_Z:
					"TinyZ";
				case EFFECT_FLIP:
					"Flip";
				case EFFECT_INVERT:
					"Invert";
				case EFFECT_TORNADO:
					"Tornado";
				case EFFECT_TORNADO_PERIOD:
					"TornadoPeriod";
				case EFFECT_TORNADO_OFFSET:
					"TornadoOffset";
				case EFFECT_TAN_TORNADO:
					"TanTornado";
				case EFFECT_TAN_TORNADO_PERIOD:
					"TanTornadoPeriod";
				case EFFECT_TAN_TORNADO_OFFSET:
					"TanTornadoOffset";
				case EFFECT_TORNADO_Z:
					"TornadoZ";
				case EFFECT_TORNADO_Z_PERIOD:
					"TornadoZPeriod";
				case EFFECT_TORNADO_Z_OFFSET:
					"TornadoZOffset";
				case EFFECT_TAN_TORNADO_Z:
					"TanTornadoZ";
				case EFFECT_TAN_TORNADO_Z_PERIOD:
					"TanTornadoZPeriod";
				case EFFECT_TAN_TORNADO_Z_OFFSET:
					"TanTornadoZOffset";
				case EFFECT_TIPSY:
					"Tipsy";
				case EFFECT_TIPSY_SPEED:
					"TipsySpeed";
				case EFFECT_TIPSY_OFFSET:
					"TipsyOffset";
				case EFFECT_TAN_TIPSY:
					"TanTipsy";
				case EFFECT_TAN_TIPSY_SPEED:
					"TanTipsySpeed";
				case EFFECT_TAN_TIPSY_OFFSET:
					"TanTipsyOffset";
				case EFFECT_BUMPY:
					"Bumpy";
				case EFFECT_BUMPY_OFFSET:
					"BumpyOffset";
				case EFFECT_BUMPY_PERIOD:
					"BumpyPeriod";
				case EFFECT_TAN_BUMPY:
					"TanBumpy";
				case EFFECT_TAN_BUMPY_OFFSET:
					"TanBumpyOffset";
				case EFFECT_TAN_BUMPY_PERIOD:
					"TanBumpyPeriod";
				case EFFECT_BUMPY_X:
					"BumpyX";
				case EFFECT_BUMPY_X_OFFSET:
					"BumpyXOffset";
				case EFFECT_BUMPY_X_PERIOD:
					"BumpyXPeriod";
				case EFFECT_TAN_BUMPY_X:
					"TanBumpyX";
				case EFFECT_TAN_BUMPY_X_OFFSET:
					"TanBumpyXOffset";
				case EFFECT_TAN_BUMPY_X_PERIOD:
					"TanBumpyXPeriod";
				case EFFECT_BEAT:
					"Beat";
				case EFFECT_BEAT_OFFSET:
					"BeatOffset";
				case EFFECT_BEAT_PERIOD:
					"BeatPeriod";
				case EFFECT_BEAT_MULT:
					"BeatMult";
				case EFFECT_BEAT_Y:
					"BeatY";
				case EFFECT_BEAT_Y_OFFSET:
					"BeatYOffset";
				case EFFECT_BEAT_Y_PERIOD:
					"BeatYPeriod";
				case EFFECT_BEAT_Y_MULT:
					"BeatYMult";
				case EFFECT_BEAT_Z:
					"BeatZ";
				case EFFECT_BEAT_Z_OFFSET:
					"BeatZOffset";
				case EFFECT_BEAT_Z_PERIOD:
					"BeatZPeriod";
				case EFFECT_BEAT_Z_MULT:
					"BeatZMult";
				case EFFECT_ZIGZAG:
					"Zigzag";
				case EFFECT_ZIGZAG_PERIOD:
					"ZigzagPeriod";
				case EFFECT_ZIGZAG_OFFSET:
					"ZigzagOffset";
				case EFFECT_ZIGZAG_Z:
					"ZigzagZ";
				case EFFECT_ZIGZAG_Z_PERIOD:
					"ZigzagZPeriod";
				case EFFECT_ZIGZAG_Z_OFFSET:
					"ZigzagZOffset";
				case EFFECT_SAWTOOTH:
					"Sawtooth";
				case EFFECT_SAWTOOTH_PERIOD:
					"SawtoothPeriod";
				case EFFECT_SAWTOOTH_Z:
					"SawtoothZ";
				case EFFECT_SAWTOOTH_Z_PERIOD:
					"SawtoothZPeriod";
				case EFFECT_SQUARE:
					"Square";
				case EFFECT_SQUARE_OFFSET:
					"SquareOffset";
				case EFFECT_SQUARE_PERIOD:
					"SquarePeriod";
				case EFFECT_SQUARE_Z:
					"SquareZ";
				case EFFECT_SQUARE_Z_OFFSET:
					"SquareZOffset";
				case EFFECT_SQUARE_Z_PERIOD:
					"SquareZPeriod";
				case EFFECT_DIGITAL:
					"Digital";
				case EFFECT_DIGITAL_STEPS:
					"DigitalSteps";
				case EFFECT_DIGITAL_PERIOD:
					"DigitalPeriod";
				case EFFECT_DIGITAL_OFFSET:
					"DigitalOffset";
				case EFFECT_TAN_DIGITAL:
					"TanDigital";
				case EFFECT_TAN_DIGITAL_STEPS:
					"TanDigitalSteps";
				case EFFECT_TAN_DIGITAL_PERIOD:
					"TanDigitalPeriod";
				case EFFECT_TAN_DIGITAL_OFFSET:
					"TanDigitalOffset";
				case EFFECT_DIGITAL_Z:
					"DigitalZ";
				case EFFECT_DIGITAL_Z_STEPS:
					"DigitalZSteps";
				case EFFECT_DIGITAL_Z_PERIOD:
					"DigitalZPeriod";
				case EFFECT_DIGITAL_Z_OFFSET:
					"DigitalZOffset";
				case EFFECT_TAN_DIGITAL_Z:
					"TanDigitalZ";
				case EFFECT_TAN_DIGITAL_Z_STEPS:
					"TanDigitalZSteps";
				case EFFECT_TAN_DIGITAL_Z_PERIOD:
					"TanDigitalZPeriod";
				case EFFECT_TAN_DIGITAL_Z_OFFSET:
					"TanDigitalZOffset";
				case EFFECT_PARABOLA_X:
					"ParabolaX";
				case EFFECT_PARABOLA_Y:
					"ParabolaY";
				case EFFECT_PARABOLA_Z:
					"ParabolaZ";
				case EFFECT_XMODE:
					"XMode";
				case EFFECT_TWIRL:
					"Twirl";
				case EFFECT_ROLL:
					"Roll";
				case EFFECT_JIMBLE:
					"Jimble";
				case EFFECT_JIMBLE_SPREAD:
					"JimbleSpread";
				case EFFECT_JIMBLE_Z:
					"JimbleZ";
				case EFFECT_JIMBLE_SPEED:
					"JimbleSpeed";
				case NUM_EFFECTS:
					throw "Num Effects";
			}
		}
	]);

	var EFFECT_DRUNK;
	var EFFECT_DRUNK_SPEED;
	var EFFECT_DRUNK_OFFSET;
	var EFFECT_DRUNK_PERIOD;
	var EFFECT_TAN_DRUNK;
	var EFFECT_TAN_DRUNK_SPEED;
	var EFFECT_TAN_DRUNK_OFFSET;
	var EFFECT_TAN_DRUNK_PERIOD;
	var EFFECT_DRUNK_Z;
	var EFFECT_DRUNK_Z_SPEED;
	var EFFECT_DRUNK_Z_OFFSET;
	var EFFECT_DRUNK_Z_PERIOD;
	var EFFECT_TAN_DRUNK_Z;
	var EFFECT_TAN_DRUNK_Z_SPEED;
	var EFFECT_TAN_DRUNK_Z_OFFSET;
	var EFFECT_TAN_DRUNK_Z_PERIOD;
	var EFFECT_DIZZY;
	var EFFECT_ATTENUATE_X;
	var EFFECT_ATTENUATE_Y;
	var EFFECT_ATTENUATE_Z;
	var EFFECT_SHRINK_TO_MULT;
	var EFFECT_SHRINK_TO_LINEAR;
	var EFFECT_PULSE_INNER;
	var EFFECT_PULSE_OUTER;
	var EFFECT_PULSE_OFFSET;
	var EFFECT_PULSE_PERIOD;
	var EFFECT_CONFUSION;
	var EFFECT_CONFUSION_OFFSET;
	var EFFECT_CONFUSION_X;
	var EFFECT_CONFUSION_X_OFFSET;
	var EFFECT_CONFUSION_Y;
	var EFFECT_CONFUSION_Y_OFFSET;
	var EFFECT_BOUNCE;
	var EFFECT_BOUNCE_PERIOD;
	var EFFECT_BOUNCE_OFFSET;
	var EFFECT_BOUNCE_Z;
	var EFFECT_BOUNCE_Z_PERIOD;
	var EFFECT_BOUNCE_Z_OFFSET;
	var EFFECT_MINI;
	var EFFECT_TINY;
	var EFFECT_TINY_X;
	var EFFECT_TINY_Y;
	var EFFECT_TINY_Z;
	var EFFECT_FLIP;
	var EFFECT_INVERT;
	var EFFECT_TORNADO;
	var EFFECT_TORNADO_PERIOD;
	var EFFECT_TORNADO_OFFSET;
	var EFFECT_TAN_TORNADO;
	var EFFECT_TAN_TORNADO_PERIOD;
	var EFFECT_TAN_TORNADO_OFFSET;
	var EFFECT_TORNADO_Z;
	var EFFECT_TORNADO_Z_PERIOD;
	var EFFECT_TORNADO_Z_OFFSET;
	var EFFECT_TAN_TORNADO_Z;
	var EFFECT_TAN_TORNADO_Z_PERIOD;
	var EFFECT_TAN_TORNADO_Z_OFFSET;
	var EFFECT_TIPSY;
	var EFFECT_TIPSY_SPEED;
	var EFFECT_TIPSY_OFFSET;
	var EFFECT_TAN_TIPSY;
	var EFFECT_TAN_TIPSY_SPEED;
	var EFFECT_TAN_TIPSY_OFFSET;
	var EFFECT_BUMPY;
	var EFFECT_BUMPY_OFFSET;
	var EFFECT_BUMPY_PERIOD;
	var EFFECT_TAN_BUMPY;
	var EFFECT_TAN_BUMPY_OFFSET;
	var EFFECT_TAN_BUMPY_PERIOD;
	var EFFECT_BUMPY_X;
	var EFFECT_BUMPY_X_OFFSET;
	var EFFECT_BUMPY_X_PERIOD;
	var EFFECT_TAN_BUMPY_X;
	var EFFECT_TAN_BUMPY_X_OFFSET;
	var EFFECT_TAN_BUMPY_X_PERIOD;
	var EFFECT_BEAT;
	var EFFECT_BEAT_OFFSET;
	var EFFECT_BEAT_PERIOD;
	var EFFECT_BEAT_MULT;
	var EFFECT_BEAT_Y;
	var EFFECT_BEAT_Y_OFFSET;
	var EFFECT_BEAT_Y_PERIOD;
	var EFFECT_BEAT_Y_MULT;
	var EFFECT_BEAT_Z;
	var EFFECT_BEAT_Z_OFFSET;
	var EFFECT_BEAT_Z_PERIOD;
	var EFFECT_BEAT_Z_MULT;
	var EFFECT_DIGITAL;
	var EFFECT_DIGITAL_STEPS;
	var EFFECT_DIGITAL_PERIOD;
	var EFFECT_DIGITAL_OFFSET;
	var EFFECT_TAN_DIGITAL;
	var EFFECT_TAN_DIGITAL_STEPS;
	var EFFECT_TAN_DIGITAL_PERIOD;
	var EFFECT_TAN_DIGITAL_OFFSET;
	var EFFECT_DIGITAL_Z;
	var EFFECT_DIGITAL_Z_STEPS;
	var EFFECT_DIGITAL_Z_PERIOD;
	var EFFECT_DIGITAL_Z_OFFSET;
	var EFFECT_TAN_DIGITAL_Z;
	var EFFECT_TAN_DIGITAL_Z_STEPS;
	var EFFECT_TAN_DIGITAL_Z_PERIOD;
	var EFFECT_TAN_DIGITAL_Z_OFFSET;
	var EFFECT_ZIGZAG;
	var EFFECT_ZIGZAG_PERIOD;
	var EFFECT_ZIGZAG_OFFSET;
	var EFFECT_ZIGZAG_Z;
	var EFFECT_ZIGZAG_Z_PERIOD;
	var EFFECT_ZIGZAG_Z_OFFSET;
	var EFFECT_SAWTOOTH;
	var EFFECT_SAWTOOTH_PERIOD;
	var EFFECT_SAWTOOTH_Z;
	var EFFECT_SAWTOOTH_Z_PERIOD;
	var EFFECT_SQUARE;
	var EFFECT_SQUARE_PERIOD;
	var EFFECT_SQUARE_OFFSET;
	var EFFECT_SQUARE_Z;
	var EFFECT_SQUARE_Z_PERIOD;
	var EFFECT_SQUARE_Z_OFFSET;
	var EFFECT_PARABOLA_X;
	var EFFECT_PARABOLA_Y;
	var EFFECT_PARABOLA_Z;
	var EFFECT_XMODE;
	var EFFECT_TWIRL;
	var EFFECT_ROLL;
	var EFFECT_JIMBLE;
	var EFFECT_JIMBLE_SPREAD;
	var EFFECT_JIMBLE_Z; // adjusts how much it moves on z (for crud this was lowered)
	var EFFECT_JIMBLE_SPEED;
	var NUM_EFFECTS;

	@:to
	public function toString():String
	{
		return _str[this];
	}
}

enum abstract Appearance(Int) from Int to Int
{
	static final _str:Vector<String> = new Vector<String>(NUM_APPEARANCES, true, [
		for (i in 0...NUM_APPEARANCES)
		{
			switch (i : Appearance)
			{
				case APPEARANCE_HIDDEN:
					"Hidden";
				case APPEARANCE_HIDDEN_OFFSET:
					"HiddenOffset";
				case APPEARANCE_HIDDEN_RED:
					"HiddenRed";
				case APPEARANCE_HIDDEN_RED_OFFSET:
					"HiddenRedOffset";
				case APPEARANCE_HIDDEN_GREEN:
					"HiddenGreen";
				case APPEARANCE_HIDDEN_GREEN_OFFSET:
					"HiddenGreenOffset";
				case APPEARANCE_HIDDEN_BLUE:
					"HiddenBlue";
				case APPEARANCE_HIDDEN_BLUE_OFFSET:
					"HiddenBlueOffset";
				case APPEARANCE_SUDDEN:
					"Sudden";
				case APPEARANCE_SUDDEN_OFFSET:
					"SuddenOffset";
				case APPEARANCE_SUDDEN_RED:
					"SuddenRed";
				case APPEARANCE_SUDDEN_RED_OFFSET:
					"SuddenRedOffset";
				case APPEARANCE_SUDDEN_GREEN:
					"SuddenGreen";
				case APPEARANCE_SUDDEN_GREEN_OFFSET:
					"SuddenGreenOffset";
				case APPEARANCE_SUDDEN_BLUE:
					"SuddenBlue";
				case APPEARANCE_SUDDEN_BLUE_OFFSET:
					"SuddenBlueOffset";
				case APPEARANCE_STEALTH:
					"Stealth";
				case APPEARANCE_STEALTH_RED:
					"StealthRed";
				case APPEARANCE_STEALTH_GREEN:
					"StealthGreen";
				case APPEARANCE_STEALTH_BLUE:
					"StealthBlue";
				case APPEARANCE_BLINK:
					"Blink";
				case APPEARANCE_BLINK_RED:
					"BlinkRed";
				case APPEARANCE_BLINK_GREEN:
					"BlinkGreen";
				case APPEARANCE_BLINK_BLUE:
					"BlinkBlue";
				case APPEARANCE_RANDOMVANISH:
					"RandomVanish";
				case APPEARANCE_RANDOMVANISH_RED:
					"RandomVanishRed";
				case APPEARANCE_RANDOMVANISH_GREEN:
					"RandomVanishGreen";
				case APPEARANCE_RANDOMVANISH_BLUE:
					"RandomVanishBlue";
				case NUM_APPEARANCES:
					throw "Num Appearances";
			}
		}
	]);

	// hidden
	var APPEARANCE_HIDDEN; /**< The arrows disappear partway up. */

	var APPEARANCE_HIDDEN_OFFSET; /**< This determines when the arrows disappear. */

	var APPEARANCE_HIDDEN_RED; /**< The arrows disappear partway up. */

	var APPEARANCE_HIDDEN_RED_OFFSET; /**< This determines when the arrows disappear. */

	var APPEARANCE_HIDDEN_GREEN; /**< The arrows disappear partway up. */

	var APPEARANCE_HIDDEN_GREEN_OFFSET; /**< This determines when the arrows disappear. */

	var APPEARANCE_HIDDEN_BLUE; /**< The arrows disappear partway up. */

	var APPEARANCE_HIDDEN_BLUE_OFFSET; /**< This determines when the arrows disappear. */

	// sudden
	var APPEARANCE_SUDDEN; /**< The arrows appear partway up. */

	var APPEARANCE_SUDDEN_OFFSET; /**< This determines when the arrows appear. */

	var APPEARANCE_SUDDEN_RED; /**< The arrows appear partway up. */

	var APPEARANCE_SUDDEN_RED_OFFSET; /**< This determines when the arrows appear. */

	var APPEARANCE_SUDDEN_GREEN; /**< The arrows appear partway up. */

	var APPEARANCE_SUDDEN_GREEN_OFFSET; /**< This determines when the arrows appear. */

	var APPEARANCE_SUDDEN_BLUE; /**< The arrows appear partway up. */

	var APPEARANCE_SUDDEN_BLUE_OFFSET; /**< This determines when the arrows appear. */

	// stealth
	var APPEARANCE_STEALTH; /**< The arrows are not shown at all. */

	var APPEARANCE_STEALTH_RED; /**< The arrows are not shown at all. */

	var APPEARANCE_STEALTH_GREEN; /**< The arrows are not shown at all. */

	var APPEARANCE_STEALTH_BLUE; /**< The arrows are not shown at all. */

	// blink
	var APPEARANCE_BLINK; /**< The arrows blink constantly. */

	var APPEARANCE_BLINK_RED; /**< The arrows blink constantly. */

	var APPEARANCE_BLINK_GREEN; /**< The arrows blink constantly. */

	var APPEARANCE_BLINK_BLUE; /**< The arrows blink constantly. */

	// randomvanish
	var APPEARANCE_RANDOMVANISH; /**< The arrows disappear, and then reappear in a different column. */

	var APPEARANCE_RANDOMVANISH_RED; /**< The arrows disappear, and then reappear in a different column. */

	var APPEARANCE_RANDOMVANISH_GREEN; /**< The arrows disappear, and then reappear in a different column. */

	var APPEARANCE_RANDOMVANISH_BLUE; /**< The arrows disappear, and then reappear in a different column. */

	var NUM_APPEARANCES;

	@:to
	public function toString():String
	{
		return _str[this];
	}
}

enum abstract Turn(Int) from Int to Int
{
	static final _str:Vector<String> = new Vector<String>(NUM_TURNS, true, [
		for (i in 0...NUM_TURNS)
		{
			switch (i : Turn)
			{
				case TURN_NONE:
					"TurnNone"; // lol?
				case TURN_MIRROR:
					"Mirror";
				case TURN_LEFT:
					"Left";
				case TURN_RIGHT:
					"Right";
				case TURN_SHUFFLE:
					"Shuffle";
				case TURN_SUPER_SHUFFLE:
					"SuperShuffle";
				case NUM_TURNS:
					throw "Num Turns";
			}
		}
	]);

	var TURN_NONE;
	var TURN_MIRROR;
	var TURN_LEFT;
	var TURN_RIGHT;
	var TURN_SHUFFLE;
	var TURN_SUPER_SHUFFLE;
	var NUM_TURNS;

	@:to
	public function toString():String
	{
		return _str[this];
	}
}

enum abstract Transform(Int) from Int to Int
{
	static final _str:Vector<String> = new Vector<String>(NUM_TRANSFORMS, true, [
		for (i in 0...NUM_TRANSFORMS)
		{
			switch (i : Transform)
			{
				case TRANSFORM_NOHOLDS:
					"NoHolds";
				case TRANSFORM_HOLDSTOROLLS:
					"HoldsToRolls";
				case TRANSFORM_NOROLLS:
					"NoRolls";
				case TRANSFORM_NOMINES:
					"NoMines";
				case TRANSFORM_LITTLE:
					"Little";
				case TRANSFORM_WIDE:
					"Wide";
				case TRANSFORM_BIG:
					"Big";
				case TRANSFORM_QUICK:
					"Quick";
				case TRANSFORM_BMRIZE:
					"BMRize";
				case TRANSFORM_SKIPPY:
					"Skippy";
				case TRANSFORM_MINES:
					"Mines";
				case TRANSFORM_ECHO:
					"Echo";
				case TRANSFORM_STOMP:
					"Stomp";
				case TRANSFORM_PLANTED:
					"Planted";
				case TRANSFORM_FLOORED:
					"Floored";
				case TRANSFORM_TWISTER:
					"Twister";
				case TRANSFORM_NOJUMPS:
					"NoJumps";
				case TRANSFORM_NOHANDS:
					"NoHands";
				case TRANSFORM_NOQUADS:
					"NoQuads";
				case TRANSFORM_NOSTRETCH:
					"NoStretch";
				case NUM_TRANSFORMS:
					throw "Num Transforms";
			}
		}
	]);

	var TRANSFORM_NOHOLDS;
	var TRANSFORM_HOLDSTOROLLS;
	var TRANSFORM_NOROLLS;
	var TRANSFORM_NOMINES;
	var TRANSFORM_LITTLE;
	var TRANSFORM_WIDE;
	var TRANSFORM_BIG;
	var TRANSFORM_QUICK;
	var TRANSFORM_BMRIZE;
	var TRANSFORM_SKIPPY;
	var TRANSFORM_MINES;
	var TRANSFORM_ECHO;
	var TRANSFORM_STOMP;
	var TRANSFORM_PLANTED;
	var TRANSFORM_FLOORED;
	var TRANSFORM_TWISTER;
	var TRANSFORM_NOJUMPS;
	var TRANSFORM_NOHANDS;
	var TRANSFORM_NOQUADS;
	var TRANSFORM_NOSTRETCH;
	var NUM_TRANSFORMS;

	@:to
	public function toString():String
	{
		return _str[this];
	}
}

enum abstract Scroll(Int) from Int to Int
{
	static final _str:Vector<String> = new Vector<String>(NUM_SCROLLS, true, [
		for (i in 0...NUM_SCROLLS)
		{
			switch (i : Scroll)
			{
				case SCROLL_REVERSE:
					"Reverse";
				case SCROLL_SPLIT:
					"Split";
				case SCROLL_ALTERNATE:
					"Alternate";
				case SCROLL_CROSS:
					"Cross";
				case SCROLL_CENTERED:
					"Centered";
				case SCROLL_CENTERED_PATH:
					"CenteredPath";
				case NUM_SCROLLS:
					throw "Num Scrolls";
			}
		}
	]);

	var SCROLL_REVERSE;
	var SCROLL_SPLIT;
	var SCROLL_ALTERNATE;
	var SCROLL_CROSS;
	var SCROLL_CENTERED;
	var SCROLL_CENTERED_PATH;
	var NUM_SCROLLS;

	@:to
	public function toString():String
	{
		return _str[this];
	}
}

enum abstract ScoreDisplay(Int) from Int to Int
{
	static final _str:Vector<String> = new Vector<String>(NUM_SCOREDISPLAYS, true, [
		for (i in 0...NUM_SCOREDISPLAYS)
		{
			switch (i : ScoreDisplay)
			{
				case SCORING_ADD:
					"AddScore";
				case SCORING_SUBTRACT:
					"SubtractScore";
				case SCORING_AVERAGE:
					"AverageScore";
				case NUM_SCOREDISPLAYS:
					throw "Num Transforms";
			}
		}
	]);

	var SCORING_ADD;
	var SCORING_SUBTRACT;
	var SCORING_AVERAGE;
	var NUM_SCOREDISPLAYS;

	@:to
	public function toString():String
	{
		return _str[this];
	}
}

enum abstract Dimension(Int) to Int
{
	var dim_x;
	var dim_y;
	var dim_z;
	var num_dim;
}

// todo: this
enum abstract AppearanceColor(Int) to Int
{
	var col_white;
	var col_red;
	var col_green;
	var col_blue;
}

enum abstract ModTimerType(String) from String to String
{
	var ModTimerType_Game;
	var ModTimerType_Beat;
	var ModTimerType_Song;
	var ModTimerType_Default;
}

#if !modchart_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
final class PerPlayerData
{
	var player:Int;

	public function new(player:Int)
	{
		inline function colVec():Vector<Float>
		{
			return new Vector<Float>(PlayState.instance.strumLines.members[player].data.keyCount ?? 4, true);
		}

		inline function dimVec():Vector<Float>
		{
			return new Vector<Float>(num_dim, true);
		}

		// thank you haxe and openfl
		minTornado = new Vector<Vector<Float>>();
		maxTornado = new Vector<Vector<Float>>();
		for (_ in 0...num_dim)
		{
			minTornado.push(colVec());
			maxTornado.push(colVec());
		}

		fInvertDistance = colVec();
		tipsy_result = colVec();
		tipsy_offset_result = colVec();
		tan_tipsy_result = colVec();
		tan_tipsy_offset_result = colVec();
		fBeatFactor = dimVec();
		fExpandSeconds = .0;
		fTanExpandSeconds = .0;
		fJimbleTime = colVec();
		fJimbleSin = colVec();
		fJimbleCos = colVec();
		fJimbleTan = colVec();
	}

	public var minTornado:Vector<Vector<Float>>;
	public var maxTornado:Vector<Vector<Float>>;
	public var fInvertDistance:Vector<Float>;
	public var tipsy_result:Vector<Float>;
	public var tipsy_offset_result:Vector<Float>;
	public var tan_tipsy_result:Vector<Float>;
	public var tan_tipsy_offset_result:Vector<Float>;
	public var fBeatFactor:Vector<Float>;
	public var fExpandSeconds:Float;
	public var fTanExpandSeconds:Float;
	public var fJimbleTime:Vector<Float>;
	public var fJimbleSin:Vector<Float>;
	public var fJimbleCos:Vector<Float>;
	public var fJimbleTan:Vector<Float>;
}

typedef ModSplineVector = Vector<Vector<ModSplinePoint>>;

#if !modchart_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
final class ModSplineHandler
{
	public var x:ModSplineValue;
	public var y:ModSplineValue;
	public var z:ModSplineValue;
	public var rotationx:ModSplineValue;
	public var rotationy:ModSplineValue;
	public var rotationz:ModSplineValue;
	public var size:ModSplineValue;
	public var stealth:ModSplineValue;
	public var skew:ModSplineValue;

	public function new(player:Int)
	{
		x = new ModSplineValue(player);
		y = new ModSplineValue(player);
		z = new ModSplineValue(player);
		rotationx = new ModSplineValue(player);
		rotationy = new ModSplineValue(player);
		rotationz = new ModSplineValue(player);
		size = new ModSplineValue(player);
		stealth = new ModSplineValue(player);
		skew = new ModSplineValue(player);
	}
}

#if !modchart_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
final class ModSplineValue
{
	static final SPLINE_LENGTH = 40;

	public var col:ModSplineVector;
	public var type:Float = .0;
	public var offset:Vector<Float>;

	var keyCount:Int;

	var cur_col:Vector<ModSplinePoint>;

	public function new(keyCount:Int)
	{
		this.keyCount = keyCount;
		offset = new Vector<Float>(keyCount, true);
		col = new ModSplineVector();
		for (_ in 0...keyCount)
			col.push(new Vector<ModSplinePoint>());
	}

	public function set(which:Int, column:Int, percentage:Float, beat:Float, speed:Float)
	{
		if (which >= SPLINE_LENGTH)
			return;
		if (column == -1)
		{
			for (i in 0...keyCount)
				set(which, i, percentage, beat, speed);
		}
		else
		{
			col[column][which] ??= ModSplinePoint.get();
			col[column][which].set(percentage, beat, speed);
		}
	}

	public function reset(column:Int)
	{
		if (column == -1)
		{
			for (i in 0...keyCount)
				reset(i);
		}
		else
		{
			var i = 0;
			while (i < SPLINE_LENGTH)
			{
				col[column][i]?.put();
				col[column][i] = null;
			}
			col[column].length = 0;
		}
	}

	public function getPercentage(beat:Float, column:Int):Float
	{
		cur_col = col[column];
		beat += offset[column];

		var percentage = (cur_col[0] ?? ModSplinePoint.ZERO).percentage;

		if (type > 1)
		{
			if (cur_col[1] == null)
				return percentage;
			var i = 1;
			while (i < SPLINE_LENGTH)
			{
				if (cur_col[i + 1] == null)
				{ // last points
					percentage = cur_col[i].percentage;
					break;
				}
				final fi0 = (i == 1) ? cur_col[i - 1] ?? ModSplinePoint.ZERO : cur_col[i - 1];
				final fi1 = cur_col[i];
				final fi2 = cur_col[i + 1] ?? fi1;
				final fi3 = cur_col[i + 2] ?? fi2;

				i++;
				// if the next point is earlier than our beat then skip to that one (keeps happening until we reach our final one)
				if (cur_col[i + 1] != null && beat >= cur_col[i + 1].beat)
				{
					continue;
				}
				else
				{
					final t = FlxMath.bound(FlxMath.remapToRange(beat, fi0.beat, fi3.beat, 0, 1), 0, 1);
					percentage = BezierUtil.mix4(t, fi0.percentage, fi1.percentage, fi2.percentage, fi3.percentage);
					break;
				}
			}
		}
		else
		{
			var i = 1;
			while (i < SPLINE_LENGTH)
			{
				if (cur_col[i] == null)
					break;
				final p = cur_col[i];
				final lp = cur_col[i - 1] ?? ModSplinePoint.ZERO;
				if (lp.beat <= beat && p.beat >= beat)
				{
					final t = FlxMath.bound(FlxMath.remapToRange(beat, lp.beat, p.beat, 0, 1), 0, 1);
					percentage = FlxMath.lerp(lp.percentage, p.percentage, type > .0 ? FlxEase.sineInOut(t) : t);
					break;
				}
				else
				{
					percentage = p.percentage; // for last points
				}
				i++;
			}
		}
		return percentage;
	}
}

#if !modchart_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
final class ModSplinePoint implements IFlxPooled
{
	public static var ZERO = new ModSplinePoint();

	static var pool = new FlxPool<ModSplinePoint>(ModSplinePoint /*.new*/); // DAVE TODO: davealicious

	public var percentage:Float;
	public var beat:Float;
	public var speed:Float;

	function new()
	{
	}

	public static inline function get():ModSplinePoint
	{
		return pool.get();
	}

	public function set(percentage:Float, beat:Float, speed:Float)
	{
		this.percentage = percentage;
		this.beat = beat;
		this.speed = speed;
	}

	public function put()
	{
		pool.putUnsafe(this);
	}

	public function putWeak()
	{
	}

	public function destroy()
	{
	}
}

// general linker class

@:allow(modchart)
#if !modchart_debug
@:fileXml('tags="haxe,release"') @:noDebug
#end
class Modifier
{
	public var id:String;

	public var value(get, set):Float;

	public var valueOffset:Float;

	public var isPercent:Bool; // only used by Modchart.hx, if true then the modchart will convert 100 -> 1 50 -> .5 etc. does not effect the actual value passed through set_value

	var playerState:PlayerState;

	public function new(id:String, playerState:PlayerState, isPercent:Bool = true)
	{
		this.id = id;
		this.playerState = playerState;
		this.isPercent = isPercent;
	}

	public function toString():String
	{
		return 'Modifier (${playerState.player} | $id, $value)';
	}

	public function clone(id:String):Modifier
	{
		return new Modifier(id, playerState, isPercent);
	}

	function get_value():Float
	{
		throw "Bad";
	}

	function set_value(v:Float):Float
	{
		throw "Bad2";
	}
}

// linker class for vectors specifically
class ArrayModifier extends Modifier
{
	var array:Vector<Float>;
	var index:Int;

	public function new(id:String, playerState:PlayerState, array:Vector<Float>, index:Int, isPercent:Bool = true)
	{
		super(id, playerState, isPercent);
		this.array = array;
		this.index = index;
	}

	override function clone(id:String):Modifier
	{
		return new ArrayModifier(id, playerState, array, index, isPercent);
	}

	override function get_value():Float
	{
		return array[index];
	}

	override function set_value(v:Float):Float
	{
		return array[index] = v;
	}
}

@:autoBuild(modchart.macro.ModifierMacro.build("float"))
class ValueFloatModifier extends Modifier
{
}

@:autoBuild(modchart.macro.ModifierMacro.build("bool"))
class ValueBoolModifier extends Modifier
{
	public function new(id:String, playerState:PlayerState)
	{
		super(id, playerState, false);
	}
}

// noobs
@:modifier("x") class ModifierX extends ValueFloatModifier
{
}

@:modifier("y") class ModifierY extends ValueFloatModifier
{
}

@:modifier("z") class ModifierZ extends ValueFloatModifier
{
}

@:modifier("rotationX") class ModifierRotationX extends ValueFloatModifier
{
}

@:modifier("rotationY") class ModifierRotationY extends ValueFloatModifier
{
}

@:modifier("rotationZ") class ModifierRotationZ extends ValueFloatModifier
{
}

@:modifier("zoom") class ModifierZoom extends ValueFloatModifier
{
}

@:modifier("zoomx") class ModifierZoomX extends ValueFloatModifier
{
}

@:modifier("zoomy") class ModifierZoomY extends ValueFloatModifier
{
}

@:modifier("zoomz") class ModifierZoomZ extends ValueFloatModifier
{
}

@:modifier("pos.x", "playfield") class ModifierPlayFieldX extends ValueFloatModifier
{
}

@:modifier("pos.y", "playfield") class ModifierPlayFieldY extends ValueFloatModifier
{
}

@:modifier("pos.z", "playfield") class ModifierPlayFieldZ extends ValueFloatModifier
{
}

@:modifier("rot.x", "playfield") class ModifierPlayFieldRotationX extends ValueFloatModifier
{
}

@:modifier("rot.y", "playfield") class ModifierPlayFieldRotationY extends ValueFloatModifier
{
}

@:modifier("rot.z", "playfield") class ModifierPlayFieldRotationZ extends ValueFloatModifier
{
}

@:modifier("zoom.w", "playfield", false) class ModifierPlayFieldZoom extends ValueFloatModifier
{
}

@:modifier("zoom.x", "playfield", false) class ModifierPlayFieldZoomX extends ValueFloatModifier
{
}

@:modifier("zoom.y", "playfield", false) class ModifierPlayFieldZoomY extends ValueFloatModifier
{
}

@:modifier("zoom.z", "playfield", false) class ModifierPlayFieldZoomZ extends ValueFloatModifier
{
}

@:modifier("moveX") class ModifierMoveX extends ValueFloatModifier
{
}

@:modifier("moveY") class ModifierMoveY extends ValueFloatModifier
{
}

@:modifier("moveZ") class ModifierMoveZ extends ValueFloatModifier
{
}

@:modifier("skewx") class ModifierSkewX extends ValueFloatModifier
{
}

@:modifier("skewy") class ModifierSkewY extends ValueFloatModifier
{
}

@:modifier("fDark") class ModifierDark extends ValueFloatModifier
{
}

@:modifier("fBlind") class ModifierBlind extends ValueFloatModifier
{
}

@:modifier("fCover") class ModifierCover extends ValueFloatModifier
{
}

@:modifier("fRandomSpeed") class ModifierRandomSpeed extends ValueFloatModifier
{
}

@:modifier("fArrowPath") class ModifierArrowPath extends ValueFloatModifier
{
}

@:modifier("fArrowPathWidth") class ModifierArrowPathWidth extends ValueFloatModifier
{
}

@:modifier("xmod") class ModifierXmod extends ValueFloatModifier
{
}

@:modifier("fSpiralHolds") class ModifierSpiralHolds extends ValueFloatModifier
{
}

@:modifier("fStraightHolds") class ModifierStraightHolds extends ValueFloatModifier
{
}

@:modifier("fGrain") class ModifierGrain extends ValueFloatModifier
{
}

@:modifier("fGayHolds") class ModifierGayHolds extends ValueFloatModifier
{
}

@:modifier("bJimbleUseTan") class ModifierJimbleUseTan extends ValueBoolModifier
{
}

@:modifier("bZBuffer") class ModifierZBuffer extends ValueBoolModifier
{
}

@:modifier("bCosecant") class ModifierCosecant extends ValueBoolModifier
{
}

// @:modifier("fTimingScale") class ModifierJudgeScale extends ValueFloatModifier {}
// hscript specific stuff sorta
class ObjectModifier<T> extends ValueFloatModifier
{
	public var object:T;

	public function new(id:String, playerState:PlayerState, object:T)
	{
		super(id, playerState, false);
		this.object = object;
	}
}

// ok
// FlxObject
@:modifier("x", "object", false) class FlxObjectXModifier extends ObjectModifier<FlxObject>
{
}

@:modifier("y", "object", false) class FlxObjectYModifier extends ObjectModifier<FlxObject>
{
}

@:modifier("angle", "object", false) class FlxObjectAngleModifier extends ObjectModifier<FlxObject>
{
}

// FlxSprite
@:modifier("scale.x", "object", false) class FlxSpriteScaleXModifier extends ObjectModifier<FlxSprite>
{
}

@:modifier("scale.y", "object", false) class FlxSpriteScaleYModifier extends ObjectModifier<FlxSprite>
{
}

// FlxCamera
@:modifier("zoom", "object", false) class FlxCameraZoomModifier extends ObjectModifier<FlxCamera>
{
}

// PlayState
class PlayStateZoomModifier extends ObjectModifier<PlayState>
{
	override function get_value():Float
	{
		return object.defaultCamZoom;
	}

	override function set_value(v:Float):Float
	{
		object.defaultCamZoom = v;
		object.camGame.zoom = v;
		return v;
	}
}
