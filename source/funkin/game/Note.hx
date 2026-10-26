package funkin.game;

import modchart.PlayFieldGraphics;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxPoint;
import flixel.math.FlxAngle;
import flixel.math.FlxRect;
import funkin.backend.chart.ChartData;
import funkin.backend.scripting.events.note.NoteCreationEvent;
import funkin.backend.system.Conductor;
import flixel.math.FlxMatrix;

using StringTools;

@:allow(funkin.game.PlayState)
class Note extends StrumLineSprite
{
	public var player(get, never):Int;

	function get_player()
	{
		return strumLine.ID;
	}

	public var hold:HoldNote;

	public var sustainLength:Float;

	public var held:Bool;

	public var holdScore:Float = 450;

	// who cares
	public var extra:Map<String, Dynamic> = [];

	public var strumTime:Float = 0;

	public var beatTime:Float = 0;
	public var beatEndTime:Float = 0;
	public var endTime:Float = 0;

	public var mustPress(get, never):Bool;
	public var strumLine(default, set):StrumLine;

	public var deltaScoreProgress:Float;

	var lastProgress:Float;

	private function set_strumLine(strLine:StrumLine)
	{
		if (this.strumLine != null)
		{
			if (this.strumLine.notes != null)
				this.strumLine.notes.remove(this, true);
			strLine.notes.add(this);
			strLine.notes.sortNotes();
		}
		return strumLine = strLine;
	}

	private inline function get_mustPress():Bool
	{
		return false;
	}

	public var noteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var wasMissed:Bool = false;

	/**
	 * Whenever that note should be avoided by Botplay.
	 */
	public var avoid:Bool = false;

	/**
	 * The note that comes before this one (sustain and not)
	 */
	public var prevNote:Note;

	/**
	 * The note that comes after this one (sustain and not)
	 */
	public var nextNote:Note;

	/**
	 * Name of the splash.
	 */
	public var splash:String = "default";

	public var strumID(get, never):Int;

	private function get_strumID()
	{
		return if (noteData < 0) 0; else noteData % strumLine.members.length;
	}

	public var noteTypeID:Int = 0;

	// TO APPLY THOSE ON A SINGLE NOTE
	public var scrollSpeed:Null<Float> = null;
	public var noteAngle:Null<Float> = null;

	public var copyStrumAngle:Bool = true;
	public var updateNotesPosX:Bool = true;
	public var updateNotesPosY:Bool = true;
	public var updateFlipY:Bool = true;

	public var noteType(get, never):String;

	public var strum:Strum;

	@:dox(hide) @:allow(funkin.game.Strum) @:noCompletion private var __strumCameras:Array<FlxCamera> = null;
	@:dox(hide) @:allow(funkin.game.Strum) @:noCompletion private var __noteAngle:Float = 0;
	@:dox(hide) @:allow(funkin.game.Strum) @:noCompletion private var __hasStrumPos:Bool = false;

	@:dox(hide) @:noCompletion var __distance:Float;
	@:dox(hide) @:noCompletion var __dark:Float;

	private function get_noteType()
	{
		if (PlayState.instance == null)
			return null;
		return PlayState.instance.getNoteType(noteTypeID);
	}

	public static var swagWidth:Float = 160 * 0.7; // TODO: remove this

	private static var __customNoteTypeExists:Map<String, Bool> = [];

	public var animSuffix:String = null;

	// Deprecated?
	@:dox(hide) public var tripTimer:Float = 0; // ranges from 0 to 1

	private static function customTypePathExists(path:String)
	{
		if (__customNoteTypeExists.exists(path))
			return __customNoteTypeExists[path];
		return __customNoteTypeExists[path] = Assets.exists(path);
	}

	static var DEFAULT_FIELDS:Array<String> = ["time", "id", "type", "sLen"];

	public function new(strumLine:StrumLine, noteData:ChartNote, ?prev:Note)
	{
		super();

		moves = false;

		if (prev != null)
			this.prevNote = prev;
		else
			this.prevNote = strumLine.notes.members.last();

		if (this.prevNote != null)
			this.prevNote.nextNote = this;
		this.noteTypeID = noteData.type.getDefault(0);
		this.strumLine = strumLine;
		for (field in Reflect.fields(noteData))
			if (!DEFAULT_FIELDS.contains(field))
				this.extra.set(field, Reflect.field(noteData, field));

		x += 50;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;

		this.strumTime = noteData.time.getDefault(0);
		this.beatTime = Conductor.instance.getTimeInBeats(this.strumTime);
		endTime = this.strumTime + noteData.sLen;
		sustainLength = noteData.sLen;
		this.beatEndTime = Conductor.instance.getTimeInBeats(endTime);
		this.noteData = noteData.id.getDefault(0);

		var customType = Paths.image('game/notes/${this.noteType}');
		var notePath = (this.noteType != null && customTypePathExists(customType)) ? 'game/notes/${this.noteType}' : 'game/notes/default';

		var event = EventManager.get(NoteCreationEvent)
			.recycle(this, strumID, this.noteType, noteTypeID, PlayState.instance.strumLines.members.indexOf(strumLine), mustPress, notePath, @:privateAccess
				strumLine.strumScale * Flags.DEFAULT_NOTE_SCALE, animSuffix);
		final skin = NoteSkin.get(event.noteSprite);

		if (PlayState.instance != null)
			event = PlayState.instance.gameAndCharsEvent("onNoteCreation", event);

		this.animSuffix = event.animSuffix;
		if (!event.cancelled)
		{
			frames = Paths.getFrames(event.noteSprite);

			final anims = skin.arrows.anims[event.strumID % skin.arrows.anims.length];

			animation.addByPrefix("scroll", anims.scroll.name, anims.scroll.fps ?? 0);
			animation.addByPrefix("hold", anims.holdBody.name, anims.holdBody.fps ?? 0);
			animation.addByPrefix("holdend", anims.holdCap.name, anims.holdCap.fps ?? 0);
			scale.set(event.noteScale, event.noteScale).scale(skin.scale); // skin scale always forced
			antialiasing = true;
		}
		animation.play("scroll");
		targetFrame = frame;
		
		centerSprite();

		if (PlayState.instance != null)
		{
			PlayState.instance.splashHandler.getSplashGroup(splash);
			PlayState.instance.gameAndCharsEvent("onPostNoteCreation", event);
		}

		hold = new HoldNote(this);
	}

	/**
	 * Whenever the position of the note should be relative to the strum position or not.
	 * For example, if this is true, a note at the position 0; 0 will be on the strum, instead of at the top left of the screen.
	 */
	public var strumRelativePos:Bool = true;

	@:dox(hide) static var __lastAngle:Float = Math.NaN;
	@:dox(hide) static var __lastAngleSin:Float = 0;
	@:dox(hide) static var __lastAngleCos:Float = 0;
	@:dox(hide) static var __lastStrumW:Float = Math.NaN;
	@:dox(hide) static var __lastStrumH:Float = Math.NaN;
	@:dox(hide) static var __lastStrumHalfW:Float = 0;
	@:dox(hide) static var __lastStrumHalfH:Float = 0;

	override function draw()
	{
	}

	function applyStrumPos()
	{
		if (__noteAngle != __lastAngle)
		{
			__lastAngle = __noteAngle;
			final result = FlxMath.fastSinCos((__noteAngle + 90) * FlxAngle.TO_RAD);
			__lastAngleSin = result.sin;
			__lastAngleCos = result.cos;
		}

		x = (__distance * __lastAngleCos) + strum.x;
		y = (__distance * __lastAngleSin) + strum.y;
	}

	public function updateScoreProgress(time:Float)
	{
		final progress = ((time - strumTime) / sustainLength).clamp(0, 1);
		final deltaProgress = progress - lastProgress;
		lastProgress = progress;
	}

	var __lastDownscrollCam:Bool = false;
	var __lastX:Float = 0;

	@:noCompletion @:dox(hide) override function isOnScreen(?camera:FlxCamera):Bool
	{
		var downscrollCam = (Std.isOfType(camera, HudCamera) ? cast(camera, HudCamera).downscroll : false);
		if (downscrollCam == __lastDownscrollCam)
			return super.isOnScreen(camera);
		else
			__lastX = x;

		if (downscrollCam && strum != null && strum.updateNotesPosX && updateNotesPosX)
		{
			x = -x + 2 * (strum.x - origin.x + offset.x) + strum.width;
		}
		final isOnScreen = super.isOnScreen(camera);
		return isOnScreen;
	}

	override function drawComplex(camera:FlxCamera):Void
	{
		super.drawComplex(camera);

		if (__lastDownscrollCam)
		{
			__lastDownscrollCam = false;
			x = __lastX;
		}
	}

	public function isOnScreenOriginal(?camera:FlxCamera):Bool
	{
		return super.isOnScreen(camera);
	}

	public var earlyPressWindow:Float = Flags.EARLY_HIT_WINDOW_RANGE;
	public var latePressWindow:Float = Flags.LATE_HIT_WINDOW_RANGE;

	public override function destroy()
	{
		super.destroy();

		clipRect = FlxDestroyUtil.put(clipRect);
		hold = FlxDestroyUtil.destroy(hold);
	}
}

class HoldNote implements IFlxDestroyable
{
	/**
	 * Set to true if like we cant draw this
	 */
	public var invalid:Bool;

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
	public var bodyWidth:Float;
	public var bodyHalfWidth:Float;
	public var bodyHeight:Float;
	public var bodyMatrix:FlxMatrix = new FlxMatrix();

	public var cap:FlxFrame;
	public var capWidth:Float;
	public var capHalfWidth:Float;
	public var capHeight:Float;
	public var capMatrix:FlxMatrix = new FlxMatrix();

	public var antialiasing:Bool;

	public var note:Note;

	public var scale:Float;

	public var offset:FlxPoint = FlxPoint.get();

	public function new(note:Note)
	{
		init(note);
	}

	public function init(note:Note)
	{
		if (note == null)
		{
			invalid = true;
			return;
		}

		this.note = note;

		// cause i want to do note pooling later
		if (note.sustainLength <= 0)
		{
			clear();
			return;
		}
		final holdFrames = PlayState.instance.noteRenderer.graphics.getHoldFrames(note);
		body = holdFrames.getHoldFrame(note.noteData, false);
		cap = holdFrames.getHoldFrame(note.noteData, true);
		validate();

		if (invalid)
			return;

		scale = note.scale.x;
		graphic = body.parent;
		startBeat = note.beatTime;
		startMs = note.strumTime;
		endBeat = note.beatEndTime;
		endMs = note.endTime;
		column = note.noteData;
		antialiasing = note.antialiasing;

		bodyWidth = body.frame.width * note.scale.x;
		bodyHalfWidth = bodyWidth * .5;
		bodyHeight = body.frame.height * note.scale.y;

		capWidth = cap.frame.width * note.scale.x;
		capHalfWidth = bodyWidth * .5;
		capHeight = cap.frame.height * note.scale.y;

		updateMatrix();
	}

	// updateMatrices!!! but who cares
	function updateMatrix()
	{
		bodyMatrix.identity();
		bodyMatrix.scale(scale, scale);
		bodyMatrix.translate(-bodyHalfWidth, 0);

		capMatrix.identity();
		capMatrix.scale(scale, scale);
		capMatrix.translate(-capHalfWidth, 0);
	}

	function clear()
	{
		body = null;
		cap = null;
	}

	function validate()
	{
		if (body == null || cap == null)
			invalid = true;
	}

	public function destroy()
	{
		holdFrames = null;
		note = null;
		offset = FlxDestroyUtil.put(offset);
		bodyMatrix = capMatrix = null;
	}
}
