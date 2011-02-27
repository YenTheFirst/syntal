this is a set of classes & utils, with the goal of composing midi-based music in ruby in a concise, readable, and expressive manner

Overview of classes:
Phrase:
	this is used to represent a simple line of melody, drum beat, or chord progression.
	important properties are: length, representing the 'count' of the phrase in beats, and notes, a list of hashes representing notes that are played in the phrase
	the hash is of the form: {:note=> <midi note number>, :len=> <length in beats>, :from_start=> <start time of note in beats>, (optional) :vel=> <midi velocity of the note>}
		example: {:note=>64, :len=>4, :from_start=>0} will represent a whole note, played at the beginning of the measure
		{:note=>72, :len=>0.5, :from_start=>1.5} will be the same note, an octave up, with an eigth note duration, halfway into the second beat (one-and two-AND...)
	a phrase also has a 'channel', representing its midi channel. (usually 0, drum tracks use channel 9)
	A phrase can be built manually, the Phrase.build method allows for more convenient construction.

Score
	this is a collection of tracks, each of which has an array of phrases.
	it can be conveniently built with Score.build

ScoreWrap:
	this translates the ruby class 'Score' into a form usable by the java sequencer.
	It subclasses javax.sound.midi.Sequence for this purpose.
TrackWrap:
	represents a single midi 'track' in a midi sequence.
	subclasses javax.sound.midi.Track
	One caveat: the javax.sound.midi.Track has a protected constructor, it may require some hacking around to get TrackWrap to run


