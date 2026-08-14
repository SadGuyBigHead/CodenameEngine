package funkin.game;

class HoldCoverGroup extends FlxTypedGroup<HoldCover>
{
	public function noteHit(note:Note)
	{
		if (note.sustainLength <= 0)
			return;
		members[note.strumID]?.start(note.sustainLength * .001);
	}
}