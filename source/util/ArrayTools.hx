package util;

class ArrayTools
{
	/**
	 * Clears this array in place
	 * @param array 
	 * @return Array<T>
	 */
	public static function clear<T>(array:Array<T>):Array<T>
	{
		while (array.length > 0)
			array.pop();
		return array;
	}

	public static function clearDuplicates<T>(array:Array<T>, ?clean:Bool = true):Array<T>
	{
		for (i => element in array)
		{
			var index = -1;
			while ((index = array.lastIndexOf(element)) != -1 && index != i)
			{
				if (clean)
					array.splice(index, 1);
				else
					array[index] = null;
			}
		}
		return array;
	}
}
