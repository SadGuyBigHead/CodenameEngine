package funkin.backend.scripting.events.note;

import funkin.game.Character;
import funkin.game.HealthIcon;
import funkin.game.Note;

final class SustainHitEvent extends CancellableEvent
{
	@:dox(hide) public var animCancelled:Bool = false;
	@:dox(hide) public var strumGlowCancelled:Bool = false;
	@:dox(hide) public var held:Bool = true;

	/**
	 * Whether this hit increases the score
	 */
	public var countScore:Bool = true;

	/**
	 * Note that has been pressed
	 */
	public var note:Note;

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
	public var player:Bool;

	/**
	 * Note Type name (null if default note)
	 */
	public var noteType:String;

	/**
	 * Suffix of the animation. "-alt" for alt notes, "" for normal ones.
	 */
	public var animSuffix:String;

	/**
	 * Direction of the press (0 = Left, 1 = Down, 2 = Up, 3 = Right)
	 */
	public var direction:Int;

	/**
	 * Score gained after note press.
	 */
	public var score:Int;

	/**
	 * The amount of health that'll be gained in this frame like per second like yeah
	 */
	public var healthGain:Float;

	/**
	 * Whenever the animation should be forced to play (if it's null it will be forced based on the sprite's data xml, if it has one).
	 */
	public var forceAnim:Null<Bool> = false;

	/**
	 * The attached healthIcon used distinction for icons amongst others
	 */
	public var healthIcon:HealthIcon;

	/**
	 * Prevents the default sing animation from being played.
	 */
	public function preventAnim()
	{
		animCancelled = true;
	}

	@:dox(hide)
	public function cancelAnim()
	{
		preventAnim();
	}
	
	public function forceEnd()
	{
		held = false;
	}

	/**
	 * Prevents the strum from glowing after this note has been pressed.
	 */
	public function preventStrumGlow()
	{
		strumGlowCancelled = true;
	}

	@:dox(hide)
	public function cancelStrumGlow()
	{
		preventStrumGlow();
	}

	private inline function get_character()
		return characters[0];

	private function set_character(char:Character)
	{
		characters = [char];
		return char;
	}
}
