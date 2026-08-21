package util;

import haxe.Constraints.Function;
#if LUA_ALLOWED
import llua.Lua;
import llua.LuaL;
import llua.State;
import llua.Convert;
#end

class LuaUtil
{
	#if LUA_ALLOWED
	public static function get():State
	{
		final lua = LuaL.newstate();
		LuaL.openlibs(lua);
		Lua.init_callbacks(lua);
		return lua;
	}

	public static function dostring(lua:State, file:String):Bool
	{
		trace('loading lua string');
		if (file == null)
			throw "Invalid (null) lua string";
		else if (file.length <= 0)
			file = "--"; // it yells at you when its not like this
		final result = LuaL.dostring(lua, file);
		final resultStr = Lua.tostring(lua, result);
		if (resultStr != null && result != 0)
		{
			lime.app.Application.current.window.alert(resultStr, 'Error on .LUA script!');
			trace('Error on .LUA script! ' + resultStr);
			return false;
		}
		trace('Lua file loaded succesfully');
		return true;
	}

	public static function set<T>(lua:State, key:String, data:T)
	{
		Convert.toLua(lua, data);
		Lua.setglobal(lua, key);
	}

	public static function call(lua:State, event:String, args:Array<Dynamic>):Dynamic
	{
		Lua.getglobal(lua, event);

		for (arg in args)
			Convert.toLua(lua, arg);

		var result:Null<Int> = Lua.pcall(lua, args.length, 1, 0);
		if (result != null)
		{
			/*var resultStr:String = Lua.tostring(lua, result);
				var error:String = Lua.tostring(lua, -1);
				Lua.pop(lua, 1); */
			if (Lua.type(lua, -1) == Lua.LUA_TSTRING)
			{
				var error:String = Lua.tostring(lua, -1);
				Lua.pop(lua, 1);
				if (error == 'attempt to call a nil value')
				{ // Makes it ignore warnings and not break stuff if you didn't put the functions on your lua file
					return null;
				}
			}

			var conv:Dynamic = Convert.fromLua(lua, result);
			return conv;
		}
		return null;
	}

	public static function addCallback(lua:State, callback:String, func:Function):Void
	{
		Lua_helper.add_callback(lua, callback, func);
	}
	#end
}
