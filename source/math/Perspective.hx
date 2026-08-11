package math;

import openfl.geom.Matrix3D;
import openfl.utils.PerspectiveMatrix3D;
import flixel.math.FlxAngle;
import openfl.Vector;

/**
 * https://github.com/theoo-h/FunkinModchart/blob/6c9add23b1cef8183c55eee92d55855f8423334e/modchart/backend/math/ModchartPerspective.hx
 */
#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
final class Perspective
{
	/**
	 * Distance to the near clipping plane.
	 * Objects closer than this distance will not be rendered.
	 */
	public var near(default, set):Float = 0;

	/**
	 * Distance to the far clipping plane.
	 * Objects farther than this distance will not be rendered.
	 */
	public var far(default, set):Float = 1;

	/**
	 * Field of View (FOV) in radians.
	 * Defines the extent of the observable world projected onto the screen.
	 * 
	 * **NOTE:** This value defaults to 90 degrees (PI / 2).
	 */
	public var fov(default, set):Float;

	/**
	 * Distance range between the near and far clipping planes.
	 * Calculated as `near - far`.
	 */
	public var range(get, never):Float;

	/**
	 * Internal projection components.
	 */
	private var __tanHalfFov:Float = 0;

	private var __depthRange:Float = 1;
	private var __depthScale:Float = 1;
	private var __depthOffset:Float = 0;

	public var origin:Vector3D;

	public function new(?origin:Vector3D)
	{
		this.origin = origin ?? Vector3D.get(FlxG.width * .5, FlxG.height * .5, .0);
		fov = Math.PI / 2;
		updateProperties();
	}

	private function set_near(value:Float):Float
	{
		near = value;
		updateProperties();
		return value;
	}

	private function set_far(value:Float):Float
	{
		far = value;
		updateProperties();
		return value;
	}

	private function set_fov(value:Float):Float
	{
		fov = value;
		updateProperties();
		return value;
	}

	private function get_range():Float
	{
		return near - far;
	}

	/**
	 * Updates internal projection properties based on current FOV and depth range.
	 */
	public function updateProperties():Void
	{
		__tanHalfFov = Math.tan(fov * 0.5);
		__depthRange = 1 / range;
		__depthScale = (near + far) * __depthRange;
		__depthOffset = 2 * near * (far * __depthRange);
	}

	// ADD LATER: find way to use a matrix instead of this
	/**
	 * Transforms a 3D vector into 2D screen space using perspective projection. ion place it does in place
	 *
	 * @param vector The 3D vector to project.
	 * @param origin Optional origin point for transformation (defaults to screen center).
	 * @return The projected 2D vector.
	 */
	public function transformVector(vector:Vector3D):Vector3D
	{
		vector -= origin;

		final projectedZ = __depthScale * Math.min((vector.z / FlxG.width) - 1, 0) + __depthOffset;
		final projectedFov = (__tanHalfFov / projectedZ);

		vector.set(vector.x * projectedFov, vector.y * projectedFov, projectedZ);
		vector += origin;
		return vector;
	}
}
