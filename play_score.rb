require 'score.rb'
#require 'midilib_javabacked'
require 'java'
require 'midi_java/event.rb'
def play(score,tempo=nil)
	require 'pp'
	#pp score
	wrap=ScoreWrap.new(score)
	
 	seqer = javax.sound.midi.MidiSystem.sequencer
	seqer.open
	seqer.sequence = wrap
	seqer.tempo_in_bpm=tempo if tempo
	seqer.start
	while (seqer.is_running)
		sleep 1
	end
	seqer.close
	nil
end

class ScoreWrap < javax.sound.midi.Sequence
	def initialize(sc,ppqn=480)
		@score=sc
		@ppqn=ppqn
		super(javax.sound.midi.Sequence::PPQ,@ppqn)
	end
	
	def getTracks
		@tracks ||= @score.tracks.map do |t|
			TrackWrap.new(t,@ppqn)
		end.to_java("javax.sound.midi.Track".to_sym)
	end
	def getResolution
		@ppqn
	end
end

class TrackWrap < javax.sound.midi.Track
	def initialize(t,ppqn)
		super()
		@all_events = if t.nil?
			[]
		else
			phrase_start_time=0
			t.map do |phrase|
				notes=phrase.notes.map do |n|
					on=MIDI::NoteOn.new(phrase.channel,n[:note],n[:vel] || 64,0) #some assumptions here
					off=MIDI::NoteOff.new(phrase.channel,n[:note],64,n[:len]*ppqn)
					on.time_from_start=phrase_start_time+n[:from_start]*ppqn
					off.time_from_start=phrase_start_time+(n[:from_start]+n[:len])*ppqn
					[on,off]
				end
				phrase_start_time+=phrase.length*ppqn
				notes
			end.flatten.sort
		end
	end
	
	def get(i)
		@all_events[i]
	end
	def size
		@all_events.length
	end
end