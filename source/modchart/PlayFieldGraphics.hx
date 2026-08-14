package modchart;

import funkin.game.Note;
import flixel.math.FlxRect;
import openfl.display.BitmapData;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import openfl.geom.Rectangle;
import openfl.geom.Matrix;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;

using flixel.util.FlxColorTransformUtil;

#if !modchart_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:nullSafety
@:access(flixel.graphics.FlxGraphic.shader)
class PlayFieldGraphics implements IFlxDestroyable
{
	var holdFrames:Map<String, HoldFrames> = [];

	public function new()
	{
	}

	@:nullSafety(Off)
	public function getHoldFrames(note:Note):HoldFrames
	{
		final key = note.graphic.assetsKey;
		if (holdFrames.exists(key))
			return holdFrames.get(key);
		final frames = new HoldFrames(note.frames, Options.antialiasing);
		holdFrames.set(key, frames);
		return frames;
	}

	@:nullSafety(Off)
	public function destroy()
	{
		if (holdFrames != null)
		{
			for (i in holdFrames)
				i?.destroy();
			holdFrames.clear();
			holdFrames = null;
		}
	}
}

#if !modchart_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(flixel.graphics.frames.FlxFrame)
@:access(flixel.graphics.FlxGraphic)
@:access(openfl.geom.Matrix.__pool)
@:access(openfl.geom.Rectangle.__pool)
class HoldFrames implements IFlxDestroyable
{
	// under ideal circumstances, these will all be the same graphic
	public var holdBodyFrames = new Array<FlxFrame>();
	public var holdCapFrames = new Array<FlxFrame>();
	public var graphics = new Array<FlxGraphic>();

	function getFrameName(col:Int, cap:Bool)
	{
		if (cap)
		{
			return (switch (col % 4)
			{
				case 0:
					"purple hold end";
				case 1:
					"blue hold end";
				case 2:
					"green hold end";
				case 3:
					"red hold end";
				default: throw "poo";
			}) + "0000";
		}
		else
		{
			return (switch (col % 4)
			{
				case 0:
					"purple hold piece";
				case 1:
					"blue hold piece";
				case 2:
					"green hold piece";
				case 3:
					"red hold piece";
				default: throw "poo";
			}) + "0000";
		}
	}

	public function new(frames:FlxFramesCollection, aa:Bool)
	{
		final frames = frames;
		final aa = aa;

		var bodyFrames = new Array<FlxFrame>();
		var capFrames = new Array<FlxFrame>();

		var groups:Array<_HOLDFRAMEGROUP> = [];

		for (i in 0...4)
		{
			final body = frames.getByName(getFrameName(i, false));
			final cap = frames.getByName(getFrameName(i, true));

			bodyFrames.push(body);
			capFrames.push(cap);
		}

		final padding = aa ? 2 : 0;
		// now that we've found out if we need to seperate caps..
		for (i in 0...4)
		{
			var foundGroup = false;

			final body:_HOLDFRAMEENTRY = {
				direction: i,
				array: holdBodyFrames,
				frame: bodyFrames[i],
				pos: 0,
				cap: false
			}
			final cap:_HOLDFRAMEENTRY = {
				direction: i,
				array: holdCapFrames,
				frame: capFrames[i],
				pos: 0,
				cap: true
			}
			final h = body.frame.frame.height;
			for (group in groups)
			{
				if (FlxMath.equal(group.height, h))
				{
					group.frames.push(body);
					group.frames.push(cap);
					foundGroup = true;
					break;
				}
				else
				{
					trace("bad group", group.height, h);
				}
			}

			if (!foundGroup)
			{
				groups.push({height: cast h, frames: [body, cap]});
			}
		}

		final matrix = Matrix.__pool.get();
		final clipRect = Rectangle.__pool.get();
		// get this like this so we can draw with it
		Main.forceGPUOnlyBitmapsOff = true;
		final noteBitmap = Assets.getBitmapData(frames.parent.assetsKey, false);
		Main.forceGPUOnlyBitmapsOff = false;

		trace("[HoldGraphic] Generating " + groups.length + " bitmaps for holds...");
		for (i => group in groups)
		{
			final key = '${frames.parent.assetsKey}-hold-$i';
			final draw = FlxG.bitmap.get(key) == null;

			var w = 0;
			var h = group.height;

			for (frame in group.frames)
			{
				frame.pos = w;
				w += Math.ceil(frame.frame.frame.width) + padding;
				// we want to loop the body frame until we can fit the cap
				while (frame.cap && frame.frame.frame.height >= (aa ? h - (padding + 1) : h))
					h += group.height;
			}

			// amount of times to draw the body vertically

			var bitmap = draw ? new BitmapData(w, h, true, 0x00) : null;
			final graphic = draw ? FlxG.bitmap.add(new FlxGraphic(key, bitmap, true), false, key) : FlxG.bitmap.get(key);
			bitmap ??= graphic.bitmap;
			PlayState.instance.graphicCache.cacheGraphic(graphic);
			graphics.push(graphic);
			for (frame in group.frames)
			{
				final frameRect = frame.frame.frame;
				final bodies = Math.ceil(h / frame.frame.frame.height);
				if (draw)
				{
					matrix.identity();
					matrix.translate(frame.pos - frameRect.x, -frameRect.y);
					clipRect.setTo(frame.pos, 0, frameRect.width, frameRect.height);
					inline function drawToBitmap()
					{
						graphic.bitmap.draw(noteBitmap, matrix, null, null, clipRect, false);
					}
					if (frame.cap)
					{
						drawToBitmap();
						// draw one pixel of the top of the cap at the bottom to prevent weird wrapping seams
						if (aa)
						{
							matrix.translate(0, h - 1);
							clipRect.y = h - 1;
							drawToBitmap();
						}
					}
					else
					{
						for (_ in 0...bodies)
						{
							drawToBitmap();
							matrix.translate(0, frame.frame.frame.height);
							clipRect.y += frame.frame.frame.height;
						}
					}
				}
				final newFrame = new FlxFrame(graphic);
				newFrame.offset.y = bodies; // store scale in a value we don't use
				newFrame.name = frame.frame.name + "-generated"; // AI GENERATED MODS
				newFrame.frame = FlxRect.get(frame.pos, 0, frameRect.width, frameRect.height);
				newFrame.sourceSize.set(frameRect.width, frameRect.height);
				frame.array[frame.direction] = newFrame;
			}
		}

		// cleanup
		noteBitmap.dispose();
		Matrix.__pool.release(matrix);
		Rectangle.__pool.release(clipRect);
	}

	public inline function getHoldFrame(direction:Int, cap:Bool)
	{
		return cap ? holdCapFrames[direction] : holdBodyFrames[direction];
	}

	public function destroy()
	{
		holdBodyFrames = FlxDestroyUtil.destroyArray(holdBodyFrames);
		holdCapFrames = FlxDestroyUtil.destroyArray(holdCapFrames);
		graphics = null;
	}
}

private typedef _HOLDFRAMEENTRY =
{
	direction:Int,
	array:Array<FlxFrame>,
	frame:FlxFrame,
	pos:Int,
	cap:Bool
}

private typedef _HOLDFRAMEGROUP =
{
	height:Int,
	frames:Array<_HOLDFRAMEENTRY>
}
