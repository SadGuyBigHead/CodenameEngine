package dave;

import flixel.math.FlxRect;
import flixel.math.FlxMatrix;
import flixel.util.FlxStringUtil;
import funkin.backend.system.Conductor;
import flixel.sound.FlxSound;
import openfl.geom.ColorTransform;
import flixel.util.FlxColor;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxTileFrames;

using flixel.util.FlxColorTransformUtil;
using util.ColorTransformTools;
using util.SoundUtil;
using util.FloatTools;
using util.IntTools;

class DaveScrubber extends MusicBeatSubstate
{
	/**
	 * The list of quantizations for songs and stuff
	 */
	public static final QUANT_LIST:Array<Int> = [4, 8, 12, 16, 24, 32, 48, 64, 192];

	/**
	 * Color of the quant :)
	 */
	public static final QUANT_COLORS:Array<FlxColor> = [
		0xFFe74827,
		0xFF3d89f7,
		0xFFaa2df4,
		0xFF82e247,
		0xFFd82eab,
		0xFFeaa138,
		0xFFef8ceb,
		0xFF6be88e,
		0xFF828282
	];

	/**
	 * The current scroll snap (4-192)
	 */
	var snap(default, set):Int = 4;

	function set_snap(snap:Int)
	{
		exoticSnap = !QUANT_LIST.contains(snap);
		return this.snap = snap;
	}

	/**
	 * The current snap index
	 */
	var snapIndex(default, set):Int;

	function set_snapIndex(snapIndex:Int)
	{
		snapIndex = snapIndex.wrap(0, QUANT_LIST.length - 1);
		snap = QUANT_LIST[snapIndex];
		return this.snapIndex = snapIndex;
	}

	/**
	 * If the current snap isn't a default quant like 5 or something
	 */
	var exoticSnap:Bool;

	var ct = new ColorTransform();

	var matrix = new FlxMatrix();

	var inst:FlxSound;

	var vocals:Array<FlxSound> = [];

	var playing(default, set):Bool;

	var printText:DaveBitmapText;

	// graphics
	var pixel:FlxGraphic;
	var audioButtons:FlxTileFrames;

	// sizes
	static final bodyWidth = 1280 * .8;
	static final bodyHeight = 64;

	static final audioButtonPos = 10;
	static final audioButtonSize = bodyHeight - audioButtonPos;

	static final barWidth = bodyWidth - 24 - audioButtonSize - (audioButtonPos * 4);
	static final barHeight = bodyHeight - 24;

	static final handleWidth = 16;
	static final handleHeight = barHeight + 10;

	final x:Float = FlxG.width * .5;
	final y:Float = FlxG.height * .8;

	final barX:Float;

	var audioButtonScale:Float;

	var handlePos:Float;

	var barRect = FlxRect.get();
	var point = FlxPoint.get();

	var cam:FlxCamera;

	function set_playing(playing:Bool)
	{
		if (this.playing != playing)
		{
			if (playing)
				inst.play(true, conductor.songPosition);
			else
				inst.pause();
			for (channel in vocals)
			{
				if (playing)
					channel.play(true, inst.time);
				else
					channel.pause();
			}
		}
		return this.playing = playing;
	}

	public function new()
	{
		super();
		pixel = FlxG.bitmap.create(1, 1, FlxColor.WHITE, false, "scribber subscribe to channel");
		audioButtons = FlxTileFrames.fromGraphic(FlxG.bitmap.add("assets/images/editors/ui/audio-buttons.png"), FlxPoint.get(16, 16));
		audioButtonScale = audioButtonSize / 16;

		barX = x + audioButtonSize + audioButtonPos;
		barRect.set(barX - barWidth * .5, y - barHeight * .5, barWidth, barHeight);
	}

	override function create()
	{
		super.create();

		camera = cam = new FlxCamera();
		camera.bgColor.alpha = 0;
		FlxG.cameras.add(camera, false);
		FlxG.cameras.active = FlxG.plugins.active = false;

		inst = FlxG.sound.load(Assets.getMusic(Paths.inst(PlayState.SONG.meta.name, PlayState.difficulty, PlayState.SONG.meta.instSuffix)));

		var vocalsPath = Paths.voices(PlayState.SONG.meta.name, PlayState.difficulty, PlayState.SONG.meta.vocalsSuffix);
		if (PlayState.SONG.meta.needsVoices && Assets.exists(vocalsPath))
			vocals.push(FlxG.sound.load(Assets.getMusic(vocalsPath)));

		for (strumLine in PlayState.SONG.strumLines)
		{
			if (strumLine.vocalsSuffix == null || strumLine.vocalsSuffix.trim() == "")
				continue;
			var v = Paths.voices(PlayState.SONG.meta.name, PlayState.difficulty, strumLine.vocalsSuffix);
			final channel = FlxG.sound.load(Assets.getMusic(v));
			channel.group = FlxG.sound.defaultMusicGroup;
			channel.persist = false;
			vocals.push(channel);
		}

		for (channel in vocals)
		{
			channel.group = FlxG.sound.defaultMusicGroup;
			channel.persist = false;
		}

		conductor = new Conductor(inst);
		conductor.setupSong(PlayState.SONG);

		inst.time = conductor.songPosition = Conductor.instance.songPosition.clamp(0, inst.length); // set time to current time

		printText = new DaveBitmapText(50, 400, "Hi", 32, "perep");
		add(printText);
	}

	override function update(elapsed:Float)
	{
		// refresh it all
		if (FlxG.keys.justPressed.R || FlxG.keys.justPressed.ENTER && Conductor.instance.songPosition > conductor.songPosition)
		{
			MusicBeatState.skipTransOut = MusicBeatState.skipTransIn = true;
			final game = getGame();
			FlxG.switchState(game);
			game._scrubberRequest = true;
			return;
		}
		else if (FlxG.keys.justPressed.BACKSPACE || FlxG.keys.justPressed.ENTER)
		{
			if (Conductor.instance.songPosition > conductor.songPosition)
			{
				MusicBeatState.skipTransOut = MusicBeatState.skipTransIn = true;
				FlxG.switchState(getGame());
			}
			else if (!FlxMath.equal(conductor.songPosition, Conductor.instance.songPosition))
			{
				PlayState.instance.skipTime(conductor.songPosition);
				if (!FlxG.keys.justPressed.ENTER)
					close();
			}
			else if (!FlxG.keys.justPressed.ENTER)
			{
				close();
			}
			return;
		}

		super.update(elapsed);

		FlxG.mouse.visible = true;

		if (FlxG.keys.justPressed.SPACE)
			playing = !playing;

		if (FlxG.keys.justPressed.LEFT)
			snapIndex--;
		else if (FlxG.keys.justPressed.RIGHT)
			snapIndex++;

		if (FlxG.mouse.wheel != 0)
			scroll(-FlxG.mouse.wheel);
		if (FlxG.keys.justPressed.UP)
			scroll(-1)
		else if (FlxG.keys.justPressed.DOWN)
			scroll(1);

		if (FlxG.mouse.pressed)
		{
			FlxG.mouse.getViewPosition(camera, point);

			if (barRect.containsPoint(point))
			{
				final songPos = FlxMath.remapToRange(point.x, barRect.left, barRect.right, 0, inst.length);
				setTime(songPos);
			}
		}

		if (playing)
		{
			for (channel in vocals)
			{
				if (Math.abs(channel.getSourceTime() - inst.getSourceTime()) > 1)
					channel.setSourceTime(inst.getSourceTime());
			}
		}

		conductor.update();
		handlePos = barRect.left + ((conductor.songPosition * barWidth) / inst.length);
	}

	override function draw()
	{
		var buf = new StringBuf();
		buf.add("Time: ");
		buf.add(FlxStringUtil.formatTime(inst.time / 1000, true));
		buf.add(" / ");
		buf.add(FlxStringUtil.formatTime(inst.length / 1000));
		buf.addChar("\n".code);
		buf.add("Beat: ");
		buf.add(Std.string(FlxMath.roundDecimal(conductor.curBeatFloat, 3)));
		buf.addChar("\n".code);
		buf.add("Step: ");
		buf.add(Std.string(FlxMath.roundDecimal(conductor.curStepFloat, 3)));
		printText.text = buf.toString();

		super.draw();

		ct.reset();

		final f = pixel.imageFrame.frame;
		final pixelItem = camera.startQuadBatch(pixel, true, false);
		final audioButtonItem = camera.startQuadBatch(audioButtons.parent, false, false);

		// scrubber body
		matrix.identity();
		matrix.translate(-.5, -.5);
		matrix.scale(bodyWidth, bodyHeight);
		matrix.translate(x, y);
		ct.setMultColor(0x975F5F5F);
		pixelItem.addQuad(f, matrix, ct);

		// audio button
		matrix.identity();
		matrix.translate(-.5, -.5);
		matrix.scale(audioButtonScale, audioButtonScale);
		matrix.translate(x - (bodyWidth * .5) + audioButtonPos, y - (bodyHeight * .5) + audioButtonPos);
		audioButtonItem.addQuad(audioButtons.frames[inst.playing ? 1 : 0], matrix);

		// scrubber bar
		matrix.identity();
		matrix.translate(-.5, -.5);
		matrix.scale(barWidth, barHeight);
		matrix.translate(barX, y);
		ct.setMultColor(0xBD2F2F2F);
		pixelItem.addQuad(f, matrix, ct);

		// scrubber handle
		matrix.identity();
		matrix.translate(-.5, -.5);
		matrix.scale(handleWidth, handleHeight);
		matrix.translate(handlePos, y);
		ct.setMultColor(exoticSnap ? QUANT_COLORS[QUANT_COLORS.length - 1] : QUANT_COLORS[snapIndex]);
		pixelItem.addQuad(f, matrix, ct);
	}

	override function close()
	{
		super.close();
		FlxG.cameras.active = FlxG.plugins.active = true;
	}

	/**
	 * Scrolls the song position by quant * direction
	 * @param direction 
	 */
	function scroll(direction:Int)
	{
		// the beat difference we are moving at, based on the current snap
		final beatDiff = 4 / snap;

		// snap and round the beat first
		// round based on direction
		final beatFraction = conductor.curBeatFloat / beatDiff;
		final currentSnappedBeat = (direction > 0 ? Math.ceil(beatFraction) : Math.floor(beatFraction)) * beatDiff;

		// then our target beat
		// if we aren't our snapped beat, use that, otherwise add beatDiff * direction to the beat
		final targetBeat = (FlxMath.equal(conductor.curBeatFloat, currentSnappedBeat)) ? currentSnappedBeat + (direction * beatDiff) : currentSnappedBeat;

		// find the song position of that beat
		final songPos = conductor.getBeatsInTime(targetBeat).clamp(0, inst.length);
		setTime(songPos);
	}

	function setTime(songPos:Float)
	{
		inst.time = songPos;
		for (channel in vocals)
			channel.time = songPos;
		conductor.songPosition = songPos;
	}

	inline function getGame()
	{
		return new PlayState(conductor.songPosition, PlayState.instance.scriptsAllowed, PlayState.instance.scriptName);
	}

	override function destroy()
	{
		super.destroy();
		if (cam.exists)
			FlxG.cameras.remove(cam);
		cam = null;
		barRect = FlxDestroyUtil.put(barRect);
		point = FlxDestroyUtil.put(point);
	}
}
