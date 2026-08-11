package modchart;

import flixel.graphics.tile.FlxDrawTrianglesItem;
import flixel.graphics.tile.FlxDrawQuadsItem;
import openfl.geom.Matrix3D;
import math.Vector3D;
import funkin.game.StrumLine;

#if !modchart_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class PlayField
{
	public var player:Int;

	public var pos = Vector3D.get();
	public var rot = Vector3D.get();
	public var skew = FlxPoint.get();
	public var zoom = Vector3D.get(1.0, 1.0, 1.0, 1.0); // "w" is used as total zoom

	public var drawDistanceMin:Float = -FlxG.height * .25;
	public var drawDistanceMax:Float = FlxG.height;

	public var fov:Float = 90.;

	public var matrix = new Matrix3D();

	public var proxies:Array<PlayField> = [];

	public var strumLine(get, never):StrumLine;

	function get_strumLine()
	{
		return PlayState.instance.strumLines.members[player];
	}

	public function new(player:Int)
	{
		this.player = player;
		pos.set(getBaseReceptorX(1.5, player), 300);
	}

	function getBaseReceptorX(direction:Float, player:Int):Float
	{
		var x:Float = (FlxG.width / 2) - Note.swagWidth - 54 + Note.swagWidth * direction;
		switch (player % 2)
		{
			case 0:
				x -= FlxG.width / 2 - Note.swagWidth * 2 - 100;
			case 1:
				x += FlxG.width / 2 - Note.swagWidth * 2 - 100;
		}
		x -= 56;
		// x += NoteSprite.GRAPHIC_SIZE * .5;

		return x;
	}

	public function updateMatrix()
	{
		matrix.identity();
		matrix.appendScale(zoom.w * zoom.x, zoom.w * zoom.y, zoom.w * zoom.z);
		matrix.appendRotation(-rot.x, Vector3D.X_AXIS); // negative for some reason
		matrix.appendRotation(rot.y, Vector3D.Y_AXIS);
		matrix.appendRotation(rot.z, Vector3D.Z_AXIS);
		matrix.appendTranslation(.0, .0, pos.z);
	}
}
