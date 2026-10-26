package dave;

// idk where to put this
import haxe.ds.Vector as BaseVector;
#if (!macro && !eval)
import cpp.NativeArray;
#end

/**
 * Adjusted vector class to allow resizing
 * On debug builds, it also throws when you try to access an index greater than the current length where it normally hard crashes
 */
@:noCustomClass
abstract Vector<T>(BaseVector<T>) from BaseVector<T> to BaseVector<T>
{
	public static inline function blit<T>(src:Vector<T>, srcPos:Int, dest:Vector<T>, destPos:Int, len:Int):Void
	{
		return BaseVector.blit(src, srcPos, dest, destPos, len);
	}

	public static inline function fromArrayCopy<T>(array:Array<T>):Vector<T>
	{
		return BaseVector.fromArrayCopy(array);
	}

	public var length(get, set):Int;

	inline function get_length():Int
	{
		return this.length;
	}

	inline function set_length(len:Int):Int
	{
		#if (macro || eval)
		final arr:Array<T> = cast this;
		arr.resize(len);
		#else
		NativeArray.setSize(cast this, len);
		#end
		return len;
	}

	public inline function new(len:Int)
	{
		this = new BaseVector(len);
	}

	@:op([]) #if !debug inline #end function get(key:Int):T
	{
		#if debug
		if (key >= this.length)
			throw "Invalid read index! (index: " + key + ", length: " + this.length + ")";
		#end
		return this[key];
	}

	@:op([]) #if !debug inline #end function set(key:Int, value:T):T
	{
		#if debug
		if (key >= this.length)
			throw "Invalid write index! (index: " + key + ", length: " + this.length + ")";
		#end
		return this[key] = value;
	}

	public inline function toArray():Array<T>
	{
		return this.toArray();
	}
}
