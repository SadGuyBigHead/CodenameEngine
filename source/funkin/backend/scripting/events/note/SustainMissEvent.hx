package funkin.backend.scripting.events.note;

import funkin.game.Character;
import funkin.game.HealthIcon;
import funkin.game.Note;

final class SustainMissEvent extends CancellableEvent
{
	@:dox(hide) public var animCancelled:Bool = false;
	@:dox(hide) public var resetCombo:Bool = true;
	@:dox(hide) public var playMissSound:Bool = true;

	/**
	 * Note that has been missed
	 */
	public var note:Note;

	public var muteVocals:Bool;

	/**
	 * The amount of health that'll be gained from missing that note. If called from `onPlayerMiss`, the value will be negative.
	 */
	public var healthGain:Float;

	public var missSound:String;
	public var missVolume:Float;

	public var gfSad:Bool;
	public var gfSadAnim:String;
	public var forceGfAnim:Bool;

	/**
	 * Whenever the animation should be forced to play (if it's null it will be forced based on the sprite's data xml, if it has one).
	 */
	public var forceAnim:Null<Bool>;

	/**
	 * Suffix of the animation. "miss" for miss notes, "-alt" for alt notes, "" for normal ones.
	 */
	public var animSuffix:String;

	/**
	 * Character that pressed the note.
	 */
	public var character(get, set):Character;

	/**
	 * Characters that pressed the note.
	 */
	public var characters:Array<Character>;

	/**
	 * Whenever the Character is a player
	 */
	public var playerID:Int;

	/**
	 * Note Type name (null if default note)
	 */
	public var noteType:String;

	/**
	 * Direction of the press (0 = Left, 1 = Down, 2 = Up, 3 = Right)
	 */
	public var direction:Int;

	private inline function get_character()
		return characters[0];

	private function set_character(char:Character)
	{
		characters = [char];
		return char;
	}

	/**
	 * Prevents the miss sound from played.
	 */
	public function preventMissSound()
	{
		playMissSound = false;
	}

	/**
	 * Prevents the combo from being reset.
	 */
	public function preventResetCombo()
	{
		resetCombo = false;
	}

	/**
	 * Prevents the default sing animation from being played.
	 */
	public function preventAnim()
	{
		animCancelled = true;
	}

	/**
	 * Prevents the vocals volume from being set to 1 after pressing the note.
	 */
	public function preventVocalsUnmute()
	{
		muteVocals = true;
	}

	/**
	 * Prevents the vocals volume from being muted in case its a parameter of `onPlayerMiss`
	 */
	public function preventVocalsMute()
	{
		muteVocals = false;
	}
}
