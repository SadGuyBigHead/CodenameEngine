package math;

import flixel.util.FlxPool;
import openfl.geom.Vector3D as BaseVector3D;
import openfl.geom.Point;
import flixel.math.FlxAngle;

/**
 * A version of `Vector3D` that acts more like an `FlxPoint`
 * It's an abstract so it has fancy abstract overloads
 */
abstract Vector3D(BaseVector3D) from BaseVector3D to BaseVector3D
{
	public static var X_AXIS(get, never):Vector3D;
	public static var Y_AXIS(get, never):Vector3D;
	public static var Z_AXIS(get, never):Vector3D;

	// you know its technically math
	static final p = new FlxPoint();
	static final offZ:Vector3D = new BaseVector3D();
	static final offX:Vector3D = new BaseVector3D();
	static final offY:Vector3D = new BaseVector3D();

	public static function rotate2D(x:Float, y:Float, angle:Float, ?point:FlxPoint):FlxPoint
	{
		if (point == null)
			point = FlxPoint.weak();
		angle *= FlxAngle.TO_RAD;
		point.x = (x * Math.cos(angle)) - (y * Math.sin(angle));
		point.y = (x * Math.sin(angle)) + (y * Math.cos(angle));
		return point;
	}

	public static function zoomVector(vec:Vector3D, zoom:Float, xZ:Float, yZ:Float, zZ:Float):Vector3D
	{
		vec.x *= xZ * zoom;
		vec.y *= yZ * zoom;
		vec.z *= zZ * zoom;
		return vec;
	}

	public static function skewVector(vec:Vector3D, x:Float, y:Float):Vector3D
	{
		final skb = Math.tan(y * FlxAngle.TO_RAD);
		final skc = Math.tan(x * FlxAngle.TO_RAD);

		vec.y = vec.x * skb + vec.y;
		vec.x = vec.x + vec.y * skc;
		return vec;
	}

	// lazy pool
	static var pool:Array<BaseVector3D> = [];

	public inline function new(x = .0, y = .0, z = .0, w = .0)
	{
		this = Vector3D.get(x, y, z, w);
	}

	public static function get(x:Float = .0, y:Float = .0, z:Float = .0, w:Float = .0):Vector3D
	{
		final point:Vector3D = pool.pop() ?? new BaseVector3D();
		point.set(x, y, z);
		point.w = w;
		return point;
	}

	// vector values
	public var x(get, set):Float;
	public var y(get, set):Float;
	public var z(get, set):Float;
	public var w(get, set):Float;

	// who is this kid
	public var length(get, never):Float;
	public var lengthSquared(get, never):Float;

	public inline function set(x = .0, y = .0, z = .0):Vector3D
	{
		this.setTo(x, y, z);
		return this;
	}

	public inline function put():Null<Vector3D>
	{
		// kinda insane actually
		if (this != null)
			pool.push(this);
		return null;
	}

	public inline function clone()
	{
		return get(x, y, z, w);
	}

	// public inline function crossProduct(a:Vector3D)
	// {
	//	return this.crossProduct(a);
	// }
	// public inline function crossProductNew(a:Vector3D)
	// {
	//	return this.crossProduct(a);
	// }

	public inline function distance(a:Vector3D)
	{
		return BaseVector3D.distance(this, a);
	}

	public inline function dotProduct(a:Vector3D)
	{
		return this.dotProduct(a);
	}

	public inline function equals(toCompare:Vector3D, allFour:Bool = false):Bool
	{
		return this.equals(toCompare, allFour);
	}

	public inline function nearEquals(toCompare:Vector3D, tolerance:Float, allFour:Bool = false)
	{
		return this.nearEquals(toCompare, tolerance, allFour);
	}

	public inline function negate():Vector3D
	{
		this.negate();
		return this;
	}

	public inline function negateNew():Vector3D
	{
		return clone().negate();
	}

	public inline function normalize():Vector3D
	{
		this.normalize();
		return this;
	}

	static function rotate3D(vec:Vector3D, xA:Float, yA:Float, zA:Float):Vector3D
	{
		final rotateZ = rotate2D(vec.x, vec.y, zA, p);
		offZ.set(rotateZ.x, rotateZ.y, vec.z);

		final rotateX = rotate2D(offZ.z, offZ.y, xA, p);
		offX.set(offZ.x, rotateX.y, rotateX.x);

		final rotateY = rotate2D(offX.x, offX.z, yA, p);
		vec.set(rotateY.x, offX.y, rotateY.y);
		return vec;
	}

	public overload extern inline function rotate(a:Vector3D):Vector3D
	{
		return rotate3D(this, a.x, a.y, a.z);
	}

	public overload extern inline function rotate(xA:Float, yA:Float, zA:Float):Vector3D
	{
		return rotate3D(this, xA, yA, zA);
	}

	// copy
	public overload extern inline function copyFrom(a:Vector3D)
	{
		this.copyFrom(a);
		return this;
	}

	public overload extern inline function copyTo(?a:Vector3D)
	{
		if (a == null)
			return clone();
		else
			return a.set(x, y, z);
	}

	public overload extern inline function copyFrom(a:FlxPoint)
	{
		abstract.set(a.x, a.y);
		a.putWeak();
		return this;
	}

	public overload extern inline function copyTo(a:FlxPoint)
	{
		return a.set(x, y);
	}

	public overload extern inline function copyFrom(a:Point)
	{
		return set(a.x, a.y);
	}

	public overload extern inline function copyTo(a:Point)
	{
		a.setTo(x, y);
		return a;
	}

	// add
	public overload extern inline function add(x:Float = 0, y:Float = 0, z:Float = .0):Vector3D
	{
		return set(this.x + x, this.y + y, this.z + z);
	}

	public overload inline extern function add(point:Vector3D):Vector3D
	{
		add(point.x, point.y, point.z);
		return this;
	}

	public overload inline extern function add(point:FlxPoint):Vector3D
	{
		add(point.x, point.y, .0);
		point.putWeak();
		return this;
	}

	public overload inline extern function add(p:Point):Vector3D
	{
		return add(p.x, p.y, .0);
	}

	// subtract
	public overload extern inline function subtract(x:Float = 0, y:Float = 0, z:Float = .0):Vector3D
	{
		return set(this.x - x, this.y - y, this.z - z);
	}

	public overload inline extern function subtract(point:Vector3D):Vector3D
	{
		subtract(point.x, point.y, point.z);
		return this;
	}

	public overload inline extern function subtract(point:FlxPoint):Vector3D
	{
		subtract(point.x, point.y, .0);
		point.putWeak();
		return this;
	}

	public overload inline extern function subtract(p:Point):Vector3D
	{
		return subtract(p.x, p.y, .0);
	}

	// scale
	public overload extern inline function scale(x:Float = 0, y:Float = 0, z:Float = .0):Vector3D
	{
		return set(this.x * x, this.y * y, this.z * z);
	}

	public overload extern inline function scale(amount:Float):Vector3D
	{
		return scale(amount, amount, amount);
	}

	public overload inline extern function scale(point:Vector3D):Vector3D
	{
		scale(point.x, point.y, point.z);
		return this;
	}

	public overload inline extern function scale(point:FlxPoint):Vector3D
	{
		scale(point.x, point.y, 1.0);
		point.putWeak();
		return this;
	}

	public overload inline extern function scale(p:Point):Vector3D
	{
		return scale(p.x, p.y, 1.0);
	}

	public function toString():String
	{
		return '(x: $x | y: $y | z: $z)';
	}

	// ops

	@:noCompletion
	@:op(A + B)
	static inline function plusOp(a:Vector3D, b:Vector3D):Vector3D
	{
		final result = get(a.x + b.x, a.y + b.y, a.z + b.z);
		return result;
	}

	@:noCompletion
	@:op(A - B)
	static inline function minusOp(a:Vector3D, b:Vector3D):Vector3D
	{
		final result = get(a.x + b.x, a.y + b.y, a.z + b.z);
		return result;
	}

	@:noCompletion
	@:op(A * B)
	@:commutative
	static inline function scaleOp(a:Vector3D, b:Float):Vector3D
	{
		final result = get(a.x * b, a.y * b, a.z * b);
		return result;
	}

	@:noCompletion
	@:op(A / B)
	static inline function divideOp(a:Vector3D, b:Float):Vector3D
	{
		var result = get(a.x / b, a.y / b, a.z / b);
		return result;
	}

	@:noCompletion
	@:op(A * B)
	static inline function scaleOp2(a:Vector3D, b:Vector3D):Vector3D
	{
		final result = get(a.x * b.x, a.y * b.y, a.z * b.z);
		return result;
	}

	@:noCompletion
	@:op(A / B)
	static inline function divideOp2(a:Vector3D, b:Vector3D):Vector3D
	{
		var result = get(a.x / b.x, a.y / b.y, a.z / b.z);
		return result;
	}

	@:noCompletion
	@:op(A += B)
	static inline function plusEqualOp(a:Vector3D, b:Vector3D):Vector3D
	{
		return a.add(b);
	}

	@:noCompletion
	@:op(A -= B)
	static inline function minusEqualOp(a:Vector3D, b:Vector3D):Vector3D
	{
		return a.subtract(b);
	}

	@:noCompletion
	@:op(A *= B)
	static inline function scaleEqualOp(a:Vector3D, b:Float):Vector3D
	{
		return a.scale(b);
	}

	@:noCompletion
	@:op(A /= B)
	static inline function divideEqualOp(a:Vector3D, b:Float):Vector3D
	{
		return a.set(a.x / b, a.y / b, a.z / b);
	}

	@:noCompletion
	@:op(A *= B)
	static inline function scaleEqualOp2(a:Vector3D, b:Vector3D):Vector3D
	{
		return a.scale(b);
	}

	@:noCompletion
	@:op(A /= B)
	static inline function divideEqualOp2(a:Vector3D, b:Vector3D):Vector3D
	{
		return a.set(a.x / b.x, a.y / b.y, a.z / b.z);
	}

	@:noCompletion
	inline function get_x():Float
	{
		return this.x;
	}

	@:noCompletion
	inline function set_x(x:Float):Float
	{
		return this.x = x;
	}

	@:noCompletion
	inline function get_y():Float
	{
		return this.y;
	}

	@:noCompletion
	inline function set_y(y:Float):Float
	{
		return this.y = y;
	}

	@:noCompletion
	inline function get_z():Float
	{
		return this.z;
	}

	@:noCompletion
	inline function set_z(z:Float):Float
	{
		return this.z = z;
	}

	@:noCompletion
	inline function get_w():Float
	{
		return this.w;
	}

	@:noCompletion
	inline function set_w(w:Float):Float
	{
		return this.w = w;
	}

	@:noCompletion
	inline function get_length():Float
	{
		return this.length;
	}

	@:noCompletion
	inline function get_lengthSquared():Float
	{
		return this.lengthSquared;
	}

	inline static function get_X_AXIS():Vector3D
	{
		return BaseVector3D.X_AXIS;
	}

	inline static function get_Y_AXIS():Vector3D
	{
		return BaseVector3D.Y_AXIS;
	}

	inline static function get_Z_AXIS():Vector3D
	{
		return BaseVector3D.Z_AXIS;
	}
}
