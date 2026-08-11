package modchart;

import funkin.game.Note;
import funkin.game.Splash;
import flixel.math.FlxMatrix;
import flixel.math.FlxAngle;
import flixel.math.FlxRect;
import flixel.graphics.tile.FlxDrawBaseItem;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.FlxGraphic;
import modchart.PlayFieldGraphics.HoldFrames;
import flixel.util.FlxPool;
import flixel.util.FlxPool.IFlxPooled;
import math.Vector3D;
import openfl.geom.Matrix3D;
import flixel.graphics.tile.FlxDrawQuadsItem;
import flixel.system.FlxAssets.FlxShader;
import modchart.ArrowEffects.Effect;
import openfl.geom.ColorTransform;

import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.group.FlxSpriteGroup;
import funkin.game.PlayState;

using flixel.util.FlxColorTransformUtil;

/**
 * Sorta lazy thing to draw notes and stuff instead of the main guys
 */
#if !modchart_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(flixel.graphics.tile.FlxDrawQuadsItem)
@:access(flixel.graphics.tile.FlxDrawTrianglesItem)
@:access(flixel.FlxSprite.drawComplex)
@:access(flixel.FlxCamera)
@:access(funkin.game.NoteGroup)
@:access(funkin.game.Note)
@:access(funkin.game.StrumLine)
@:access(funkin.game.PlayState)
final class NoteRenderer extends flixel.FlxBasic
{
	static inline final HOLD_SEGMENT_VERTICES = 2;
	static inline final HALF_SIZE = 160 * .7 * .5;
	static final SPLASH_HUES = [19.58, 22.28, 21.18, 18.42];

	public var graphics:PlayFieldGraphics = new PlayFieldGraphics();

	var shaders:Array<ModsShader> = [new ModsShader(), new ModsShader()];
	var simpleShader = new SimpleShader();

	// var simpleHoldShader = new SimpleShader(); // ????
	var ct = new ColorTransform();

	var game:PlayState;
	var mods:ArrowEffects;
	var modchart:Modchart;

	// lazy
	var holds:Vector<Array<HoldNote>>;
	var wavyHolds:Vector<Bool>;
	var splashes:Vector<Array<Splash>>;

	// got by `getArrowEffectsPos`
	var modPos = Vector3D.get();
	var modRot = Vector3D.get();
	var modZoom = Vector3D.get();
	var modSkew = FlxPoint.get();
	var modColor = FlxColor.WHITE;
	var modGlow = 0.0;
	var modDark = 0.0;
	var modYOffset = 0.0;

	// holds
	var modPos1 = Vector3D.get();
	var modRot1 = Vector3D.get();
	var modZoom1 = Vector3D.get();
	var modColor1 = FlxColor.WHITE;
	var modGlow1 = 0.0;

	var matrix3d:Matrix3D = new Matrix3D();
	var matrix:FlxMatrix = new FlxMatrix();

	var p = FlxPoint.get();
	var p2 = FlxPoint.get();
	var v3 = Vector3D.get();

	var perspective = new Perspective();

	var clippedFrame:FlxFrame;

	public function new(game:PlayState)
	{
		super();
		for (shader in shaders)
			shader.fov.value = [90.0];
		this.game = game;
		mods = new ArrowEffects(new NotePositionMetrics(), game.strumLines.length);

		// final luaPath = ''
		modchart = new Modchart(game.timeline, mods, "no");
		mods.active = modchart.active;

		holds = new Vector<Array<HoldNote>>(mods.players, true, [for (i in 0...mods.players) []]);
		wavyHolds = new Vector<Bool>(mods.players, true);
		splashes = new Vector<Array<Splash>>(mods.players, true, [for (i in 0...mods.players) []]);
	}

	public function getYOffset(pn:Int, column:Int, beat:Float, ms:Float):Float
	{
		final playerState = mods.playerStates[pn];
		mods.curr_options = playerState;
		playerState.curr_dir = column + 1;
		if (beat == mods.conductor.currentBeatTime)
		{
			final z = playerState.getZeroYOffset();
			if (z != null)
				return z;
		}
		return mods.getYOffset(playerState, column, beat, ms, false, !mods.active);
	}

	public function getArrowEffectsPos(pn:Int, beat:Float, ms:Float, column:Int, receptor:Bool, hold:Bool, ?yOffset:Float)
	{
		final playerState = mods.playerStates[pn];
		// basically the distance
		mods.curr_options = playerState;
		playerState.curr_dir = column + 1;
		yOffset ??= getYOffset(pn, column, beat, ms);
		modYOffset = yOffset;

		// basic get functions
		modPos.x = mods.getXPos(playerState, column, yOffset);
		modPos.y = mods.getYPos(playerState, column, yOffset, mods.position.reverseOffset, true);
		modPos.z = mods.getZPos(playerState, column, yOffset);

		if (receptor)
		{
			modDark = FlxMath.remapToRange(playerState.fDark + playerState.colDark[column], .5, 1, 1, 0).clamp(0, 1);
		}
		else
		{
			modGlow = 255 * mods.getGlow(playerState, column, yOffset, -1, mods.position.reverseOffset).clamp(-1, 1);
			modColor.alphaFloat = mods.getAlpha(playerState, column, yOffset, -1, mods.position.reverseOffset).clamp(-1, 1);
			modColor.redFloat = (1 - mods.getRedVisible(playerState, column, yOffset, -1, mods.position.reverseOffset)).clamp(-1, 1);
			modColor.greenFloat = (1 - mods.getGreenVisible(playerState, column, yOffset, -1, mods.position.reverseOffset)).clamp(-1, 1);
			modColor.blueFloat = (1 - mods.getBlueVisible(playerState, column, yOffset, -1, mods.position.reverseOffset)).clamp(-1, 1);
		}

		// dumb order cause we dont want holds rotating in those axis
		modRot.y = mods.getRotationY(playerState, yOffset, false, column) + playerState.splines.rotationy.getPercentage(yOffset, column);
		if (!hold)
		{
			modRot.x = -mods.getRotationX(playerState, yOffset, false, column) + playerState.splines.rotationx.getPercentage(yOffset, column);
			modRot.z = mods.getRotationZ(playerState, yOffset, false, column) + playerState.splines.rotationz.getPercentage(yOffset, column);
		}
		else
		{
			modRot.x = modRot.z = 0;
		}

		final miniZoom = FlxMath.remapToRange(playerState.fEffects(EFFECT_MINI), 0, 1, 1, .5);
		modZoom.w = (mods.getZoom(playerState, yOffset, column) * miniZoom) + playerState.splines.size.getPercentage(yOffset, column);
		modZoom.x = mods.getZoomX(playerState, yOffset, column);
		modZoom.y = mods.getZoomY(playerState, yOffset, column);
		modZoom.z = mods.getZoomZ(playerState, yOffset, column);
		modZoom *= modZoom.w;

		if (!hold)
		{
			modSkew.x = mods.getSkewX(playerState, yOffset, column) + playerState.splines.skew.getPercentage(yOffset, column);
			modSkew.y = mods.getSkewY(playerState, yOffset, column);
		}

		// move values
		modPos.x += (playerState.moveX + playerState.colMoveX[column] + playerState.splines.x.getPercentage(yOffset, column)) * ArrowEffects.ARROW_SIZE;
		modPos.y += (playerState.moveY + playerState.colMoveY[column] + playerState.splines.y.getPercentage(yOffset, column)) * ArrowEffects.ARROW_SIZE;
		modPos.z += (playerState.moveZ + playerState.colMoveZ[column] + playerState.splines.z.getPercentage(yOffset, column)) * ArrowEffects.ARROW_SIZE;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (mods.active)
		{
			mods.update(elapsed);
			modchart.update(elapsed);
		}
		for (pn in 0...2)
		{
			if (mods.active)
				wavyHolds[pn] = mods.needWavyHolds(mods.playerStates[pn]);
			for (hold in holds[pn])
			{
				if (mods.conductor.currentBeatTime >= hold.endBeat)
				{
					hold.put();
					holds[pn].remove(hold);
				}
			}
			#if debug
			FlxG.watch.addQuick('numHolds-$pn', holds[pn].length);
			FlxG.watch.addQuick('numSplashes-$pn', splashes[pn].length);
			FlxG.watch.addQuick('wavyHolds-$pn', wavyHolds[pn]);
			#end
		}
	}

	override function draw()
	{
		super.draw();

		for (pn => strumLine in game.strumLines.members)
		{
			for (camera in strumLine.cameras)
			{
				if (!camera.exists)
					continue;
				drawPlayField(camera, pn);
			}
		}
	}

	public function drawPlayField(camera:FlxCamera, pn:Int)
	{
		if (mods.active)
			playField(pn).updateMatrix();
		drawReceptors(camera, pn);
		drawHolds(camera, pn);
		drawArrows(camera, pn);
		drawSplashes(camera, pn);
	}

	// if the last calculated mod y offset is on screen
	inline function isTooClose(pn:Int):Bool
	{
		return modYOffset < playField(pn).drawDistanceMin;
	}

	inline function isTooFar(pn:Int):Bool
	{
		return modYOffset > playField(pn).drawDistanceMax;
	}

	inline function isOnScreen(pn:Int):Bool
	{
		return !isTooClose(pn) && !isTooFar(pn);
	}

	function drawReceptors(camera:FlxCamera, pn:Int)
	{
		for (col => receptor in strumLine(pn).members)
		{
			// update mod positions
			if (mods.active)
			{
				getArrowEffectsPos(pn, mods.conductor.currentBeatTime, mods.conductor.songPosition, col, true, false);

				if (!isOnScreen(pn))
					continue;
			}
			// its invisible
			// if (modDark == .0)
			//	continue;
			// update local matrix
			// updateLocalMatrix(receptor.origin);

			// apply darkness
			// receptor.colorTransform.alphaMultiplier = modDark;

			drawSprite(camera, pn, receptor, null);
		}
	}

	function drawHolds(camera:FlxCamera, pn:Int)
	{
		if (!mods.active)
			drawSimpleHolds(camera, pn);
		else
			drawModHolds(camera, pn);
	}

	function drawSimpleHolds(camera:FlxCamera, pn:Int)
	{
		for (note in holds[pn])
		{
			final r = game.strumLines.members[pn].members[note.column];
			final startY = note.hit ? .0 : -r.getDistance(note.note);
			final endY = -r.getDistance(note.note);
			var capY = endY - note.capHeight;
			final bodyHeight = capY - startY;

			// check if we are really gonna draw
			if (startY > playField(pn).drawDistanceMax || note.hit && bodyHeight < .0 && endY < .0 || !note.hit && bodyHeight < .0)
				continue;

			final aa = note.antialiasing;
			final drawItem = camera.startQuadBatch(note.graphic, false, false, null, aa, simpleShader);
			initDrawItem(pn, drawItem);

			ct.alphaMultiplier = note.note.alpha;

			// draw body
			if (bodyHeight > .0)
			{
				var frame = clippedFrame;
				if (frame == null || clippedFrame.parent != note.body.parent)
					frame = clippedFrame = note.body.copyTo(clippedFrame);
				else
					frame.frame.copyFrom(note.body.frame);
				frame.frame.top = -bodyHeight / note.scale; // it will make it wrap, and also have the top be clipped
				frame.frame.bottom = 0;
				// frame.uv.top = FlxMath.lerp(h.body.uv.top, h.body.uv.bottom, ratio);

				frame.prepareMatrix(matrix, FlxFrameAngle.ANGLE_0, false, false);
				matrix.translate(-frame.frame.width * .5, .0);
				matrix.scale(note.scale, note.scale);
				matrix.translate(.0, startY);
				matrix.translate(note.note.x + note.offset.x, r.y + note.offset.y);
				drawItem.addQuad(frame, matrix, ct);
				for (_ in 0...FlxDrawQuadsItem.VERTICES_PER_QUAD)
					pushRGBHueColor(null, 0, drawItem);
			}

			// draw cap
			// but dont if cap is offscreen
			if (endY > playField(pn).drawDistanceMax)
				continue;

			var frame = clippedFrame;
			if (frame == null || clippedFrame.parent != note.cap.parent)
				frame = clippedFrame = note.cap.copyTo(clippedFrame);
			else
				frame.frame.copyFrom(note.cap.frame);
			if (bodyHeight < .0)
			{
				frame.frame.top = (note.capHeight - endY) / note.scale;
				capY = .0;
			}
			// frame.uv.top = FlxMath.lerp(h.body.uv.top, h.body.uv.bottom, ratio);

			if (frame.frame.height > .0)
			{
				frame.prepareMatrix(matrix, FlxFrameAngle.ANGLE_0, false, false);
				matrix.translate(-frame.frame.width * .5, .0);
				matrix.scale(note.scale, note.scale);
				matrix.translate(.0, capY);
				matrix.translate(note.note.x + note.offset.x, r.y + note.offset.y);
				drawItem.addQuad(frame, matrix, ct);
				for (_ in 0...FlxDrawQuadsItem.VERTICES_PER_QUAD)
					pushRGBHueColor(null, 0, drawItem);
			}
			else
			{
				// cancel draw item
				// nvm idk how it works
			}
		}
	}

	function drawModHolds(camera:FlxCamera, pn:Int)
	{
		for (note in holds[pn])
		{
			final clip = note.hit;
			final item = camera.startTrianglesBatch(note.graphic, note.antialiasing, true, null, true, shaders[pn]);
			item.colorMultipliers ??= [];
			item.colorOffsets ??= [];
			var numVertices = item.numVertices;
			initDrawItem(pn, item);
			// item.modsShader = null;
			// item.shader = null;

			final zeroOffset = !clip ? .0 : getYOffset(pn, note.column, mods.conductor.currentBeatTime, mods.conductor.songPosition);

			final startYOffset = clip ? zeroOffset : getYOffset(pn, note.column, note.startBeat, note.startMs);
			final endYOffset = getYOffset(pn, note.column, note.endBeat, note.endMs);

			if (endYOffset < startYOffset && clip)
				continue;

			final dist = endYOffset - startYOffset;
			final bodyDist = dist - note.capHeight;
			final endRatio = bodyDist / dist;

			final capBeat = FlxMath.lerp(clip ? mods.conductor.currentBeatTime : note.startBeat, note.endBeat, endRatio);
			final capMs = FlxMath.lerp(clip ? mods.conductor.songPosition : note.startMs, note.endMs, endRatio);
			final capYOffset = FlxMath.lerp(startYOffset, endYOffset, endRatio);
			final drawBody = !clip || capYOffset > zeroOffset;

			// inline function distanceUvt(dist:Float)
			// {
			//	return FlxMath.remapToRange(dist, 0, -note.bodyHeight * note.body.offset.y, note.bodyUV.bottom, note.bodyUV.top);
			// }

			// final totalV = distanceUvt(bodyDist);

			modYOffset = startYOffset;

			var i = 0;
			// the stupid version
			inline function drawPart(startBeat:Float, endBeat:Float, startMs:Float, endMs:Float, segments:Float, cap:Bool)
			{
				var startV = .0;
				if (clip && startBeat <= mods.conductor.currentBeatTime)
					startV = FlxMath.bound(Math.abs(capYOffset - startYOffset) / note.capHeight, 0.0, 1.0);
				final uv = cap ? note.capUV : note.bodyUV;
				final halfU = cap ? note.capHalfU : note.bodyHalfU;
				final halfWidth = cap ? note.capHalfWidth : note.bodyHalfWidth;

				inline function pushVertices()
				{
					item.vertices.pushr( //
						HALF_SIZE - halfWidth, HALF_SIZE, // left
						// HALF_SIZE, 				HALF_SIZE, // center (we dont actually need it)
						HALF_SIZE + halfWidth, HALF_SIZE, // right
					);
				}

				final iStart = i;
				do
				{
					final isEnd = i - iStart + 1 >= segments;
					final t = (i - iStart) / segments;
					final t2 = Math.min(1.0, (i - iStart + 1) / segments);
					final beat = FlxMath.lerp(startBeat, endBeat, t);
					final beat2 = FlxMath.lerp(startBeat, endBeat, t2);
					final ms = FlxMath.lerp(startMs, endMs, t);
					final ms2 = FlxMath.lerp(startMs, endMs, t2);

					if (i == iStart)
						getArrowEffectsPos(pn, beat, ms, note.column, false, true);
					if (isTooFar(pn))
						break;

					final v = if (cap) //
						FlxMath.lerp(FlxMath.lerp(uv.top, uv.bottom, startV), uv.bottom, t); //
					else //
						FlxMath.remapToRange(modYOffset - endYOffset, -note.bodyHeight, 0, note.bodyUV.bottom, note.bodyUV.top); //

					modPos1.copyFrom(modPos);
					modRot1.copyFrom(modRot);
					modZoom1.copyFrom(modZoom);
					modColor1 = modColor;
					modGlow1 = modGlow;

					getArrowEffectsPos(pn, beat2, ms2, note.column, false, true);

					// if (isTooFar(pn))
					//	break;

					// spiral holds
					modRot.x += spiralHolds2D(pn, p.set(modPos.z, modPos.y), p2.set(modPos1.z, modPos1.y));
					modRot.y += spiralHolds2D(pn, p.set(modPos.x, modPos.z), p2.set(modPos1.x, modPos1.z));
					modRot.z += spiralHolds2D(pn, p.set(modPos.x, modPos.y), p2.set(modPos1.x, modPos1.y));

					final v2 = if (cap) //
						FlxMath.lerp(FlxMath.lerp(uv.top, uv.bottom, startV), uv.bottom, t2); //
					else //
						FlxMath.remapToRange(modYOffset - endYOffset, -note.bodyHeight, 0, note.bodyUV.bottom, note.bodyUV.top); //

					pushVertices();
					pushVertices();

					// bad

					item.uvtData.pushr( //
						uv.left, v, // left
						// halfU, v, // center
						uv.right, v, // right
						uv.left, v2, // left 2
						// halfU, v2, // center 2
						uv.right, v2, // right 2
					);

					{
						final ip = numVertices;
						item.indices.pushr( //
							ip + 0, ip + 1, ip + 2, ip + 1, ip + 2, ip + 3,);

						// stupidness ultimate
						inline function push()
						{
							pushPoint(item.localOrigin, p.set(HALF_SIZE, HALF_SIZE));
							pushPoint(item.localOrigin, p.set());
							pushVector3D(item.localSkew, v3);
							pushRGBHueColor(null, 0, item);
						}

						inline function push1()
						{
							push();
							pushVector3D(item.localPosition, modPos1);
							pushVector3D(item.localRotation, modRot1);
							pushVector3D(item.localZoom, modZoom1);
							item.alphas.pushr(0.6 * modColor1.alphaFloat);
							pushModColor(item.colorMultipliers, modColor1);
							pushGlow(item.colorOffsets, modGlow1);
						}

						inline function push2()
						{
							push();
							pushVector3D(item.localPosition, modPos);
							pushVector3D(item.localRotation, modRot);
							pushVector3D(item.localZoom, modZoom);
							item.alphas.pushr(0.6 * modColor.alphaFloat);
							pushModColor(item.colorMultipliers, modColor);
							pushGlow(item.colorOffsets, modGlow);
						}

						// basically fuck the sequel
						push1();
						push1();
						push2();
						push1();
						push2();
						push2();

						// if (isEnd)
						// {
						//	pushOurFriend();
						// }
					}

					i++;
					numVertices += 4;

					if (isEnd)
						break;
					// if (!pushIndices)
					//	break;
				}
				while (true);
			}
			// if we dont need to, just render holds with 4 segments total
			final grain = wavyHolds[pn] ? mods.playerStates[pn].fGrain : 512;
			if (drawBody)
				drawPart(clip ? mods.conductor.currentBeatTime : note.startBeat, capBeat, clip ? mods.conductor.songPosition : note.startMs, capMs, bodyDist / grain,
					false);
			drawPart(clip ? Math.max(capBeat, mods.conductor.currentBeatTime) : capBeat, note.endBeat,
				clip ? Math.max(capMs, mods.conductor.songPosition) : capMs, note.endMs, note.capHeight / grain, true);
			// FlxG.watch.addQuick("vertices", item.vertices);
			// FlxG.watch.addQuick("verticesLen", item.vertices.length);
			// FlxG.watch.addQuick("uvtData", item.uvtData);
			// FlxG.watch.addQuick("uvtDataLen", item.uvtData.length);
			// FlxG.watch.addQuick("indices", item.indices);
			// FlxG.watch.addQuick("indicesLen", item.indices.length);
			// FlxG.watch.addQuick("localZoom", item.localZoom);
			// FlxG.watch.addQuick("localPositionLen", item.localPosition.length);
			// FlxG.watch.addQuick("colorMultipliers", item.colorMultipliers);
			// FlxG.watch.addQuick("colorMultipliersLen", item.colorMultipliers.length);
			// FlxG.watch.addQuick("r", item.r);
			// FlxG.watch.addQuick("rLen", item.r.length);
		}
	}

	function drawArrows(camera:FlxCamera, pn:Int)
	{
		final strumLine = strumLine(pn);
		final ng = strumLine.notes;

		final oldCur = ng.__currentlyLooping;
		ng.__currentlyLooping = true;

		var i = ng.length;
		while (i > 0)
		{
			final note = ng.__loopSprite = ng.members[--i];
			// update mod positions (or not)
			if (mods.active)
				getArrowEffectsPos(pn, note.beatTime, note.strumTime, note.noteData, false, false);
			else
				modYOffset = note.y; // with relative pos the y is just the distance

			// better draw distance based on pixel distance rather than song distance
			if (isTooClose(pn))
				continue;
			else if (isTooFar(pn))
				break;
			// its invisible
			// if (modDark == .0)
			//	continue;
			// update local matrix
			// updateLocalMatrix(receptor.origin);
	
			// apply colors
			if (mods.active)
			{
				note.colorTransform.setMultipliers(1 - modColor.redFloat, 1 - modColor.greenFloat, 1 - modColor.blueFloat, modColor.alphaFloat);
				final ofs = modGlow * 255.;
				note.colorTransform.setOffsets(ofs, ofs, ofs, .0);
			}
	
			final originalX = note.x;
			final originalY = note.y;
			note.applyStrumPos();
			drawSprite(camera, pn, note, null);
			note.x = originalX;
			note.y = originalY;
		}
		ng.__currentlyLooping = oldCur;
	}

	function drawSprite(camera:FlxCamera, pn:Int, sprite:FlxSprite, rgbColor:Null<RGBColor> = null, hue:Float = .0)
	{
		// override shader
		sprite.shader = mods.active ? shaders[pn] : simpleShader;

		if (mods.active)
		{
			// force pos and offset to 0 for our custom pos and then draw
			sprite.offset.copyTo(p);
			sprite.offset.set();
			sprite.setPosition(0, 0);
			sprite.drawComplex(camera);
			sprite.offset.copyFrom(p);
		}
		else
		{
			sprite.drawComplex(camera);
		}

		// push our custom stuff
		final item = camera._headTiles;
		initDrawItem(pn, item);

		for (_ in 0...FlxDrawQuadsItem.VERTICES_PER_QUAD)
		{
			pushRGBHueColor(rgbColor, hue, item);

			if (mods.active)
			{
				// its a vec4 im justpacking them together cause it was being weird when they were seperate
				pushPoint(item.localOrigin, sprite.origin);
				pushPoint(item.localOrigin, p);

				pushVector3D(item.localPosition, modPos);
				pushVector3D(item.localRotation, modRot);
				pushVector3D(item.localZoom, modZoom);
			}
		}
	}

	function pushRGBHueColor<T>(rgbColor:RGBColor, hue:Float, item:FlxDrawBaseItem<T>)
	{
		//if (rgbColor != null && rgbColor.mix > .0)
		//{
		//	pushColor(item.r, rgbColor.r);
		//	pushColor(item.g, rgbColor.g);
		//	pushColor(item.b, rgbColor.b);
		//	item.rgbMix.push(rgbColor.mix);
		//}
		//else
		//{
		//	pushColor(item.r, FlxColor.RED);
		//	pushColor(item.g, FlxColor.GREEN);
		//	pushColor(item.b, FlxColor.BLUE);
		//	item.rgbMix.push(0.0);
		//}
		item.hue.push(hue);
	}

	function drawSplashes(camera:FlxCamera, pn:Int)
	{
		for (splash in splashes[pn])
		{
			// update mod positions
			getArrowEffectsPos(pn, mods.conductor.currentBeatTime, mods.conductor.songPosition, splash.strum.ID, true, false);
			if (!isOnScreen(pn))
				continue;
			// its invisible
			// if (modDark == .0)
			//	continue;
			// update local matrix
			// updateLocalMatrix(receptor.origin);

			// apply darkness
			// receptor.colorTransform.alphaMultiplier = modDark;

			drawSprite(camera, pn, splash, null, SPLASH_HUES[splash.strum.ID]);
		}
	}

	function initDrawItem<T>(pn:Int, item:FlxDrawBaseItem<T>)
	{
		if (item.playFieldTransform.length > 0)
			return;
		if (!mods.active)
		{
			item.simpleShader = simpleShader;
		}
		else
		{
			item.modsShader = shaders[pn];
			pushMatrix(item.playFieldTransform, playField(pn).matrix);
			v3.copyFrom(playField(pn).pos);
			v3.z = 0;
			pushVector3D(item.playFieldPos, v3);
			item.fov = playField(pn).fov;

			pushVector3D(item.depthStuff, v3.set(perspective.__depthScale, perspective.__depthOffset, perspective.__tanHalfFov));
		}
	}

	inline function playField(pn:Int)
	{
		return mods.playerStates[pn].playField;
	}

	// get our codenames i dont like codenames
	inline function strumLine(pn:Int)
	{
		return game.strumLines.members[pn];
	}

	inline function pushColor(arr:Array<Float>, color:FlxColor)
	{
		arr.pushr(color.redFloat, color.greenFloat, color.blueFloat);
	}

	inline function pushModColor(arr:Array<Float>, color:FlxColor)
	{
		arr.pushr(1.0 - color.redFloat, 1.0 - color.greenFloat, 1.0 - color.blueFloat, 1.0);
	}

	inline function pushGlow(arr:Array<Float>, glow:Float)
	{
		glow *= 255.;
		arr.pushr(glow, glow, glow, 0);
	}

	inline function pushColorOffset(offset:Int, arr:Array<Float>, color:FlxColor)
	{
		arr.setRestOffset(offset, color.redFloat, color.greenFloat, color.blueFloat);
	}

	inline function pushMatrix(arr:Array<Float>, matrix:Matrix3D)
	{
		final len = arr.length;
		// convert OpenF Lmatrix to Float32Array
		// why?
		// no wait i understand why i think
		var p = 0;
		for (i in 0...16)
		{
			arr[len + p] = matrix.rawData[i];
			p += 4;
			if (p >= 16)
				p -= 15;
		}
	}

	inline function pushPoint(arr:Array<Float>, p:FlxPoint)
	{
		arr.pushr(p.x, p.y);
	}

	inline function pushVector3D(arr:Array<Float>, vec:Vector3D)
	{
		arr.pushr(vec.x, vec.y, vec.z);
	}

	inline function pushPointOffset(offset:Int, arr:Array<Float>, p:FlxPoint)
	{
		arr.setRestOffset(offset, p.x, p.y);
	}

	inline function pushVector3DOffset(offset:Int, arr:Array<Float>, vec:Vector3D)
	{
		arr.setRestOffset(offset, vec.x, vec.y, vec.z);
	}

	static final HALF_PI = Math.PI * .5;

	inline function spiralHolds2D(pn:Int, a:FlxPoint, b:FlxPoint):Float
	{
		final spiral = mods.playerStates[pn].fSpiralHolds;
		if (spiral == 0 || a.equals(b))
		{
			return 0;
		}
		else
		{
			return (FlxAngle.radiansFromOrigin(b.x - a.x, b.y - a.y) + HALF_PI) * spiral;
		}
	}

	public inline function splashAdded(splash:Splash)
	{
		splashes[splash.strum.strumLine.ID].push(splash);
	}

	public inline function splashKilled(splash:Splash)
	{
		splashes[splash.strum.strumLine.ID].remove(splash);
	}

	override function destroy()
	{
		super.destroy();
		mods = FlxDestroyUtil.destroy(mods);
		modchart = FlxDestroyUtil.destroy(modchart);
	}
}

class HoldNote implements IFlxPooled
{
	static final pool = new FlxPool<HoldNote>(HoldNote /*.new*/); // DAVE TODO: davealicious

	public var graphic:FlxGraphic;
	public var holdFrames:HoldFrames;

	public var hit(get, never):Bool;

	inline function get_hit()
		return note.wasGoodHit;

	public var startBeat:Float;
	public var startMs:Float;
	public var endBeat:Float;
	public var endMs:Float;
	public var column:Int;

	public var body:FlxFrame;
	public var bodyUV:FlxUVRect;
	public var bodyHalfU:Float;
	public var bodyWidth:Float;
	public var bodyHalfWidth:Float;
	public var bodyHeight:Float;

	public var cap:FlxFrame;
	public var capUV:FlxUVRect;
	public var capHalfU:Float;
	public var capWidth:Float;
	public var capHalfWidth:Float;
	public var capHeight:Float;

	public var antialiasing:Bool;

	public var note:Note;

	public var scale:Float;

	public var offset:FlxPoint;

	public static function get(note:Note)
	{
		final n = pool.get();
		n.init(note);
		return n;
	}

	function init(note:Note)
	{
		this.note = note;
		scale = note.scale.x;
		body = note.bodyFrame;
		bodyUV = cast body.uv;
		cap = note.capFrame;
		capUV = cast cap.uv;
		graphic = body.parent;
		startBeat = note.beatTime;
		startMs = note.strumTime;
		endBeat = note.beatEndTime;
		endMs = note.endTime;
		column = note.noteData;
		antialiasing = note.antialiasing;

		bodyHalfU = FlxMath.lerp(bodyUV.left, bodyUV.right, .5);

		bodyWidth = body.sourceSize.x * note.scale.x;
		bodyHalfWidth = bodyWidth * .5;
		bodyHeight = body.sourceSize.y * note.scale.y;

		capHalfU = FlxMath.lerp(capUV.left, capUV.right, .5);

		capWidth = body.sourceSize.x * note.scale.x;
		capHalfWidth = bodyWidth * .5;
		capHeight = body.sourceSize.y * note.scale.y;

		offset = FlxPoint.get(bodyHalfWidth, Note.swagWidth * .5);
	}

	function new()
	{
	}

	public function put()
	{
		pool.put(this);
	}

	public function destroy()
	{
		holdFrames = null;
		note = null;
		offset = FlxDestroyUtil.put(offset);
	}
}

/**
 * Dumb
 */
class SimpleShader extends FlxShader
{
	@:glVertexSource('
		#pragma header
	
		attribute vec3 r;
		attribute vec3 g;
		attribute vec3 b;
		attribute float rgb_mix;
		attribute float hue;
	
		varying vec3 _r;
		varying vec3 _g;
		varying vec3 _b;
		varying float _rgb_mix;
		varying float _hue;

		void main()
		{
			#pragma body
			_r = r;
			_g = g;
			_b = b;
			_rgb_mix = rgb_mix;
		}
	')
	@:glFragmentSource('
		#pragma header
	
		varying vec3 _r;
		varying vec3 _g;
		varying vec3 _b;
		varying float _rgb_mix;
		varying float _hue;

		vec3 hueShift(vec3 col, float hue) 
		{
			const vec3 k = vec3(0.57735, 0.57735, 0.57735);
			float cosAngle = cos(hue);
			return vec3(col * cosAngle + cross(k, col) * sin(hue) + k * dot(k, col) * (1.0 - cosAngle));
		}

		void main() 
		{
			vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);

			vec4 new_color = color;
			//new_color.rgb = mix(color.rgb, min(color.r * _r + color.g * _g + color.b * _b, vec3(color.a)), _rgb_mix);
			//new_color.a = color.a;
			gl_FragColor = new_color; // vec4(hueShift(new_color.rgb, _hue), new_color.a);
		}')
	public function new()
	{
		super();
		bitmap.wrap = REPEAT;
	}
}

/**
 * Combination of an rgb shader and a perspective shader thing
 */
class ModsShader extends FlxShader
{
	@:glVertexSource('
		#pragma header

		#define PI 3.14159265359
		#define TO_RAD PI / 180.0
		#define TO_DEG 180.0 / PI

		const vec3 X_AXIS = vec3(1.0, 0.0, 0.0);
		const vec3 Y_AXIS = vec3(0.0, 1.0, 0.0);
		const vec3 Z_AXIS = vec3(0.0, 0.0, 1.0);
	
		attribute vec3 r;
		attribute vec3 g;
		attribute vec3 b;
		attribute float rgb_mix;
		attribute float hue;

		attribute vec3 localRotation;
		attribute vec3 localZoom;
		attribute vec3 localPosition;
		attribute vec2 localSkew;
		attribute vec4 localOrigin;

		uniform mat4 playFieldTransform;
		uniform vec3 playFieldPos;
		uniform vec3 depthStuff;
		
		const float far = 100.;
		const float near = 0.1;
		uniform float fov;
		const float aspect = 1280.0/720.0;
	
		varying vec3 _r;
		varying vec3 _g;
		varying vec3 _b;
		varying float _rgb_mix;
		varying float _hue;
		varying float depth;

		// Rotation matrix around the X axis.
		mat3 rotateX(float theta) 
		{
			float c = cos(theta);
			float s = sin(theta);
			return mat3(
				vec3(1, 0, 0),
				vec3(0, c, -s),
				vec3(0, s, c)
			);
		}

		// Rotation matrix around the Y axis.
		mat3 rotateY(float theta) 
		{
			float c = cos(theta);
			float s = sin(theta);
			return mat3(
				vec3(c, 0, s),
				vec3(0, 1, 0),
				vec3(-s, 0, c)
			);
		}

		// Rotation matrix around the Z axis.
		mat3 rotateZ(float theta) 
		{
			float c = cos(theta);
			float s = sin(theta);
			return mat3(
				vec3(c, -s, 0),
				vec3(s, c, 0),
				vec3(0, 0, 1)
			);
		}

		void main()
		{
			#pragma body

			vec4 pos = openfl_Position;
			pos.xy -= localOrigin.xy; // origin
			pos.xyz *= rotateX(TO_RAD * localRotation.x);
			pos.xyz *= rotateY(TO_RAD * localRotation.y);
			pos.xyz *= rotateZ(TO_RAD * localRotation.z);
			pos = (((pos * vec4(localZoom, 1.0)) + vec4(localPosition, 0.0)) * playFieldTransform);
			pos.xy += localOrigin.xy; // origin
			pos.xy -= localOrigin.zw; // offset
			
			
			// yes this is just the shitty funkin modchart projection but here instead cause im too stupid to use a matrix
			float projectedZ = depthStuff.x * min((pos.z / 1280.) - 1.0, 0.0) + depthStuff.y;
			float projectedFov = (depthStuff.z / projectedZ);
			pos.xy *= projectedFov;
			pos.z = projectedZ;
			depth = projectedZ;

			gl_Position = openfl_Matrix * (pos + vec4(playFieldPos, 0.0));
			_r = r;
			_g = g;
			_b = b;
			_rgb_mix = rgb_mix;
			_hue = hue;
		}
	')
	@:glFragmentSource('
		#pragma header
	
		varying vec3 _r;
		varying vec3 _g;
		varying vec3 _b;
		varying float _rgb_mix;
		varying float _hue;
		varying float depth;

		vec3 hueShift(vec3 col, float hue) 
		{
			const vec3 k = vec3(0.57735, 0.57735, 0.57735);
			float cosAngle = cos(hue);
			return vec3(col * cosAngle + cross(k, col) * sin(hue) + k * dot(k, col) * (1.0 - cosAngle));
		}

		void main() 
		{
			vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);

			vec4 new_color = color;
			//new_color.rgb = mix(color.rgb, min(color.r * _r + color.g * _g + color.b * _b, vec3(color.a)), _rgb_mix);
			//new_color.a = color.a;
			gl_FragColor = vec4(hueShift(new_color.rgb, _hue), new_color.a);
			gl_FragDepth = depth; // fix warping i think??
		}')
	public function new()
	{
		super();
		bitmap.wrap = REPEAT;
	}
}

// from later versions of flixel

@:forward(put)
abstract FlxUVRect(FlxRect) from FlxRect to flixel.util.FlxPool.IFlxPooled
{
	public var left(get, set):Float;

	inline function get_left():Float
	{
		return this.x;
	}

	inline function set_left(value):Float
	{
		return this.x = value;
	}

	/** Top */
	public var right(get, set):Float;

	inline function get_right():Float
	{
		return this.width;
	}

	inline function set_right(value):Float
	{
		return this.width = value;
	}

	/** Right */
	public var top(get, set):Float;

	inline function get_top():Float
	{
		return this.y;
	}

	inline function set_top(value):Float
	{
		return this.y = value;
	}

	/** Bottom */
	public var bottom(get, set):Float;

	inline function get_bottom():Float
	{
		return this.height;
	}

	inline function set_bottom(value):Float
	{
		return this.height = value;
	}

	public inline function set(l, t, r, b)
	{
		this.set(l, t, r, b);
	}

	public inline function copyTo(uv:FlxUVRect)
	{
		uv.set(left, top, right, bottom);
	}

	public inline function copyFrom(uv:FlxUVRect)
	{
		set(uv.left, uv.top, uv.right, uv.bottom);
	}

	// public inline function toString()
	// {
	//	return return FlxStringUtil.getDebugString([
	//		LabelValuePair.weak("l", left),
	//		LabelValuePair.weak("t", top),
	//		LabelValuePair.weak("r", right),
	//		LabelValuePair.weak("b", bottom)
	//	]);
	// }

	public static function get(l = 0.0, t = 0.0, r = 0.0, b = 0.0)
	{
		return FlxRect.get(l, t, r, b);
	}
}
