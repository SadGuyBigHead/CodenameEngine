package dave;

import flixel.system.FlxAssets.FlxAngelCodeAsset;
import flixel.graphics.frames.bmfont.BMFont;
import flixel.graphics.FlxGraphic;
import flixel.text.FlxBitmapFont;
import flixel.text.FlxBitmapText;

/**
 * This is actually the one from dde but just here
 * Note that setting the size is actually setting the scale too so like if you want to mess with that remember that one little fact
 */
class DaveBitmapText extends FlxBitmapText /* implements IDaveBitmapText */
{
	public static var fontCache = new BitmapFontCache();

	public var internalFont:FlxBitmapFont;

	public var size(get, set):Float;

	var _size:Float;

	public function new(?x = 0.0, ?y = 0.0, text:UnicodeString = "", ?size:Float = 8, ?font:String)
	{
		_size = size;

		super(x, y, text, fontCache.get(font));

		this.size = size;
	}

	override function set_font(font:FlxBitmapFont):FlxBitmapFont
	{
		super.set_font(font);

		if (textData != null && font != null) // flixel is so cool and awesome
		{
			setRealFontSize(_size);
		}

		return this.font;
	}

	function get_size():Float
	{
		return _size;
	}

	function set_size(size:Float):Float
	{
		setRealFontSize(size);

		return _size = size;
	}

	function setRealFontSize(size:Float):Void
	{
		final scale = size / font.size;
		this.scale.set(scale, scale);

		updateHitbox();
	}

	override function checkPendingChanges(useTiles:Bool = false)
	{
		super.checkPendingChanges(useTiles);
	}
}

@:access(flixel.graphics.frames.FlxBitmapFont.size)
class BitmapFontCache
{
	static final dontClear:Array<String> = ["perep", "perep_outlined"];

	var map:Map<String, FlxBitmapFont> = [];
	var graphics:Map<String, FlxGraphic> = [];
	var bye:Map<String, Bool> = [];

	public function new()
	{
	}

	public function get(id:String):FlxBitmapFont
	{
		bye.set(id, false);

		if (map.exists(id))
		{
			final font = map.get(id);
			@:privateAccess
			if (font.frame != null && !graphics.get(id).isDestroyed)
			{
				return font;
			}
		}

		var assetPath:String = Paths.font('bitmap/$id/$id.fnt');

		if (!Assets.exists(assetPath))
		{
			assetPath = Paths.font('bitmap/$id/$id.xml');
		}

		if (!Assets.exists(assetPath))
		{
			trace("[BitmapFontCache] NONEXISTENT BITMAP FONT " + id, assetPath);
			return null;
		}

		final bm:BMFont = (assetPath : FlxAngelCodeAsset).parse();

		if (bm?.pages[0]?.file == null)
		{
			trace("[BitmapFontCache] no thing " + id);
			return null;
		}

		final graphicPath = Paths.font('bitmap/$id/' + bm.pages[0].file).trim();
		final graphic:FlxGraphic = FlxG.bitmap.add(graphicPath);

		if (graphic == null)
		{
			trace("[BitmapFontCache] no graphic thing " + id);
			return null;
		}

		graphics.set(id, graphic);

		final font:FlxBitmapFont = FlxBitmapFont.fromAngelCode(graphicPath, assetPath);
		font.fontName = id;
		// weirdly sometimes the font size exports as negative
		font.size = FlxMath.absInt(bm.info.size);
		map.set(id, font);
		return font;
	}

	public function mapAsBye():Void
	{
		for (id in map.keys())
		{
			bye.set(id, true);
		}
	}

	public function clear():Void
	{
		for (id in map.keys())
		{
			final graphic = graphics.get(id);

			if (graphic == null || !dontClear.contains(id) && bye.get(id))
			{
				if (graphic != null)
				{
					FlxG.bitmap.remove(graphic);
				}

				graphics.remove(id);
				map.remove(id);
			}
		}
	}
}
