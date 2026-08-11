package modchart.macro;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;

using haxe.macro.Tools;
using Lambda;
#end

class FlxMacro
{
	/**
	 * Related to above function, adds arrays to store draw info for rgb shaders and an modsShader field
	 * Also edits the `reset` function to reset said arrays
	 * @return Array<haxe.macro.Expr.Field>
	 */
	public static macro function buildFlxDrawBaseItem():Array<haxe.macro.Expr.Field>
	{
		var fields:Array<haxe.macro.Expr.Field> = Context.getBuildFields();

		final shaderParams:Array<String> = [
			"r",
			"g",
			"b",
			"localRotation",
			"localZoom",
			"localSkew",
			"localOrigin",
			"localPosition",
			"playFieldTransform",
			"playFieldPos",
			"rgbMix",
			"depthStuff",
			"hue",
		];
		for (f in shaderParams)
		{
			fields.push({
				name: f,
				access: [haxe.macro.Expr.Access.APublic],
				kind: FVar(macro :Array<Float>, macro []),
				pos: Context.currentPos()
			});
		}

		fields.push({
			name: "modsShader",
			access: [haxe.macro.Expr.Access.APublic],
			kind: FVar(macro :Null<modchart.NoteRenderer.ModsShader>),
			pos: Context.currentPos()
		});

		fields.push({
			name: "simpleShader",
			access: [haxe.macro.Expr.Access.APublic],
			kind: FVar(macro :Null<modchart.NoteRenderer.SimpleShader>),
			pos: Context.currentPos()
		});

		fields.push({
			name: "fov",
			access: [haxe.macro.Expr.Access.APublic],
			kind: FVar(macro :Float, macro 90.),
			pos: Context.currentPos()
		});

		for (field in fields)
		{
			switch (field.name)
			{
				case "reset":
					field.pos = Context.currentPos();
					switch field.kind
					{
						case FFun(f):
							final expr = f.expr;
							f.expr = macro
								{
									$expr;
									modsShader = null;
									simpleShader = null;
									// looks confusing im just making "ArrayTools.clear(rgbR)", "ArrayTools.clear(rgbG)", etc..
									$b{[for (i in shaderParams) macro util.ArrayTools.clear(this.$i)]}
								}
						default:
							throw "Invalid field";
					}
			}
		}

		return fields;
	}

	/**
	 * A general function for both `FlxDrawQuadsItem` and `FlxDrawTrianglesItem`
	 * It adjusts the `render` function to update rgb shader fields if it can
	 * @return Array<haxe.maro.Expr>
	 */
	public static macro function buildFlxDrawItem():Array<haxe.macro.Expr.Field>
	{
		var cls:haxe.macro.Type.ClassType = Context.getLocalClass().get();
		var fields:Array<haxe.macro.Expr.Field> = Context.getBuildFields();

		for (field in fields)
		{
			switch (field.name)
			{
				case "render":
					field.pos = Context.currentPos();
					switch (field.kind)
					{
						case FFun(f):
							final expr = f.expr;
							f.expr = macro
								{
									#if !flash
									if (simpleShader != null)
									{
										simpleShader.r.value = r;
										simpleShader.g.value = g;
										simpleShader.b.value = b;
										simpleShader.rgb_mix.value = rgbMix;
										simpleShader.hue.value = hue;
									}
									else if (modsShader != null)
									{
										modsShader.r.value = r;
										modsShader.g.value = g;
										modsShader.b.value = b;
										modsShader.rgb_mix.value = rgbMix;
										modsShader.hue.value = hue;

										modsShader.playFieldTransform.value = playFieldTransform;
										modsShader.playFieldPos.value = playFieldPos;
										modsShader.depthStuff.value = depthStuff;

										modsShader.localRotation.value = localRotation;
										modsShader.localZoom.value = localZoom;
										modsShader.localSkew.value = localSkew;
										modsShader.localOrigin.value = localOrigin;
										modsShader.localPosition.value = localPosition;

										modsShader.fov.value[0] = fov;
										shader = modsShader;
									}
									#end
									$expr;
								}
						default:
							throw "Invalid field";
					}
			}
		}

		return fields;
	}
}
