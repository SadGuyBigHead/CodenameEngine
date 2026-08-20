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
using util.ColorTransformTools;

/**
 * Sorta lazy thing to draw notes and stuff instead of the main guys
 * 
 * Broken things:
 * - holds that go backwards go crazy
 * - holds with appearance mods only fade nicely on enter and snap when becoming not white idk just try it and see for yourself
 * - gotta adjust fade distance its just bad right now
 * - centering holds is just kinda annoying and random
 * - spiralholds is buggy and rotates around the top of a note instead of the middle
 * - adding onto that having holds starting at the center should be done better in general i think??
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
		mods = new ArrowEffects(new NotePositionMetrics(), game.strumLines.length, game.conductor);

		// final luaPath = ''
		modchart = new Modchart(game.timeline, mods, "songs/" + PlayState.SONG.meta.name + "/modchart.lua");
		mods.active = modchart.active;

		wavyHolds = new Vector<Bool>(mods.players, true);
		splashes = new Vector<Array<Splash>>(mods.players, true, [for (i in 0...mods.players) []]);
	}

	public function getYOffset(pn:Int, column:Int, beat:Float, ms:Float):Float
	{
		final playerState = mods.playerStates[pn];
		mods.curr_options = playerState;
		playerState.curr_dir = column + 1;
		if (beat == mods.conductor.curBeatFloat)
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
			#if debug
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
			if (!strumLine.visible)
				continue;
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
		drawHoldCovers(camera, pn);
		drawArrows(camera, pn);
		drawSplashes(camera, pn);
	}

	// if the last calculated mod y offset is on screen
	inline function isTooClose(pn:Int):Bool
	{
		return modYOffset < strumLine(pn).drawDistanceMin;
	}

	inline function isTooFar(pn:Int):Bool
	{
		return modYOffset > strumLine(pn).drawDistanceMax;
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
				getArrowEffectsPos(pn, mods.conductor.curBeatFloat, mods.conductor.songPosition, col, true, false);

				if (modDark <= 0.0 || !isOnScreen(pn))
					continue;
			}

			// apply colors
			receptor.colorTransform.copyTo(ct);
			receptor.colorTransform.alphaMultiplier *= modDark;
			drawSprite(camera, pn, receptor, null);
			ct.copyTo(receptor.colorTransform);
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
		// messy ill make it better later i just want it to work right now
		final strumLine = strumLine(pn);
		final ng = strumLine.notes;

		final oldCur = ng.__currentlyLooping;
		ng.__currentlyLooping = true;

		var i = ng.length - 1;
		while (i >= 0)
		{
			final note = ng.__loopSprite = ng.members[i--];
			if (!note?.exists)
				continue;
			// since holds are drawn first we always update these values no matter what
			note.__distance = note.strum.getDistance(note);
			note.__dark = getMissDark(note);
			note.colorTransform.setOffsets(note.__dark, note.__dark, note.__dark, 0);

			if (note.__distance > strumLine.drawDistanceMax)
				break;
			else if (note.hold.invalid || note.sustainLength <= 0 || note.held && mods.conductor.songPosition > note.endTime)
				continue;
			final hold = note.hold;

			final startY = (note.held ? .0 : note.__distance);
			final endY = note.strum.getDistance(note, hold.endMs);

			var capY = endY - hold.capHeight;
			final bodyHeight = capY - startY;

			// check if we are really gonna draw
			if (hold.hit && endY < .0 || !hold.hit && bodyHeight < .0)
				continue;

			final originalX = note.x;
			final originalY = note.y;
			note.applyStrumPos();

			final aa = hold.antialiasing;
			final drawItem = camera.startQuadBatch(hold.graphic, note.colorTransform.hasRGBMultipliers(), note.colorTransform.hasRGBAOffsets(), null, aa,
				simpleShader);
			initDrawItem(pn, drawItem);

			// draw body
			if (bodyHeight > .0)
			{
				var frame = clippedFrame;
				if (frame == null || clippedFrame.parent != hold.body.parent)
					frame = clippedFrame = hold.body.copyTo(clippedFrame);
				else
					frame.frame.copyFrom(hold.body.frame);
				frame.frame.top = -bodyHeight / hold.scale; // it will make it wrap, and also have the top be clipped
				frame.frame.bottom = 0;
				// frame.uv.top = FlxMath.lerp(h.body.uv.top, h.body.uv.bottom, ratio);

				// temoparaorely offset the stored matrix
				final x:Float = note.x;
				final y:Float = startY + note.strum.y;
				hold.bodyMatrix.tx += x;
				hold.bodyMatrix.ty += y;
				drawItem.addQuad(frame, hold.bodyMatrix, note.colorTransform);
				hold.bodyMatrix.tx -= x;
				hold.bodyMatrix.ty -= y;
				for (_ in 0...FlxDrawQuadsItem.VERTICES_PER_QUAD)
					pushRGBHueColor(null, 0, drawItem);
			}

			// draw cap
			// but dont if cap is offscreen
			if (endY <= strumLine.drawDistanceMax)
			{
				var frame = clippedFrame;
				if (frame == null || clippedFrame.parent != hold.cap.parent)
					frame = clippedFrame = hold.cap.copyTo(clippedFrame);
				else
					frame.frame.copyFrom(hold.cap.frame);
				if (bodyHeight < .0)
				{
					frame.frame.top = (hold.capHeight - endY) / hold.scale;
					capY = .0;
				}
				// frame.uv.top = FlxMath.lerp(h.body.uv.top, h.body.uv.bottom, ratio);

				if (frame.frame.height > .0)
				{
					// temoparaorely offset the stored matrix
					final x:Float = note.x;
					final y:Float = capY + note.strum.y;
					hold.capMatrix.tx += x;
					hold.capMatrix.ty += y;
					drawItem.addQuad(frame, hold.capMatrix, note.colorTransform);
					hold.capMatrix.tx -= x;
					hold.capMatrix.ty -= y;

					for (_ in 0...FlxDrawQuadsItem.VERTICES_PER_QUAD)
						pushRGBHueColor(null, 0, drawItem);
				}
			}

			note.x = originalX;
			note.y = originalY;
		}
		ng.__currentlyLooping = oldCur;
	}

	function drawModHolds(camera:FlxCamera, pn:Int)
	{
		// messy ill make it better later i just want it to work right now
		final strumLine = strumLine(pn);
		final ng = strumLine.notes;

		final oldCur = ng.__currentlyLooping;
		ng.__currentlyLooping = true;

		var i = ng.length - 1;
		while (i >= 0)
		{
			final note = ng.__loopSprite = ng.members[i--];
			if (!note?.exists)
				continue;
			// now, get distance from y offset!
			note.__distance = getYOffset(pn, note.noteData, note.beatTime, note.strumTime);
			note.__dark = getMissDark(note);

			if (note.__distance > strumLine.drawDistanceMax)
				break;
			else if (note.hold.invalid || note.sustainLength <= 0 || note.held && mods.conductor.songPosition > note.endTime)
				continue;
			final hold = note.hold;
			final clip = note.held;

			final startYOffset = (clip ? getYOffset(pn, hold.column, mods.conductor.curBeatFloat, mods.conductor.songPosition) : note.__distance);
			final endYOffset = getYOffset(pn, hold.column, hold.endBeat, hold.endMs);

			final dist = endYOffset - startYOffset;
			final bodyDist = dist - hold.capHeight;
			final endRatio = bodyDist / dist;

			final capBeat = FlxMath.lerp(clip ? mods.conductor.curBeatFloat : hold.startBeat, hold.endBeat, endRatio);
			final capMs = FlxMath.lerp(clip ? mods.conductor.songPosition : hold.startMs, hold.endMs, endRatio);
			final capYOffset = FlxMath.lerp(startYOffset, endYOffset, endRatio);

			final capClip = -Math.min(0, bodyDist);
			final realCapHeight = hold.capHeight - capClip;

			final drawBody = !clip || capYOffset > startYOffset;

			// check if we are really gonna draw
			if (hold.hit && !drawBody && endYOffset < .0 || !hold.hit && !drawBody)
				continue;

			final aa = hold.antialiasing;
			// todo: detect when we need color mults or offsets
			final drawItem = camera.startQuadBatch(hold.graphic, true, true, null, aa, simpleShader);
			initDrawItem(pn, drawItem);

			modYOffset = startYOffset;

			// the stupid version
			inline function drawPart(segments:Float, cap:Bool)
			{
				final startBeat = if (!cap) //
					clip ? mods.conductor.curBeatFloat : hold.startBeat; //
				else //
					clip ? Math.max(capBeat, mods.conductor.curBeatFloat) : capBeat; //

				final endBeat = if (!cap) //
					capBeat; //
				else //
					hold.endBeat; //

				final startMs = if (!cap) //
					clip ? mods.conductor.songPosition : hold.startMs; //
				else //
					clip ? Math.max(capMs, mods.conductor.songPosition) : capMs; //

				final endMs = if (!cap) //
					capMs; //
				else //
					hold.endMs; //

				// var startV = .0;
				// if (clip && start <= mods.conductor.curBeatFloat)
				//	startV = FlxMath.bound(Math.abs(capYOffset - startYOffset) / hold.capHeight, 0.0, 1.0);

				final sourceFrame = cap ? hold.cap : hold.body;

				var frame = clippedFrame;
				if (frame == null || clippedFrame.parent != sourceFrame.parent)
					frame = clippedFrame = sourceFrame.copyTo(clippedFrame);
				else
					frame.frame.copyFrom(sourceFrame.frame);
				frame.frame.y = frame.frame.height = 0;

				final mat = cap ? hold.capMatrix : hold.bodyMatrix;

				inline function updateDrawInfo()
				{
					// get spiral holds
					modPos.y += ArrowEffects.ARROW_SIZE_HALF;
					//final angleX = spiralHolds2D(pn, p.set(modPos.z, modPos.y), p2.set(v3.z, v3.y));
					//final angleY = spiralHolds2D(pn, p.set(modPos.x, modPos.z), p2.set(v3.x, v3.z)) + modRot.y;
					final angleZ = spiralHolds2D(pn, p.set(modPos.x, modPos.y), p2.set(v3.x, v3.y));

					matrix3d.identity();
					// basically flatten out the point vertically
					matrix3d.appendScale(1, 0, 1);
					//matrix3d.appendRotation(angleX, Vector3D.X_AXIS);
					matrix3d.appendRotation(modRot.y, Vector3D.Y_AXIS);
					matrix3d.appendRotation(angleZ, Vector3D.Z_AXIS);
					matrix3d.appendScale(modZoom.x, modZoom.y, .0);
					matrix3d.appendTranslation(modPos.x, modPos.y, modPos.z);

					var ofs:Float = note.__dark;
					if (mods.active)
					{
						ct.setMultipliers(1 - modColor.redFloat, 1 - modColor.greenFloat, 1 - modColor.blueFloat, modColor.alphaFloat);
						ofs += modGlow * 255.;
					}
					ct.setOffsets(ofs, ofs, ofs, .0);
				}

				if (cap)
					segments++;
				var i = .0;
				while (i < segments)
				{
					final i2 = Math.min(i + 1, segments);

					if (!cap)
					{
						frame.frame.y = -Math.abs(bodyDist * ((segments - i) / segments)) / hold.scale;
						frame.frame.bottom = -Math.abs(bodyDist * ((segments - i2) / segments)) / hold.scale;
					}
					else
					{
						frame.frame.y = (capClip + Math.abs(realCapHeight * (i / segments))) / hold.scale;
						frame.frame.bottom = (capClip + Math.abs(realCapHeight * (i2 / segments))) / hold.scale;
					}

					// if we don't have a last position (cause we just started) then make one
					if (i == .0 && (!drawBody || !cap))
					{
						getArrowEffectsPos(pn, startBeat, startMs, note.noteData, false, false, cap ? null : startYOffset);
						v3.copyFrom(modPos); // just copy it for 0 holds :)
						v3.y += ArrowEffects.ARROW_SIZE_HALF;
						updateDrawInfo();
					}

					if (isTooClose(pn))
					{
						i = i2;
						continue;
					}
					else if (isTooFar(pn))
					{
						break;
					}

					drawItem.addQuad(frame, mat, ct);

					// and now push the position of the last (or firsts?? ) ones
					for (_ in 0...2)
					{
						pushRGBHueColor(null, 0, drawItem);
						pushLocalTransform(drawItem);
					}

					v3.copyFrom(modPos); // save last pos for spiralholds
					final t2 = i2 / segments;
					getArrowEffectsPos(pn, FlxMath.lerp(startBeat, endBeat, t2), FlxMath.lerp(startMs, endMs, t2), note.noteData, false, false);
					updateDrawInfo();

					// and now now now
					final len = drawItem.colorMultipliers.length;
					for (i in 0...2)
					{
						pushRGBHueColor(null, 0, drawItem);
						pushLocalTransform(drawItem);

						// we gotta override the old colors
						final i4 = (i * 4);
						drawItem.colorMultipliers[len - 4 - i4] = ct.redMultiplier;
						drawItem.colorMultipliers[len - 3 - i4] = ct.greenMultiplier;
						drawItem.colorMultipliers[len - 2 - i4] = ct.blueMultiplier;
						drawItem.colorMultipliers[len - 1 - i4] = ct.alphaMultiplier;

						drawItem.colorOffsets[len - 4 - i4] = ct.redOffset;
						drawItem.colorOffsets[len - 3 - i4] = ct.greenOffset;
						drawItem.colorOffsets[len - 2 - i4] = ct.blueOffset;
						drawItem.colorOffsets[len - 1 - i4] = ct.alphaOffset;
					}

					i = i2;
				}
			}
			// if we dont need to, just render holds with 4 segments total
			final grain = wavyHolds[pn] ? mods.playerStates[pn].fGrain : 512;
			if (drawBody)
				drawPart(bodyDist / grain, false);
			drawPart(realCapHeight / grain, true);
		}
		ng.__currentlyLooping = oldCur;
	}

	function drawArrows(camera:FlxCamera, pn:Int)
	{
		final strumLine = strumLine(pn);
		final ng = strumLine.notes;

		final oldCur = ng.__currentlyLooping;
		ng.__currentlyLooping = true;

		var i = ng.length - 1;
		while (i >= 0)
		{
			final note = ng.__loopSprite = ng.members[i--];
			if (!note?.exists || note.held)
				continue;
			// update mod positions (or not)
			if (mods.active)
				getArrowEffectsPos(pn, note.beatTime, note.strumTime, note.noteData, false, false, note.__distance);
			else
				modYOffset = note.__distance; // with relative pos the y is just the distance

			// better draw distance based on pixel distance rather than song distance
			if (isTooClose(pn))
				continue;
			else if (isTooFar(pn))
				break;

			// apply colors
			var ofs:Float = note.__dark;
			if (mods.active)
			{
				note.colorTransform.setMultipliers(1 - modColor.redFloat, 1 - modColor.greenFloat, 1 - modColor.blueFloat, modColor.alphaFloat);
				ofs += modGlow * 255.;
			}
			note.colorTransform.setOffsets(ofs, ofs, ofs, .0);

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

		if (mods.active)
		{
			matrix3d.identity();
			matrix3d.appendTranslation(-sprite.origin.x, -sprite.origin.y, 0);
			matrix3d.appendRotation(-modRot.x, Vector3D.X_AXIS);
			matrix3d.appendRotation(modRot.y, Vector3D.Y_AXIS);
			matrix3d.appendRotation(modRot.z, Vector3D.Z_AXIS);
			matrix3d.appendScale(modZoom.x, modZoom.y, modZoom.z);
			matrix3d.appendTranslation(modPos.x + sprite.origin.x - p.x, modPos.y + sprite.origin.y - p.y, modPos.z);
		}

		for (_ in 0...FlxDrawQuadsItem.VERTICES_PER_QUAD)
		{
			pushRGBHueColor(rgbColor, hue, item);

			if (mods.active)
			{
				// its a vec4 im justpacking them together cause it was being weird when they were seperate
				// pushPoint(item.localOrigin, sprite.origin);
				// pushPoint(item.localOrigin, p);

				// pushVector3D(item.localPosition, modPos);
				// pushVector3D(item.localRotation, modRot);
				// pushVector3D(item.localZoom, modZoom);

				pushLocalTransform(item);
			}
		}
	}

	function getMissDark(note:Note):Float
	{
		if (!note.tooLate)
			return 0;
		final hitWindow:Float = Flags.USE_LEGACY_TIMING ? PlayState.instance.hitWindow : PlayState.instance.ratingManager.lastHitWindow;
		final dark:Float = FlxMath.remapToRange(note.strumTime - mods.conductor.songPosition, -hitWindow, -hitWindow - 100, 0, -100);
		return dark.clamp(-100, 0);
	}

	function pushRGBHueColor<T>(rgbColor:RGBColor, hue:Float, item:FlxDrawBaseItem<T>)
	{
		// if (rgbColor != null && rgbColor.mix > .0)
		// {
		//	pushColor(item.r, rgbColor.r);
		//	pushColor(item.g, rgbColor.g);
		//	pushColor(item.b, rgbColor.b);
		//	item.rgbMix.push(rgbColor.mix);
		// }
		// else
		// {
		//	pushColor(item.r, FlxColor.RED);
		//	pushColor(item.g, FlxColor.GREEN);
		//	pushColor(item.b, FlxColor.BLUE);
		//	item.rgbMix.push(0.0);
		// }
		item.hue.push(hue);
	}

	function drawSplashes(camera:FlxCamera, pn:Int)
	{
		for (splash in splashes[pn])
		{
			// update mod positions
			if (mods.active)
			{
				getArrowEffectsPos(pn, mods.conductor.curBeatFloat, mods.conductor.songPosition, splash.strum.ID, true, false);
				if (modDark <= 0.0 || !isOnScreen(pn))
					continue;
			}
			else
			{
				splash.setPosition(splash.strum.x, splash.strum.y);
			}

			// apply colors
			splash.colorTransform.copyTo(ct);
			splash.colorTransform.alphaMultiplier *= modDark;
			drawSprite(camera, pn, splash, null, SPLASH_HUES[splash.strum.ID]);
			ct.copyTo(splash.colorTransform);
		}
	}

	function drawHoldCovers(camera:FlxCamera, pn:Int)
	{
		final strumLine = strumLine(pn);
		for (cover in strumLine.holdCovers.members)
		{
			if (!cover.visible)
				continue;
			// update mod positions
			if (mods.active)
			{
				getArrowEffectsPos(pn, mods.conductor.curBeatFloat, mods.conductor.songPosition, cover.ID, true, false);
				if (modDark <= 0.0 || !isOnScreen(pn))
					continue;
			}
			else
			{
				cover.setPosition(strumLine.members[cover.ID].x, strumLine.members[cover.ID].y);
			}

			// its invisible
			// if (modDark == .0)
			//	continue;
			// update local matrix
			// updateLocalMatrix(receptor.origin);

			// apply darkness
			// receptor.colorTransform.alphaMultiplier = modDark;

			// apply colors
			cover.colorTransform.copyTo(ct);
			cover.colorTransform.alphaMultiplier *= modDark;
			drawSprite(camera, pn, cover);
			ct.copyTo(cover.colorTransform);
		}
	}

	function initDrawItem<T>(pn:Int, item:FlxDrawBaseItem<T>)
	{
		if (item.playFieldTransform.length > 0)
			return;
		item.wrapMode = CLAMP_U_REPEAT_V;
		if (!mods.active)
		{
			item.simpleShader = simpleShader;
		}
		else
		{
			item.modsShader = shaders[pn];
			pushPlayFieldMatrix(item, playField(pn).matrix);
			v3.copyFrom(playField(pn).pos);
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

	inline function pushPlayFieldMatrix<T>(item:FlxDrawBaseItem<T>, matrix:Matrix3D)
	{
		final r = matrix.rawData;
		item.playFieldTransform.pushr( //
			r[0], r[4], r[8], r[12], //
			r[1], r[5], r[9], r[13], //
			r[2], r[6], r[10], r[14], //
			r[3], r[7], r[11], r[15], //
		); //
	}

	static final __fullMatrix:Array<Float> = [];

	inline function pushLocalTransform<T>(item:FlxDrawBaseItem<T>)
	{
		// when we dont do it like this haxe compiles it evily
		item.localTransform0.pushr(matrix3d.rawData[0], matrix3d.rawData[4], matrix3d.rawData[8], matrix3d.rawData[12]);
		item.localTransform1.pushr(matrix3d.rawData[1], matrix3d.rawData[5], matrix3d.rawData[9], matrix3d.rawData[13]);
		item.localTransform2.pushr(matrix3d.rawData[2], matrix3d.rawData[6], matrix3d.rawData[10], matrix3d.rawData[14]);
		item.localTransform3.pushr(matrix3d.rawData[3], matrix3d.rawData[7], matrix3d.rawData[11], matrix3d.rawData[15]);
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
			return FlxAngle.TO_DEG * (FlxAngle.radiansFromOrigin(b.x - a.x, b.y - a.y) + HALF_PI) * spiral;
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
			_hue = hue;
			gl_Position = openfl_Matrix * openfl_Position;
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
			gl_FragColor = vec4(hueShift(new_color.rgb, _hue), new_color.a);
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
	
		//attribute vec3 r;
		//attribute vec3 g;
		//attribute vec3 b;
		//attribute float rgb_mix;
		attribute float hue;

		attribute vec4 localTransform0;
		attribute vec4 localTransform1;
		attribute vec4 localTransform2;
		attribute vec4 localTransform3;

		uniform mat4 playFieldTransform;
		uniform vec3 playFieldPos;
		uniform vec3 depthStuff;
		
		const float far = 100.;
		const float near = 0.1;
		uniform float fov;
	
		//varying vec3 _r;
		//varying vec3 _g;
		//varying vec3 _b;
		//varying float _rgb_mix;
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

			mat4 localTransform = mat4(
				localTransform0, 
				localTransform1, 
				localTransform2, 
				localTransform3
			);
			vec4 pos = openfl_Position * localTransform * playFieldTransform;
			// yes this is just the shitty funkin modchart projection but here instead cause im too stupid to use a matrix
			float projectedZ = depthStuff.x * min((pos.z / 1280.) - 1.0, 0.0) + depthStuff.y;
			float projectedFov = (depthStuff.z / projectedZ);
			pos.xy *= projectedFov;
			pos.z = projectedZ;
			depth = projectedZ;

			gl_Position = openfl_Matrix * (pos + vec4(playFieldPos, 0.0));
			//_r = r;
			//_g = g;
			//_b = b;
			//_rgb_mix = rgb_mix;
			_hue = hue;
		}
	')
	@:glFragmentSource('
		#pragma header
	
		//varying vec3 _r;
		//varying vec3 _g;
		//varying vec3 _b;
		//varying float _rgb_mix;
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
