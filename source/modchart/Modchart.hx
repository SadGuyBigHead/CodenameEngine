package modchart;

import apple.*;
import apple.timeline.*;
import flixel.tweens.FlxEase.EaseFunction;
import flixel.util.FlxDestroyUtil;
import openfl.Vector;
#if LUA_ALLOWED
import llua.Lua;
import llua.LuaL;
import llua.State;
import llua.Convert;
import llua.Lua;
import llua.LuaCallback;
#end
import haxe.Constraints.Function;
import openfl.geom.Vector3D;
import haxe.xml.Access;
import flixel.system.FlxAssets.FlxXmlAsset;
import modchart.ArrowEffects;
#if FLX_DEBUG
import flixel.system.debug.log.LogStyle;
#end
import flixel.tweens.FlxEase.EaseFunction;
import dave.timeline.*;
import funkin.backend.system.Conductor;

using util.LuaUtil;

#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
final class Modchart extends FlxBasic
{
	static var _backend:String;
	static var _plugins:ModchartPlugins;
	static var modchartLines = 0;

	#if FLX_DEBUG
	static var logStyle = new LogStyle('[LUA] ', '00a8f3', 16, true, false);
	#end

	public var parent:ArrowEffects;
	public var timeline:Timeline;

	#if LUA_ALLOWED
	public var lua:State;
	#end

	var usePercent:Bool = true;

	var aliases = new Map<String, String>();

	var gamestate:GameState;

	var _heldFunc:Function;

	var _heldEase:EaseFunction;

	#if LUA_ALLOWED
	var luaCallbacks:Array<LuaCallback> = [];

	function _holdFunc(callback:LuaCallback)
	{
		luaCallbacks.push(callback);
		_heldFunc = Reflect.makeVarArgs(callback.call);
	}

	function _holdEase(callback:LuaCallback)
	{
		luaCallbacks.push(callback);
		_heldEase = (t:Float) -> callback.call([t]) ?? .0;
	}
	#end

	public function new(timeline:Timeline, parent:ArrowEffects, modchartPath:String)
	{
		trace("loading modchart from path?", modchartPath);
		super();
		this.timeline = timeline;
		this.parent = parent;

		// PlayState.instance?.callOnHScript("onModchart", [this]);
		if (modchartPath != null && openfl.Assets.exists(modchartPath))
		//if (false)
		{
			#if LUA_ALLOWED
			lua = LuaUtil.get();
			#end
			gamestate = new GameState(this);
			#if LUA_ALLOWED
			lua.set("debug", #if debug true #else false #end);
			lua.addCallback("__set_use_percent", v -> usePercent = v);
			lua.addCallback("__ease", ease);
			lua.addCallback("__set", set);
			lua.addCallback("__setdefault", setdefault);
			lua.addCallback("__add", add);
			lua.addCallback("__addease", addease);
			lua.addCallback("__reset", reset);
			lua.addCallback("__func", func);
			lua.addCallback("__func_ease", funcEase);
			lua.addCallback("__perframe", perframe);
			lua.addCallback("__alias", alias);
			lua.addCallback("__aux", aux);
			lua.addCallback("__node", node);
			lua.addCallback("__definemod", definemod);
			// the luajit im using is weird but probably memories better so
			lua.addCallback("__hold_func", _holdFunc);
			lua.addCallback("__hold_ease", _holdEase);
			lua.addCallback("__log", log);
			lua.addCallback("watch_add", FlxG.watch.addQuick);
			lua.addCallback("clear_log", FlxG.log.clear);
			lua.set("__gamestate_callbacks", gamestate.callbackList);
			#end

			// add things for poptions
			final mods = new Array<String>();
			for (player in 0...parent.players)
			{
				#if LUA_ALLOWED
				lua.addCallback('__getModTimerType-$player', parent.playerStates[player].setModTimerType);
				lua.addCallback('__setModTimerType-$player', parent.playerStates[player].setModTimerType);
				lua.addCallback('__resetAll-$player', parent.playerStates[player].resetAll);
				#end
				for (mod => modifier in parent.playerStates[player].mods)
				{
					if (player == 0)
						mods.push(mod);

					definemodInternal(modifier, player);
				}
			}
			#if LUA_ALLOWED
			lua.set("__mods", mods);
			lua.set("players", parent.players);

			_backend #if debug = #else ??= #end openfl.Assets.getText("assets/data/modchart/mod-backend.lua");
			if (_backend == null)
				throw "Mods backend not found.";
			// trace(_backend);
			_plugins #if debug = #else ??= #end new ModchartPlugins();

			var next = -1;
			do
			{
				final code = switch next
				{
					case -1: _backend;
					case(_ == _plugins.plugins.length) => true: openfl.Assets.getText(modchartPath);
					case i: _plugins.plugins[i].code.replace("%xero", "__add_plugin");
				}
				// trace(code);
				final result = lua.dostring(code);
				if (!result)
				{
					trace("FAIL at", next, _plugins.plugins.length);
					active = false;
					return;
				}
				next++;
			}
			while (next < _plugins.plugins.length + 1);
			lua.set("__ran", true);
			#else
			// todo: cry
			#end
		}
		else
		{
			active = false;
		}
		for (playerState in parent.playerStates)
			playerState.resetAll([]);
	}

	public function set(beat:Float, value:Float, id:String, player:Int = 0)
	{
		final mod = getMod(id, player);
		if (mod == null)
		{
			log(["[set] Mod not found:", id]);
			return;
		}
		timeline.add(new SetModEvent(mod, resolveValue(mod, value), beat));
	}

	public function setdefault(id:String, value:Float, player:Int = 0)
	{
		final mod = parent.playerStates[player]._def.mods.get(id.toLowerCase());
		if (mod == null)
		{
			log(["[setdefault] Mod not found:", id]);
			return;
		}
		mod.value = resolveValue(mod, value);
	}

	public function ease(beat:Float, length:Float, ease:EaseFunction, value:Float, id:String, player:Int = 0)
	{
		ease ??= cast _heldEase;
		if (ease == null)
		{
			trace('[EREREROER] FUCUSDFSDFJSDF', ease);
			return;
		}
		final mod = getMod(id, player);
		if (mod == null)
		{
			log(["[ease] Mod not found:", id]);
			return;
		}
		timeline.add(new EaseModEvent(mod, resolveValue(mod, value), beat, length, ease));
	}

	public function add(beat:Float, value:Float, id:String, player:Int = 0)
	{
		final mod = getMod(id, player);
		if (mod == null)
		{
			log(["[add] Mod not found:", id]);
			return;
		}
		timeline.add(new AddModEvent(mod, resolveValue(mod, value), beat));
	}

	public function addease(beat:Float, length:Float, ease:EaseFunction, value:Float, id:String, player:Int = 0)
	{
		ease ??= cast _heldEase;
		if (ease == null)
		{
			trace('[EREREROER] FUCUSDFSDFJSDF', ease);
			return;
		}
		final mod = getMod(id, player);
		if (mod == null)
		{
			log(["[add] Mod not found:", id]);
			return;
		}
		timeline.add(new AddEaseModEvent(mod, resolveValue(mod, value), beat, length, ease));
	}

	// could be shit. oh well. (todo: add touching)
	public function reset(beat:Float, length:Float, ease:EaseFunction, exclude:Array<String>, player:Int = 0)
	{
		if (length == 0)
		{
			timeline.add(new FuncEvent(beat, parent.playerStates[player].resetAll.bind(exclude)));
		}
		else
		{
			final allMods = parent.playerStates[player]._allMods;
			for (i in 0...allMods.length)
			{
				final mod = allMods[i];
				if (mod.value != parent.playerStates[player]._def._allMods[i].value)
					timeline.add(new EaseModEvent(mod, parent.playerStates[player]._def._allMods[i].value, beat, length, ease ?? cast _heldEase));
			}
		}
	}

	public function func(beat:Float, func:Void->Void)
	{
		func ??= cast _heldFunc;
		timeline.func(beat, func);
	}

	public function funcEase(beat:Float, length:Float, ease:EaseFunction, beginPercent:Float, endPercent:Float, func:Float->Void)
	{
		ease ??= cast _heldEase;
		func ??= cast _heldFunc;
		timeline.funcEase(beat, length, ease, beginPercent, endPercent, func);
	}

	public function perframe(beat:Float, length:Float, func:Float->Void)
	{
		func ??= cast _heldFunc;
		timeline.perframe(beat, length, func);
	}

	public function alias(name:String, mod:String)
	{
		aliases.set(mod.toLowerCase(), name.toLowerCase());
	}

	// stupid idiot ways of doing this. whatever
	public function definemod(name:String, percents:Array<Float>, mods:Array<String>)
	{
		aux(name);
		// safe guard for c++ exception
		for (id in mods)
		{
			for (plr in 0...parent.playerStates.length)
			{
				if (getMod(id, plr) == null)
					aux(id);
			}
		}
		final mods = new Vector(parent.playerStates.length * mods.length, true, [for (plr in 0...parent.playerStates.length) for (id in mods) getMod(id, plr)]);
		final auxed = new Vector(parent.playerStates.length, true, [for (plr in 0...parent.playerStates.length) getMod(name, plr)]);
		for (i in 0...percents.length)
			percents[i] = resolveValue(mods[i], percents[i]); // probably bad but idc
		node([name], (plr, undo, run) ->
		{
			for (i in 0...percents.length)
				mods[i + (plr * percents.length)].value += percents[i] * auxed[plr].value * (undo ? -1 : 1);
		});
	}

	public function aux(name:String)
	{
		for (plr in 0...parent.playerStates.length)
		{
			final playerState = parent.playerStates[plr];
			auxInternal(name, plr, new NodeModifier(name, playerState), new NodeModifier(name, playerState));
		}
	}

	function auxInternal(name:String, plr:Int, mod:Modifier, ?defmod:Modifier)
	{
		final playerState = parent.playerStates[plr];
		if (Std.isOfType(mod, NodeModifier))
			playerState.auxes.set(name.toLowerCase(), cast mod);
		playerState.addMod(definemodInternal(mod, plr));
		if (defmod != null)
			playerState._def.addMod(defmod); // lol
	}

	public function node(args:Array<String>, func:NodeCallback)
	{
		func ??= cast _heldFunc;
		for (plr in 0...parent.playerStates.length)
		{
			final playerState = parent.playerStates[plr];
			final handler = new ModNode([for (mod in args) parent.playerStates[plr].auxes.get(mod.toLowerCase())], func, playerState);
			playerState.nodes.push(handler);
		}
	}

	public function scriptedAux(name:String, inPlayers:Bool = false):ScriptedModifier
	{
		for (plr in 0...parent.playerStates.length)
		{
			final playerState = parent.playerStates[plr];
			final mod = new ScriptedModifier(name, playerState, false);
			auxInternal(name, plr, mod, inPlayers ? new ScriptedModifier(name, playerState, false) : null);

			if (!inPlayers)
				return mod;
		}
		return null;
	}

	/**
		// * Defines all relevant functions to an hscript function for nicesnes
		// * @param hscript 
		// */
	// public function implementToHScript(hscript:HScript)
	// {
	//	hscript.set("set", set);
	//	hscript.set("ease", ease);
	//	hscript.set("add", add);
	//	hscript.set("addease", addease);
	//	hscript.set("reset", reset);
	//	timeline.implementToHScript(hscript);
	//	hscript.set("alias", alias);
	//	hscript.set("aux", aux);
	//	hscript.set("node", node);
	//	hscript.set("definemod", definemod);
	//	hscript.set("scriptedAux", scriptedAux);
	//	hscript.set("defineObjectMods", defineObjectMods);
	//	hscript.set("defineSpriteMods", defineSpriteMods);
	//	hscript.set("GameState", gamestate);
	// }

	public function defineObjectMods(name:String, object:FlxObject)
	{
		auxInternal(name + "x", 0, new FlxObjectXModifier(name, parent.playerStates[0], object));
		auxInternal(name + "y", 0, new FlxObjectYModifier(name, parent.playerStates[0], object));
		auxInternal(name + "angle", 0, new FlxObjectAngleModifier(name, parent.playerStates[0], object));
	}

	public function defineSpriteMods(name:String, sprite:FlxSprite)
	{
		defineObjectMods(name, sprite);
		auxInternal(name + "scalex", 0, new FlxSpriteScaleXModifier(name, parent.playerStates[0], sprite));
		auxInternal(name + "scaley", 0, new FlxSpriteScaleYModifier(name, parent.playerStates[0], sprite));
	}

	public function definePlayStateMods(name:String, playState:PlayState)
	{
		auxInternal("zoom", 0, new PlayStateZoomModifier(name, parent.playerStates[0], playState));
	}

	// sets lua stuff for poptions
	function definemodInternal(modifier:Modifier, player:Int):Modifier
	{
		final mod = modifier.id.toLowerCase();
		#if LUA_ALLOWED
		if (lua != null)
		{
			lua.addCallback('__get_$mod-$player', modifier.get_value);
			lua.addCallback('__set_$mod-$player', modifier.set_value);
			lua.set('__isPercent_$mod-$player', modifier.isPercent);
		}
		#end
		return modifier;
	}

	function _sort(a:TimelineEvent, b:TimelineEvent)
	{
		if (a.beat < b.beat)
			return -1;
		else if (a.beat > b.beat)
			return 1;
		return 0;
	}

	inline function getMod(id:String, player:Int)
	{
		id = id.toLowerCase();
		id = aliases.get(id) ?? id;
		return parent.playerStates[player].mods.get(id.toLowerCase());
	}

	var _lastBeat:Float = -9999;

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		callLuaUpdate();
	}

	function callLuaUpdate()
	{
		#if LUA_ALLOWED
		if (lua == null)
			return;
		Lua.getglobal(lua, "update");
		if (Lua.type(lua, -1) == Lua.LUA_TFUNCTION)
		{
			if (Lua.pcall(lua, 0, 0, 0) != 0)
			{
				final error = Lua.tostring(lua, -1);
				log(['[update] $error']);
			}
		}
		Lua.pop(lua, -1);
		#end
	}

	function resolveValue(mod:Modifier, value:Float):Float
	{
		if (mod.isPercent && usePercent)
			return value / 100;
		else
			return value;
	}

	inline function log(data:Array<Dynamic>)
	{
		#if FLX_DEBUG
		try
		{
			final str = data.join(",\t");
			FlxG.log.advanced(str, logStyle);
			trace(str);
		}
		catch (e)
		{
			trace(e);
		}
		#end
	}

	override function destroy()
	{
		super.destroy();
		#if LUA_ALLOWED
		if (lua != null)
		{
			for (callback in luaCallbacks)
				callback?.dispose();
			Lua.close(lua);
			lua = null;
		}
		#end
		_heldEase = null;
		_heldFunc = null;
	}
}

class ModEvent extends TimelineEvent
{
	var modifier:Modifier;
	var value:Float;
	var initialVal:Float;

	public function new(modifier:Modifier, value:Float, beat:Float)
	{
		super(beat);
		this.modifier = modifier;
		this.value = value;
	}
}

class SetModEvent extends ModEvent
{
	override function run(beat:Float):Bool
	{
		if (beat >= this.beat)
		{
			initialVal = modifier.value;
			modifier.value = value;
			return true;
		}
		return false;
	}
}

class AddModEvent extends SetModEvent
{
	override function run(beat:Float):Bool
	{
		if (beat >= this.beat)
		{
			modifier.value += value;
			return true;
		}
		return false;
	}
}

class EaseModEvent extends SetModEvent
{
	public var length:Float;
	public var ease:EaseFunction;

	var started:Bool;
	var lastVal:Float;

	public function new(modifier:Modifier, value:Float, beat:Float, length:Float, ease:EaseFunction)
	{
		super(modifier, value, beat);
		this.length = length;
		this.ease = ease;
	}

	override function run(time:Float):Bool
	{
		if (time >= beat)
		{
			final t = Math.min(1.0, (time - beat) / length);
			if (!started)
			{
				started = true;
				initialVal = lastVal = modifier.value;
			}
			final val = FlxMath.lerp(initialVal, value, ease(t));
			modifier.value += val - lastVal; // relative easing :)
			lastVal = val;
			// trace("easey", modifier, ease(.5));
			return t >= 1;
		}
		return false;
	}
}

class AddEaseModEvent extends EaseModEvent
{
	override function run(time:Float):Bool
	{
		if (time >= beat)
		{
			final t = Math.min(1.0, (time - beat) / length);
			if (!started)
			{
				started = true;
				initialVal = lastVal = modifier.value;
			}
			final val = FlxMath.lerp(initialVal, initialVal + value, ease(t));
			modifier.value += val - lastVal; // relative easing :)
			lastVal = val;
			// trace("easey", modifier, ease(.5));
			return t >= 1;
		}
		return false;
	}
}

typedef NodeCallback = (player:Int, undo:Bool, run:Bool) -> Void;

class ModNode
{
	public var dirty:Bool;
	public var callback:NodeCallback;

	var mods:Vector<NodeModifier>;
	var playerState:PlayerState;

	public function new(mods:Array<NodeModifier>, callback:NodeCallback, playerState:PlayerState)
	{
		this.mods = new Vector<NodeModifier>(mods.length, true, mods);
		this.callback = callback;
		for (mod in this.mods)
			mod.node = this;
	}
}

// simple modifier that just carries a value
class ScriptedModifier extends Modifier
{
	var _value:Float;

	public function new(id:String, playerState:PlayerState, isPercent:Bool)
	{
		super(id, playerState, isPercent);
	}

	override function get_value():Float
	{
		return _value;
	}

	override function set_value(v:Float):Float
	{
		return _value = v;
	}
}

class NodeModifier extends ScriptedModifier
{
	public var node:ModNode;

	public function new(id:String, playerState:PlayerState)
	{
		super(id, playerState, true);
	}

	override function set_value(v:Float):Float
	{
		if (node != null)
			node.dirty = true;
		return _value = v;
	}
}

class SimpleDefineModifier extends ScriptedModifier
{
	var _len:Int;
	var mods:Vector<Modifier>;
	var values:Vector<Float>;

	public function new(id:String, playerState:PlayerState, mods:Array<Modifier>, values:Array<Float>)
	{
		super(id, playerState, true);
		_len = values.length;
		this.mods = new Vector<Modifier>(mods.length, true, mods);
		this.values = new Vector<Float>(values.length, true, values);
	}

	override function set_value(v:Float):Float
	{
		for (i in 0..._len)
			mods[i].value = values[i];
		return _value = v;
	}
}

#if LUA_ALLOWED
@:build(modchart.macro.GameStateMacro.build())
#end
class GameState
{
	public var callbackList:Array<String> = [];

	var modchart:Modchart;
	var _vec = new Vector3D();
	var _rot = new Vector3D();

	public function new(modchart:Modchart)
	{
		this.modchart = modchart;
	}

	@:toLua
	public function GetCurBPS():Float
	{
		return Conductor.instance.bpm / 60;
	}

	@:toLua
	public function GetSongBeat():Float
	{
		return Conductor.instance.curBeatFloat;
	}

	@:toLua
	public function GetSongBeatVisible():Float
	{
		return GetSongBeat();
	}

	@:toLua
	public function GetSongTime():Float
	{
		return Conductor.instance.songPosition / 1000;
	}

	@:toLua
	public function GetSongTimeVisible():Float
	{
		return GetSongTime();
	}

	@:toLua
	public function GetTicks():Float
	{
		return FlxG.game.ticks;
	}

	@:toLua
	public function GetElapsed():Float
	{
		return FlxG.elapsed;
	}

	// @:toLua
	// public function GetFpsFix():Float {
	//	return Main.fpsFix;
	// }
	// todo later: this
	// @:toLua
	// public function GetX(playerNumber:Int, column:Int, yOffset:Float):Float {
	//	return modpos(playerNumber, column, yOffset).x;
	// }
	// @:toLua
	// public function GetY(playerNumber:Int, column:Int, yOffset:Float):Float {
	//	return modpos(playerNumber, column, yOffset).y;
	// }
	// @:toLua
	// public function GetZ(playerNumber:Int, column:Int, yOffset:Float):Float {
	//	return modpos(playerNumber, column, yOffset).z;
	// }
	// @:toLua
	// public function GetDrawDistance():Float {
	//	return modchart.parent.gameField.drawDistance;
	// }
	// @:toLua
	// public function SetDrawDistance(playerNumber:Int, drawDistance:Float):Float {
	//	return modchart.parent.gameField.drawDistance = drawDistance;
	// }
	// stupid to get everything when we just need one but whatever
	// inline function modpos(playerNumber:Int, column:Int, yOffset:Float) {
	//	modchart.parent.position.getModPosition(modchart.parent.playerStates[playerNumber], column, 0, null, _vec, _rot, yOffset);
	//	return _vec;
	// }
}

class ModchartPlugins
{
	public var plugins:Array<{version:String, author:String, code:String}> = [];

	public function new()
	{
		final p = "assets/data/modchart/Plugins/PLUGINLIST.txt";
		if (openfl.Assets.exists(p))
		{
			final list = [
				for (i in openfl.Assets.getText(p).split('\n'))
					i.trim()
			];
			for (plugin in list)
			{
				trace('Loading plugin', '$plugin');
				final path = "assets/data/modchart/Plugins/" + plugin + ".xml";
				if (openfl.Assets.exists(path))
				{
					final xml:Access = new Access(((openfl.Assets.getText(path)) : FlxXmlAsset).getXml().firstElement());
					plugins.push({version: xml.att.Version, author: xml.att.Author, code: xml.att.LoadCommand});
				}
				else
				{
					trace("oh", path, plugin);
				}
			}
		}
		else
		{
			trace("end it all");
		}
	}
}
