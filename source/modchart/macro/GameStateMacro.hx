package modchart.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.ComplexTypeTools;
using haxe.macro.ExprTools;
using haxe.macro.TypeTools;
using StringTools;
#end

/**
 * Binds every field with @:saveField to a field in SaveDataHandler.saveFile.data
 */
class GameStateMacro
{
	#if macro
	public static macro function build():Array<Field>
	{
		// #if !display
		// Context.info('Building Settings...', Context.currentPos());
		// #end
		var cls:haxe.macro.Type.ClassType = Context.getLocalClass().get();
		var initialFields:Array<Field> = Context.getBuildFields();
		var fields:Array<Field> = [];
		var pos = Context.currentPos();

		var states = [];

		for (field in initialFields)
		{
			if (field.meta != null)
			{
				for (m in field.meta)
				{
					if (m.name == ":toLua")
					{
						var funcName:String = field.name;
						var type:ComplexType = null;
						var expr:Expr = null;

						if (m.params != null && m.params[0] != null)
						{
							switch m.params[0].expr
							{
								case EConst(CString(s)):
									funcName = s;
								default:
									throw "Field name should be STIRNG !";
							}
						}

						// add callback
						states.push(macro
							{
								callbackList.push($v{funcName});
								modchart.lua.addCallback("__gamestate_" + $v{funcName}, $i{field.name});
							});
						break;
					}
				}
			}
			if (field.name == "new")
			{
				// edit constructor
				var args:Array<FunctionArg> = null;
				var expr:Expr = null;

				switch field.kind
				{
					case FFun(f):
						expr = f.expr;
						args = f.args;
					default:
						throw "INVLAID BITCH!";
				}
				fields.push({
					name: "new",
					access: [APublic],
					pos: pos,
					kind: FFun({
						args: args,
						expr: macro
						{
							${expr} $b{states}
						}
					})
				});
			}
			else
			{
				fields.push(field);
			}
		}

		return fields;
	}
	#end
}
