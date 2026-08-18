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
@:access(funkin.game.StrumLine.startingPos)
class PlayField
{
	public var player:Int;

	public var pos = Vector3D.get();
	public var rot = Vector3D.get();
	public var skew = FlxPoint.get();
	public var zoom = Vector3D.get(1.0, 1.0, 1.0, 1.0); // "w" is used as total zoom

	public var fov:Float = 90.;

	public var matrix = new Matrix3D();

	public var proxies:Array<PlayField> = [];

	public var strumLine(get, never):StrumLine;

	function get_strumLine()
	{
		return PlayState.instance.strumLines.members[player];
	}

	public function new(player:Int, mods:ArrowEffects)
	{
		this.player = player;
		final size = ArrowEffects.ARROW_SIZE * (strumLine.data.strumScale ?? 1.0) * (strumLine.data.strumSpacing ?? 1.0);
		final lanes = strumLine.data.keyCount ?? 4;
		final ofsY = (ArrowEffects.ARROW_SIZE * .5) - (ArrowEffects.ARROW_SIZE * (strumLine.data.strumScale ?? 1.0) * .5);
		pos.set(strumLine.startingPos.x + (size * (lanes * .5) * .5) + (size * .5), strumLine.startingPos.y + (mods.position.reverseOffset * .5) + ofsY);
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
