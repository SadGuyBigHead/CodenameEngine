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
class Note extends FlxSprite
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
		this.beatTime = dave.DaveConductor.instance.getTimeInBeats(this.strumTime);
		endTime = this.strumTime + noteData.sLen;
		sustainLength = noteData.sLen;
		this.beatEndTime = dave.DaveConductor.instance.getTimeInBeats(endTime);
		this.noteData = noteData.id.getDefault(0);

		var customType = Paths.image('game/notes/${this.noteType}');
		var event = EventManager.get(NoteCreationEvent)
			.recycle(this, strumID, this.noteType, noteTypeID, PlayState.instance.strumLines.members.indexOf(strumLine), mustPress,
				(this.noteType != null && customTypePathExists(customType)) ? 'game/notes/${this.noteType}' : 'game/notes/default', @:privateAccess
				strumLine.strumScale * Flags.DEFAULT_NOTE_SCALE, animSuffix);

		if (PlayState.instance != null)
			event = PlayState.instance.gameAndCharsEvent("onNoteCreation", event);

		this.animSuffix = event.animSuffix;
		if (!event.cancelled)
		{
			switch (event.noteType)
			{
				// case "My Custom Note Type": // hardcoding note types
				default:
					frames = Paths.getFrames(event.noteSprite);

					switch (event.strumID % 4)
					{
						case 0:
							animation.addByPrefix('scroll', 'purple0');
							animation.addByPrefix('hold', 'purple hold piece');
							animation.addByPrefix("holdend", "pruple end hold");
							if (animation.exists("holdend") != true) // null or false
								animation.addByPrefix('holdend', 'purple hold end');
						case 1:
							animation.addByPrefix('scroll', 'blue0');
							animation.addByPrefix('hold', 'blue hold piece');
							animation.addByPrefix('holdend', 'blue hold end');
						case 2:
							animation.addByPrefix('scroll', 'green0');
							animation.addByPrefix('hold', 'green hold piece');
							animation.addByPrefix('holdend', 'green hold end');
						case 3:
							animation.addByPrefix('scroll', 'red0');
							animation.addByPrefix('hold', 'red hold piece');
							animation.addByPrefix('holdend', 'red hold end');
					}

					scale.set(event.noteScale, event.noteScale);
					antialiasing = true;
			}
		}

		updateHitbox();

		animation.play("scroll");

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

		if (strum.width != __lastStrumW || strum.height != __lastStrumH)
		{
			__lastStrumW = strum.width;
			__lastStrumH = strum.height;
			__lastStrumHalfW = strum.width * 0.5;
			__lastStrumHalfH = strum.height * 0.5;
		}

		x = -origin.x + offset.x + (__distance * __lastAngleCos) + strum.x + __lastStrumHalfW;
		y = -origin.y + offset.y + (__distance * __lastAngleSin) + strum.y + __lastStrumHalfH;
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
		this.note = note;

		// cause i want to do note pooling later
		if (note.sustainLength <= 0)
		{
			clear();
			return;
		}
		final holdFrames = PlayState.instance.noteRenderer.graphics.getHoldFrames(note);
		scale = note.scale.x;
		body = holdFrames.getHoldFrame(note.noteData, false);
		cap = holdFrames.getHoldFrame(note.noteData, true);
		graphic = body.parent;
		startBeat = note.beatTime;
		startMs = note.strumTime;
		endBeat = note.beatEndTime;
		endMs = note.endTime;
		column = note.noteData;
		antialiasing = note.antialiasing;

		bodyWidth = body.sourceSize.x * note.scale.x;
		bodyHalfWidth = bodyWidth * .5;
		bodyHeight = body.sourceSize.y * note.scale.y;

		capWidth = cap.sourceSize.x * note.scale.x;
		capHalfWidth = bodyWidth * .5;
		capHeight = cap.sourceSize.y * note.scale.y;

		offset.set(Note.swagWidth * .5, Note.swagWidth * .5);

		body.prepareMatrix(bodyMatrix, FlxFrameAngle.ANGLE_0, false, false);
		bodyMatrix.translate(-bodyHalfWidth, 0);
		bodyMatrix.scale(scale, scale);
		bodyMatrix.translate(offset.x, offset.y);
		
		cap.prepareMatrix(capMatrix, FlxFrameAngle.ANGLE_0, false, false);
		capMatrix.translate(-capHalfWidth, 0);
		capMatrix.scale(scale, scale);
		capMatrix.translate(offset.x, offset.y);
	}

	function clear()
	{
		body = null;
		cap = null;
	}

	public function destroy()
	{
		holdFrames = null;
		note = null;
		offset = FlxDestroyUtil.put(offset);
	}
}