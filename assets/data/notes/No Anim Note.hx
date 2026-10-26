function onNoteHit(event)
	if (event.noteType == "No Anim Note")
		event.animCancelled = true;

function onSustainHit(event)
	if (event.noteType == "No Anim Note")
		event.animCancelled = true;

function onPlayerMiss(event)
	if (event.noteType == "No Anim Note")
		event.animCancelled = true;
