package dave;

import flixel.system.FlxAssets.FlxAngelCodeAsset;
import flixel.graphics.frames.bmfont.BMFont;
import flixel.graphics.FlxGraphic;
import flixel.text.FlxBitmapFont;
// import firetongue.FireTongue;
import flixel.text.FlxBitmapText;

/**
 * This is actually the one from dde but just here
 * Note that setting the size is actually setting the scale too so like if you want to mess with that remember that one little fact
 */
class DaveBitmapText extends FlxBitmapText /* implements IDaveBitmapText */
{
	public static var fontCache = new BitmapFontCache();

	public var internalFont:FlxBitmapFont;
	//public var internalSize:Float;

	// private var fontData:FontData;
	public var size(get, set):Float;

	var _size:Float;

	public function new(?x = 0.0, ?y = 0.0, text:UnicodeString = "", ?size:Float = 8, ?font:String)
	{
		//_size = internalSize = size;
		_size = size;
		super(x, y, text, fontCache.get(font));
		this.size = size; // now we are good
	}

	// public static function getFont(text:IDaveBitmapText, font:FlxBitmapFont):FlxBitmapFont
	// {
	//	if (font != null)
	//	{
	//		text.internalFont = font;
	//		text.fontData = localeFont.get(text.internalFont.fontName, text.internalSize, true);
	//		return fontCache.get(text.fontData.name) ?? FlxBitmapFont.getDefaultFont();
	//	}
	//	else
	//	{
	//		return FlxBitmapFont.getDefaultFont();
	//	}
	// }

	override function set_font(font:FlxBitmapFont):FlxBitmapFont
	{
		// super.set_font(getFont(this, font));
		super.set_font(font);
		if (textData != null && font != null) // flixel is so cool and awesome
			setRealFontSize(_size);
		// setRealFontSize(fontData.size);
		return this.font;
	}

	function get_size():Float
	{
		return _size;
	}

	function set_size(size:Float):Float
	{
		//internalSize = size;
		// fontData = localeFont.get(internalFont.fontName, internalSize, false);
		// setRealFontSize(fontData.size);
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
	static final dontClear:Array<String> = ["consolas", //
	];

	var map:Map<String, FlxBitmapFont> = [];
	var graphics:Map<String, FlxGraphic> = [];

	public function new()
	{
	}

	public function get(id:String):FlxBitmapFont
	{
		if (map.exists(id))
			return map.get(id);

		var assetPath:String = Paths.font('bitmap/$id/$id.fnt');
		if (!Assets.exists(assetPath))
			assetPath = Paths.font('bitmap/$id/$id.xml');
		if (!Assets.exists(assetPath))
		{
			trace("[BitmapFontCache] wtf " + id, assetPath);
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

		graphic.persist = true;
		graphics.set(id, graphic);

		final font:FlxBitmapFont = FlxBitmapFont.fromAngelCode(graphicPath, assetPath);
		font.fontName = id;
		// weirdly sometimes the font size exports as negative
		font.size = FlxMath.absInt(bm.info.size);
		map.set(id, font);
		return font;
	}

	public function clear():Void
	{
		for (id in map.keys())
		{
			if (!dontClear.contains(id))
			{
				graphics.get(id).destroy();
				graphics.remove(id);
				map.remove(id);
			}
		}
	}
}

//interface IDaveBitmapText
//{
//	public var font(default, set):FlxBitmapFont;
//	public var internalFont:FlxBitmapFont;
//	public var internalSize:Int;

//	// private var fontData:FontData;
//	private function setRealFontSize(size:Int):Void;
//}
