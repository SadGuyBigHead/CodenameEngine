package funkin.menus;

import funkin.backend.system.Conductor;
import funkin.menus.ui.MenuBackground;
import flixel.sound.FlxSoundData;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.backend.chart.Chart;
import funkin.backend.chart.ChartData.ChartMetaData;
import funkin.backend.scripting.events.menu.MenuChangeEvent;
import funkin.backend.scripting.events.menu.freeplay.*;
import funkin.game.HealthIcon;
import funkin.savedata.FunkinSave;
import funkin.backend.system.Conductor;
import funkin.backend.system.Controls.Control;
import funkin.backend.TurboControls;
import funkin.backend.assets.ModsFolder;
import funkin.backend.assets.ModsFolderLibrary;
import funkin.backend.assets.IModsAssetLibrary;
import funkin.backend.assets.AssetSource;
import flixel.text.FlxBitmapText;
import dave.DaveBitmapText;
import funkin.backend.shaders.CustomShader;
import flixel.util.FlxSort;

using StringTools;

class FreeplayState extends MusicBeatState
{
	/**
	 * Array containing all of the songs' metadata.
	 */
	public var songs:Array<ChartMetaData> = [];

	/**
	 * Current song metadata
	 */
	public var curSong:Null<ChartMetaData>;

	/**
	 * Currently selected song
	 */
	public var curSelected:Int = 1;

	/**
	 * Currently selected coop/opponent mode
	 */
	public var curCoopMode:Int = 0;

	/**
	 * Assigned FreeplaySonglist item.
	 */
	public var songList:FreeplaySonglist;

	/**
	 * Background.
	 */
	public var bg:MenuBackground;

	/**
	 * Whenever the player can navigate and select
	 */
	public var canSelect:Bool = true;

	/**
	 * Group containing all of the alphabets
	 */
	public var grpSongs:FlxTypedGroup<Alphabet>;

	/**
	 * Whenever the currently selected song is playing.
	 */
	public var curPlaying:Bool = false;

	/**
	 * Array containing all of the icons.
	 */
	public var iconArray:Array<HealthIcon> = [];

	/**
	 * FlxInterpolateColor object for smooth transition between Freeplay colors.
	 */
	public var interpColor:FlxInterpolateColor;

	public var upTurboControl:TurboControls;
	public var downTurboControl:TurboControls;
	public var turboBasics:Array<TurboBasic>;

	public var interpColorTwo:FlxInterpolateColor;

	public var bgShader = new CustomShader("stillgradient");

	public var accstrhead = "Best Accuracy";

	var accBacker:FlxSprite;
	var accBack:FlxSprite;
	var accText:FlxBitmapText;
	var oppBacker:FlxSprite;
	var oppBack:FlxSprite;
	var oppText:FlxBitmapText;
	var targAcc:Float = 0;
	var lerpAcc:Float = 0;
	var tempacolor:FlxColor;
	var tempaSlect:Int = -1;

	public var vinylGraphic:FlxSprite;

	var curVinylId:String;

	var headerLocations:Array<Int> = [];

	override function create()
	{
		//CoolUtil.playMenuSong();

		accstrhead = TU.translate("freeplay.acchead");
		songList = FreeplaySonglist.get();
		songs = songList.songs;

		for (k => s in songs)
		{
			if (s.name == Options.freeplayLastSong)
			{
				curSelected = k;
			}

			// PRELOAD VINYL IMAGES
			Paths.image("menus/vinyls/" + s.vinylId);
		}

		updateCurSong();

		DiscordUtil.call("onMenuLoaded", ["Freeplay"]);

		upTurboControl = new TurboControls([Control.UP]);
		downTurboControl = new TurboControls([Control.DOWN]);
		turboBasics = [upTurboControl, downTurboControl];

		for (basic in turboBasics)
		{
			basic.delay = 0.6;
			basic.interval = 0.08;
		}

		super.create();

		bg = new MenuBackground();
		bg.setGraphicSize(FlxG.width, FlxG.height);
		bg.scale.set(1, 1);
		bg.updateHitbox();
		bg.screenCenter();
		tempacolor = curSong.color;
		interpColor = new FlxInterpolateColor(curSong.color);
		interpColorTwo = new FlxInterpolateColor(curSong.color);
		bg.color = FlxColor.WHITE;
		bgShader.hset("colora", [curSong.color.redFloat, curSong.color.greenFloat, curSong.color.blueFloat]);
		bgShader.hset("colorb", [curSong.color.redFloat, curSong.color.greenFloat, curSong.color.blueFloat]);
		bgShader.hset("angle", 0);
		bg.shader = bgShader;
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i].displayName, "bold");
			songText.menuScrollMode = AlphabetMenuScrollMode.DSHAPE;
			songText.isMenuItem = true;
			songText.targetY = i;
			var leng = songs[i].displayName.length;
			if (leng >= 12)
			{
				songText.scale.set(1 - (0.05 * (leng - 11)), 1);
				songText.updateHitbox();
			}
			grpSongs.add(songText);

			var icon:HealthIcon = new HealthIcon(songs[i].icon);
			icon.sprTracker = songText;

			if (songs[i]._isHeader)
			{
				headerLocations.push(i);
				songText.scale.set(0.8, 0.8);
				songText.updateHitbox();
			}

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);
		}

		curVinylId = curSong.vinylId;
		vinylGraphic = new FlxSprite(-360, 0).loadGraphic(Paths.image("menus/vinyls/" + curVinylId));
		vinylGraphic.setGraphicSize(720, 720);
		vinylGraphic.updateHitbox();
		vinylGraphic.x = -360;
		vinylGraphic.y = 0;
		vinylGraphic.antialiasing = Options.antialiasing;
		add(vinylGraphic);

		accBacker = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		accBacker.alpha = 0.2;
		add(accBacker);

		accBack = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		accBack.alpha = 0.4;
		add(accBack);

		accText = new DaveBitmapText(0, 16, accstrhead + '\n0.00%', 64 * .4, "perep");
		accText.antialiasing = Options.antialiasing;
		accText.letterSpacing = 2;
		accText.alignment = FlxTextAlign.CENTER;
		add(accText);

		oppBacker = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		oppBacker.alpha = 0.2;
		add(oppBacker);

		oppBack = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		oppBack.alpha = 0.4;
		add(oppBack);

		oppText = new DaveBitmapText(0, 16, "[TAB] Standard", 64 * .4, "perep");
		oppText.antialiasing = Options.antialiasing;
		oppText.letterSpacing = 2;
		oppText.alignment = FlxTextAlign.RIGHT;
		add(oppText);

		updateAccBackScale();

		for (songi in songs)
		{
			if (Reflect.hasField(songi.customValues, "colorTwo"))
			{
				songi.customValues.colorTwo = FlxColor.fromString(songi.customValues.colorTwo);
			}
		}

		changeSelection(0, true);
		changeCoopMode(0, true);
	}

	#if PRELOAD_ALL
	/**
	 * How much time a song stays selected until it autoplays.
	 */
	public var timeUntilAutoplay:Float = 0.75;

	/**
	 * Whenever the song autoplays when hovered over.
	 */
	public var disableAutoPlay:Bool = false;

	/**
	 * Whenever the autoplayed song gets async loaded.
	 */
	public var disableAsyncLoading:Bool = #if desktop false #else true #end;

	/**
	 * Time elapsed since last autoplay. If this time exceeds `timeUntilAutoplay`, the currently selected song will play.
	 */
	public var autoplayElapsed:Float = 0;

	/**
	 * Whenever the currently selected song instrumental is playing.
	 */
	public var songInstPlaying:Bool = true;

	/**
	 * Path to the currently playing song instrumental.
	 */
	public var curPlayingInst:String = null;

	/**
	 * If it should play the song automatically.
	 */
	public var autoplayShouldPlay:Bool = true;
	#end

	override function update(elapsed:Float)
	{
		if (tempaSlect != curSelected)
		{
			if (Reflect.hasField(curSong.customValues, "colorTwo"))
			{
				tempacolor = curSong.customValues.colorTwo;
			}
			else
			{
				tempacolor = curSong.color;
			}

			tempaSlect = curSelected;
		}

		interpColor.fpsLerpTo(curSong.color, 0.0625);
		interpColorTwo.fpsLerpTo(tempacolor, 0.0625);

		bgShader.hset("colora", [interpColor.red, interpColor.green, interpColor.blue]);
		bgShader.hset("colorb", [interpColorTwo.red, interpColorTwo.green, interpColorTwo.blue]);

		targAcc = FunkinSave.getSongHighscore(curSong.name, "normal").accuracy * 100;
		lerpAcc = CoolUtil.fpsLerp(lerpAcc, targAcc, 0.1);
		accText.text = accstrhead + "\n" + formatAccuracy(lerpAcc) + "%";

		updateAccBackScale();

		super.update(elapsed);

		if (vinylGraphic != null)
		{
			vinylGraphic.angle += elapsed * (Conductor.instance.bpm / 18);
		}

		if (FlxG.sound.music != null && FlxG.sound.music.volume < 0.7 && (disableAutoPlay || songInstPlaying))
		{
			FlxG.sound.music.volume = Math.max(.7, FlxG.sound.music.volume + .9 * elapsed);
		}

		var selectedAnotherSong:Bool = false;
		if (canSelect)
		{
			var changer = (controls.UP_P ? -1 : 0) + (controls.DOWN_P ? 1 : 0) - FlxG.mouse.wheel;

			if (changer != 0)
			{
				if (FlxG.keys.pressed.CONTROL)
				{
					changeToCategoryInDirection(changer);
				}
				else
				{
					changeSelection(changer);
				}
			}

			changeCoopMode((controls.CHANGE_MODE ? 1 : 0));

			if (FlxG.mouse.justPressed && grpSongs != null)
			{
				for (index => sprite in grpSongs.members)
				{
					if (curSelected != index && FlxG.mouse.overlaps(sprite))
					{
						changeSelection(index - curSelected);
						selectedAnotherSong = true;
						break;
					}
				}
			}

			updateOptionsAlpha();
		}

		#if PRELOAD_ALL
		var dontPlaySongThisFrame = false;
		autoplayElapsed += elapsed;
		if (!disableAutoPlay && !songInstPlaying && (autoplayElapsed > timeUntilAutoplay))
		{
			if (curPlayingInst != (curPlayingInst = Paths.inst(curSong.name, "normal", curSong.instSuffix)))
			{
				var data = FlxSoundData.fromAssetKey(curPlayingInst, true);

				if (data != null && autoplayShouldPlay)
				{
					FlxG.sound.playMusic(data, 0);
					Conductor.instance.changeBPM(curSong.bpm, curSong.beatsPerMeasure, curSong.stepsPerBeat);
				}
			}

			songInstPlaying = true;
		}
		#end

		if (controls.BACK || FlxG.mouse.justPressedRight)
		{
			CoolUtil.playMenuSFX(CANCEL, 0.7);
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.stop();
			}
			FlxG.switchState(new MainMenuState());
		}

		#if sys
		if (FlxG.keys.justPressed.EIGHT && Sys.args().contains("-livereload"))
			convertChart();
		#end

		if ((controls.ACCEPT
			|| (!selectedAnotherSong
				&& FlxG.mouse.justPressed
				&& grpSongs?.members[curSelected] != null
				&& FlxG.mouse.overlaps(grpSongs.members[curSelected]))) #if PRELOAD_ALL && !dontPlaySongThisFrame #end)
		{
			select();
		}
	}

	override function destroy()
	{
		for (basic in turboBasics)
			basic.destroy();
		super.destroy();
	}

	var __opponentMode:Bool = false;
	var __coopMode:Bool = false;

	function updateCoopModes()
	{
		__opponentMode = false;
		__coopMode = false;
		if (curSong.coopAllowed && curSong.opponentModeAllowed)
		{
			__opponentMode = curCoopMode % 2 == 1;
			__coopMode = curCoopMode >= 2;
		}
		else if (curSong.coopAllowed)
		{
			__coopMode = curCoopMode == 1;
		}
		else if (curSong.opponentModeAllowed)
		{
			__opponentMode = curCoopMode == 1;
		}
	}

	/**
	 * Selects the current song.
	 */
	public function select()
	{
		updateCoopModes();

		var event = event("onSelect", EventManager.get(FreeplaySongSelectEvent).recycle(curSong.name, "normal", curSong.variant, __opponentMode, __coopMode));

		if (event.cancelled)
			return;

		#if PRELOAD_ALL
		autoplayShouldPlay = false;
		#end

		Options.freeplayLastSong = curSong.name;
		Options.freeplayLastVariation = curSong.variant;

		PlayState.loadSong(event.song, "normal", event.variant, event.opponentMode, event.coopMode);

		FlxG.switchState(new PlayState());
	}

	public function convertChart()
	{
		trace('Converting ${curSong.name} ${curSong.variant} to Codename format...');
		var chart = Chart.parse(curSong.name, "normal", curSong.variant);
		Chart.save(chart, "normal", curSong.variant);
	}

	/**
	 * Array containing all labels for Co-Op / Opponent modes.
	 */
	public var coopLabels:Array<String> = [
		TU.translate("freeplay.solo"),
		TU.translate("freeplay.opponentMode"),
		TU.translate("freeplay.coopMode"),
		TU.translate("freeplay.coopModeSwitched")
	];

	/**
	 * Change the current coop mode context.
	 * @param change How much to change
	 * @param force Force the change, even if `change` is equal to 0.
	 */
	public function changeCoopMode(change:Int = 0, force:Bool = false)
	{
		if (change == 0 && !force)
			return;
		if (!curSong.coopAllowed && !curSong.opponentModeAllowed)
			return;

		var bothEnabled = curSong.coopAllowed && curSong.opponentModeAllowed;
		var event = event("onChangeCoopMode",
			EventManager.get(MenuChangeEvent).recycle(curCoopMode, FlxMath.wrap(curCoopMode + change, 0, bothEnabled ? 3 : 1), change));

		if (event.cancelled)
			return;

		curCoopMode = event.value;

		var coopBinds = [
			CoolUtil.keyToString(Options.P1_CHANGE_MODE[0]),
			CoolUtil.keyToString(Options.P2_CHANGE_MODE[0])
		].filter(x -> x != "---");
		if (coopBinds.length == 2 && coopBinds[1] == coopBinds[0])
			coopBinds.pop();
		else if (coopBinds.length == 0)
			coopBinds.push("---");

		var key = '[${coopBinds.join(" / ")}] ';

		oppText.text = key + coopLabels[curCoopMode * (curSong.coopAllowed ? 2 : 1)];

		updateAccBackScale();
	}

	/**
	 * Change the current selection.
	 * @param change How much to change
	 * @param force Force the change, even if `change` is equal to 0.
	 */
	public function changeSelection(change:Int = 0, force:Bool = false)
	{
		if (change == 0 && !force)
			return;

		var event = event("onChangeSelection",
			EventManager.get(MenuChangeEvent).recycle(curSelected, FlxMath.wrap(curSelected + change, 0, songs.length - 1), change));
		if (event.cancelled)
			return;

		curSelected = event.value;

		if (songs[curSelected]._isHeader)
		{
			if (change < 0)
			{
				curSelected--;
			}
			else
			{
				curSelected++;
			}

			// hardcoding this because wrap didnt work somehow thanks
			if (curSelected < 0)
			{
				curSelected = songs.length - 1;
			}
		}

		updateCurSong();

		if (curVinylId != curSong.vinylId)
		{
			curVinylId = curSong.vinylId;
			vinylGraphic.loadGraphic(Paths.image("menus/vinyls/" + curVinylId));
			vinylGraphic.setGraphicSize(720, 720);
			vinylGraphic.updateHitbox();
			vinylGraphic.x = -360;
			vinylGraphic.y = 0;
		}

		if (event.playMenuSFX)
			CoolUtil.playMenuSFX(SCROLL, 0.7);

		#if PRELOAD_ALL
		autoplayElapsed = 0;
		songInstPlaying = false;
		if (!disableAutoPlay && FlxG.sound.music != null)
			FlxG.sound.music.volume = .0;
		#end
	}

	// THANK YOU MINYA FOR HELP BECAUSE I WOULD HAVE DIED BADLY + BLOOD IF NOT FOR THAT
	public function changeToCategoryInDirection(change:Int = 0)
	{
		var targs:Int = -1;

		var mult:Int = 1;
		if (change < 0)
		{
			mult = -1;
		}

		for (i in 0...headerLocations.length)
		{
			if (curSelected >= headerLocations[i])
			{
				if (i != headerLocations.length - 1)
				{
					if (curSelected >= headerLocations[i + 1])
					{
						continue;
					}
				}

				var new_i = i + mult;

				// modulo doesnt work on negative numbers #Nice #ThanksHaxe
				if (new_i < 0)
				{
					new_i = headerLocations.length + new_i;
				}

				targs = new_i;
			}
		}

		if (change != 0)
		{
			curSelected = headerLocations[targs];
			changeSelection(1);
		}
	}

	function updateOptionsAlpha()
	{
		var event = event("onUpdateOptionsAlpha", EventManager.get(FreeplayAlphaUpdateEvent).recycle(0.6, 0.45, 1, 1, 0.25));
		if (event.cancelled)
			return;

		final idleAlpha = #if PRELOAD_ALL songInstPlaying ? event.idlePlayingAlpha : #end
		event.idleAlpha;
		final selectedAlpha = #if PRELOAD_ALL songInstPlaying ? event.selectedPlayingAlpha : #end
		event.selectedAlpha;

		for (i in 0...iconArray.length)
			iconArray[i].alpha = lerp(iconArray[i].alpha, idleAlpha, event.lerp);

		iconArray[curSelected].alpha = selectedAlpha;

		for (i => item in grpSongs.members)
		{
			item.targetY = i - curSelected;

			item.alpha = lerp(item.alpha, idleAlpha, event.lerp);

			if (item.targetY == 0)
				item.alpha = selectedAlpha;

			if (songs[i]._isHeader)
			{
				item.alpha = 1;
				iconArray[i].alpha = 1;
			}
		}
	}

	function updateCurSong()
	{
		var song = songs[curSelected];
		if (song == null)
		{
			curSong = null;
		}
		else
		{
			curSong = song;
		}
	}

	/**
	 * Formats the accuracy value to always display 2 decimal values no matter the circumstances. (00.00)
	 * @param value The raw, unrounded accuracy value.
	 * @return Formatted string.
	 */
	public static function formatAccuracy(value:Float):String
	{
		var rounded:Float = FlxMath.roundDecimal(value, 2);
		var str:String = Std.string(rounded);

		var dotIndex:Int = str.indexOf(".");

		if (dotIndex == -1)
			return str + ".00";
		else if (str.length - dotIndex == 2)
			return str + "0";

		return str;
	}

	function updateAccBackScale()
	{
		var charCount = accstrhead.length;
		var charWidth = 13.1;

		accBacker.scale.set((charCount * charWidth) + 16 + 8, 48 + 16 + 8);
		accBacker.updateHitbox();
		accBacker.setPosition((FlxG.width - accBack.width) - 12, 4);

		accBack.scale.set((charCount * charWidth) + 16, 48 + 16);
		accBack.updateHitbox();
		accBack.setPosition((FlxG.width - accBack.width) - 8, 8);
		accText.setPosition(accBack.x + 8, accBack.y + 8);

		var charCount = oppText.text.length;
		var charWidth = 13.1;

		oppBacker.scale.set((charCount * charWidth) + 16, 46);
		oppBacker.updateHitbox();
		oppBacker.setPosition((FlxG.width - oppBack.width) - 12, (FlxG.height - oppBack.height) - 12);

		oppBack.scale.set((charCount * charWidth) + 8, 38);
		oppBack.updateHitbox();
		oppBack.setPosition((FlxG.width - oppBack.width) - 8, (FlxG.height - oppBack.height) - 8);
		oppText.setPosition(oppBack.x + 8, oppBack.y + 8);
	}
}

class FreeplaySonglist
{
	public var songs:Array<ChartMetaData> = [];

	public static final EXCLUDE_SUBFOLDERS:Array<String> = ['charts', 'scripts', 'song'];

	public function new()
	{
	}

	public static function isSubSongDirectory(subs:Array<String>):Bool
	{
		for (i in EXCLUDE_SUBFOLDERS)
		{
			// that one guy that is using sgbh codename and capitizlaed their name when writing it :)
			if (subs.contains(i.toLowerCase()))
				return false;
		}
		return true;
	}

	public function getSongsFromSource(source:AssetSource = BOTH, useTxt:Bool = true, ?startDir:String = 'songs/', ?flatten:Bool = true)
	{
		var totalSongsFound:Array<String> = [];
		var mods:Array<IModsAssetLibrary> = ModsFolder.getLoadedModsLibs(true);
		// addon songs appear lower than the mod's main music now
		while (mods[0].modName != (ModsFolder.currentModFolder ?? 'assets'))
		{
			final thisMod = mods.pop();
			mods.insert(0, thisMod);
		}
		if (source != BOTH)
		{
			var i:Int = 0;
			while (i < mods.length)
			{
				final thisMod = mods[i];
				if (((source == MODS) && (thisMod.modName == 'assets')) || ((source == SOURCE) && (thisMod.modName != 'assets')))
					mods.remove(thisMod);
				else
					i++;
			}
		}
		var i:Int = 0;
		while (i < mods.length)
		{
			final modLib:ModsFolderLibrary = cast mods[i++];
			if (modLib == null)
			{
				i++;
				continue;
			}

			final modName = modLib.modName;
			var songsFound:Array<String> = [];

			if (useTxt)
			{
				var oldPath = Paths.txt('freeplaySonglist/LIB_$modName');
				var newPath = Paths.txt('config/freeplaySonglist/LIB_$modName');

				if (modLib.exists(newPath, "TEXT"))
				{
					for (i in CoolUtil.coolTextFile(newPath))
						songsFound.push(i);
				}
				else if (modLib.exists(oldPath, "TEXT"))
				{
					Logs.warn("data/freeplaySonglist.txt is deprecated and will be removed in the future. Please move the file to data/config/", DARKYELLOW,
						"FreeplaySonglist");
					for (i in CoolUtil.coolTextFile(oldPath))
						songsFound.push(i);
				}
				for (s in songsFound)
					totalSongsFound.push(s);
			}
			if (songsFound.length < 1 || !useTxt)
			{
				// only scan the songs folder in this library (assets/ is automatically replaced)
				var songDirs = modLib.getFolders('assets/' + startDir);
				function scanForSongs(a:Array<Dynamic>, startDir:String, ?multiScan:Bool = false)
				{
					for (i in a)
					{
						var subs = modLib.getFolders('$startDir$i/');
						if (isSubSongDirectory(subs))
						{
							if (multiScan)
								scanForSongs(subs, '$startDir$i/');
							else
								songsFound.push(StringTools.trim(i + '/'));
						}
						else
							songsFound.push(StringTools.trim(i));
					}
				}
				scanForSongs(songDirs, 'assets/' + startDir, flatten);
				for (s in songsFound)
					if (totalSongsFound.indexOf(s) == -1)
						totalSongsFound.push(s); // dont allow any duplicates
			}
		}
		// put folders at the top (in chart editor)
		totalSongsFound = totalSongsFound.filter(a -> a.endsWith('/')).concat(totalSongsFound.filter(a -> !a.endsWith('/')));
		if (totalSongsFound.length > 0)
		{
			for (s in totalSongsFound)
			{
				if (s.toLowerCase().startsWith("header:"))
				{
					var sect = s.toLowerCase().substr(7);
					songs.push({
						_isHeader: true,
						name: sect,
						displayName: "",
						icon: sect + "-header",
						difficulties: [""]
					});
				}
				else
				{
					songs.push(Chart.loadChartMeta(startDir.substr('songs/'.length) + s, source == MODS));
				}
			}

			return false;
		}

		return true;
	}

	public static function get(useTxt:Bool = true, ?startDir:String = 'songs/', ?flatten:Bool = true)
	{
		var songList = new FreeplaySonglist();

		switch (Flags.SONGS_LIST_MOD_MODE)
		{
			case 'prepend':
				songList.getSongsFromSource(MODS, useTxt, startDir, flatten);
				songList.getSongsFromSource(SOURCE, useTxt, startDir, flatten);
			case 'append':
				songList.getSongsFromSource(SOURCE, useTxt, startDir, flatten);
				songList.getSongsFromSource(MODS, useTxt, startDir, flatten);
			default /*case 'override'*/:
				// appends addon songs after base game songs,
				// because old behavior would clear base game songs either way
				if (ModsFolder.currentModFolder == null)
				{
					songList.getSongsFromSource(SOURCE, useTxt, startDir, flatten);
					songList.getSongsFromSource(MODS, useTxt, startDir, flatten);
				}
				else if (songList.getSongsFromSource(MODS, useTxt, startDir, flatten))
					songList.getSongsFromSource(SOURCE, useTxt, startDir, flatten);
		}

		return songList;
	}
}
