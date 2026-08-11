package modchart.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.ComplexTypeTools;
using haxe.macro.ExprTools;
using haxe.macro.TypeTools;
using StringTools;
#end

enum abstract ModifierMacroType(String) from String
{
	var FLOAT = "float";
	var BOOL = "bool";
}

enum abstract ModifierType(String) from String
{
	var MODIFIER = "modifier";
	var PLAYFIELD = "playfield";
	var OBJECT = "object";
}

/**
 * automatically makes a modifier class that sets a value
 */
class ModifierMacro
{
	#if macro
	public static macro function build(type:Expr):Array<Field>
	{
		// #if !display
		// #end
		final type:ModifierMacroType = type.getValue();
		var cls:haxe.macro.Type.ClassType = Context.getLocalClass().get();
		var initialFields:Array<Field> = Context.getBuildFields();
		var fields:Array<Field> = [].concat(initialFields);
		var pos = Context.currentPos();

		if (cls.meta?.get() != null)
		{
			for (m in cls.meta.get())
			{
				if (m.name == ":modifier")
				{
					final modField:String = m.params[0].getValue();
					final valueType:ModifierType = cast m.params[1]?.getValue() ?? MODIFIER;
					final useValueOffset:Bool = m.params[2]?.getValue() ?? true;
					final fieldExpr = (valueType == PLAYFIELD) ? 'playerState.playField.$modField' : 'object.$modField';
					if (valueType != MODIFIER && type != BOOL && useValueOffset)
					{
						fields.push({
							name: "new",
							access: [APublic, AOverride],
							kind: FFun({
								args: [
									{name: "id", type: macro :String},
									{name: "playerState", type: macro :modchart.ArrowEffects.PlayerState},
									{name: "isPercent", type: macro :Bool, value: macro true}
								],
								expr: macro
								{
									super(id, playerState, isPercent);
									valueOffset = ${Context.parse(fieldExpr, Context.currentPos())};
								}
							}),
							pos: Context.currentPos(),
						});
					}
					fields.push({
						name: "get_value",
						access: [APrivate, AOverride],
						kind: FFun({
							args: [],
							ret: macro :Float,
							expr: switch valueType
							{
								case PLAYFIELD, OBJECT:
									switch type
									{
										case FLOAT: macro
											{
												return ${Context.parse(fieldExpr, Context.currentPos())} -valueOffset;
											}
										case BOOL: macro
											{
												return ${Context.parse(fieldExpr, Context.currentPos())} ?1.0:0.0;
											}
									}
								case MODIFIER:
									switch type
									{
										case FLOAT: macro return playerState.$modField;
										case BOOL: macro return playerState.$modField ? 1.0 : 0.0;
									}
							}
						}),
						pos: pos,
					});
					fields.push({
						name: "set_value",
						access: [APrivate, AOverride],
						kind: FFun({
							args: [{name: "value", type: macro :Float}],
							expr: switch valueType
							{
								case PLAYFIELD, OBJECT:
									switch type
									{
										case FLOAT: macro
											{
												${Context.parse(fieldExpr, Context.currentPos())} = value + valueOffset;
												return value;
											}
										case BOOL: macro
											{
												${Context.parse(fieldExpr, Context.currentPos())} = value != 0.0;
												return get_value();
											}
									}
								case MODIFIER:
									switch type
									{
										case FLOAT: macro return playerState.$modField = value;
										case BOOL: macro
											{
												playerState.$modField = value != 0.0;
												return get_value();
											}
									}
							}
						}),
						pos: pos,
					});
				}
			}
		}

		return fields;
	}
	#end
}
