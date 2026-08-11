package modchart.macro;

import haxe.macro.Context;

@:allow(modchart)
class FuckHelper
{
	static macro function __fuck(transform:haxe.macro.Expr, arr:Array<haxe.macro.Expr>)
	{
		final exprs = [];
		for (expr in arr)
		{
			final exprf = macro $expr * 4;
			exprs.push(macro
				{
					$b
					{
						[
							for (i in 0...4)
							{
								final m = (i : Channel).multiplier();
								final o = (i : Channel).offset();
								macro
								{
									@:privateAccess
									{
										$
										{
											if ((i : Channel) == ALPHA)
											{
												macro
												{
													drawItem.colorMultipliers[colorMultipliersLength + $exprf + $v{i}] = 1.0;
													drawItem.alphas[alphasLength + $expr + $v{i}] = $transform.$m;
												}
											}
											else
											{
												macro drawItem.colorMultipliers[colorMultipliersLength + $exprf + $v{i}] = $transform.$m;
											}
										}
										drawItem.colorOffsets[colorOffsetsLength + $exprf + $v{i}] = $transform.$o;
									}
								}
							}
						]
					}
				});
		}
		return macro
		{$b{exprs}}
	}

	static macro function __fuckNotes(arr:Array<haxe.macro.Expr>)
	{
		final exprs = [];
		for (expr in arr)
		{
			final exprt = macro $expr * 3;
			for (i in 0...3)
			{
				final dn = (i : Channel).noteColor();
				final tn = (i : Channel).toString().substr(0, 1);
				exprs.push(macro
					{
						$b
						{
							[
								for (i in 0...3)
								{
									final c = (i : Channel).flxColor();
									macro
									{
										@:privateAccess
										{
											drawItem.$dn[${Context.parse(dn + "Length", Context.currentPos())} + $exprt + $v{i}] = rgbColor.$tn.$c;
										}
									}
								}
							]
						}
					});
			}
		}
		return macro
		{$b{exprs}}
	}

	static macro function __noFuckNotes(offset:haxe.macro.Expr)
	{
		final exprs = [];
		for (i in 0...(6 * 4))
		{
			final exprt = macro $v{i * 3};
			for (i in 0...3)
			{
				final dn = (i : Channel).noteColor();
				final tn = (i : Channel).toString().substr(0, 1);
				exprs.push(macro
					{
						$b
						{
							[
								for (i in 0...3)
								{
									final c = (i : Channel).flxColor();
									macro
									{
										@:privateAccess
										{
											drawItem.$dn[${Context.parse(dn + "Length", Context.currentPos())} + $exprt + $v{i} + $offset] = rgbColor.$tn.$c;
										}
									}
								}
							]
						}
					});
			}
		}
		return macro
		{$b{exprs}}
	}

	// unused, was made for gapples glowing holds when rendering without mods
	// static macro function __fuckHelper(distance:haxe.macro.Expr, arr:Array<haxe.macro.Expr>)
	// {
	//	final exprs = [];
	//	for (expr in arr)
	//	{
	//		final expr = macro $expr * 4;
	//		exprs.push(macro
	//			{
	//				_tmpTransform.reset();
	//				setupColorTransform(_tmpTransform, ${distance});
	//				// we can assume that redOffset will equal the other offsets if we aren't using mods
	//				$b
	//				{
	//					[
	//						for (i in 0...3)
	//							macro this.drawColorOffsets[$expr + $v{i}] = _tmpTransform.redOffset
	//					]
	//				}
	//				this.drawColorMults[$expr + 3] = _tmpTransform.alphaMultiplier;
	//			});
	//	}
	//	return macro
	//	{$b{exprs}}
	// }

	static macro function __noFuckHelper()
	{
		final exprs = [];
		for (i in 0...6 * 4 * 2)
		{
			final channel:Channel = i % 4;
			final mult = '${channel}Multiplier';
			final ofs = '${channel}Offset';
			exprs.push(macro
				{
					drawColorMults[$v{i}] = _tmpTransform.$mult;
					drawColorOffsets[$v{i}] = _tmpTransform.$ofs;
				});
		}
		return macro
		{$b{exprs}}
	}
}

#if macro
enum abstract Channel(Int) from Int to Int
{
	var RED;
	var GREEN;
	var BLUE;
	var ALPHA;

	@:to
	public function toString()
	{
		return switch abstract
		{
			case RED: "red";
			case GREEN: "green";
			case BLUE: "blue";
			case ALPHA: "alpha";
		}
	}

	public function multiplier()
	{
		return '${abstract}Multiplier';
	}

	public function offset()
	{
		return '${abstract}Offset';
	}

	public function noteColor()
	{
		return '${abstract}'.substr(0, 1);
	}

	public function flxColor()
	{
		return '${abstract}Float';
	}
}
#end
