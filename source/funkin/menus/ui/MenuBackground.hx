package funkin.menus.ui;

class MenuBackground extends FlxSprite
{
	public static var folder:String = "menubgs";

	public var id:String = "";

	public function new(idOverride:String = "", folderOverride:String = "")
	{
		super();

		if (idOverride != "")
		{
			id = idOverride;
		}
		else
		{
			var bgNames = Paths.getFolderContent('images/menus/menubgs', false, "BOTH", true);
			var value = FlxG.random.int(0, bgNames.length - 1);
			id = bgNames[value];
		}

		var locFolder = folder;
		if (folderOverride != "")
		{
			locFolder = folderOverride;
		}

		loadGraphic(Paths.image("menus/" + locFolder + "/" + id));

		scale.set(1.05, 1.05);
		updateHitbox();
		scrollFactor.set(0, 0);
		screenCenter();

		antialiasing = Options.antialiasing;
	}
}
