module MIDIator #temp work-around
end
require 'midiator/notes.rb'
require 'midiator/drums.rb'
#require 'midilib_javabacked'
#require 'midilib'
class Score
	def self.build(&block)
		score=self.new
		score.instance_eval(&block)
		score
	end
	
	attr_accessor :tracks
	def initialize
		@tracks=[]
	end
end

class Phrase
	def self.build(channel=0,&block)
		p=self.new
		p.channel=channel
		p.instance_eval(&block)
		p
	end
	
	attr_accessor :notes,:channel
	def initialize
		@notes=[]
		@channel=0
		@running_time=0
	end
	#todo: make less fragile
	def length=(l)
		@len=l
	end
	def length
		@len ||= @notes.map {|n| n[:from_start]+n[:len]}.max
	end
	
	#for dsl
	def at(beat,&block)
		to=(beat-1).to_f
		if block
			temp=@running_time
			@running_time=to
			yield
			@running_time=temp
		else
			@running_time=to
		end
	end
	def note(len,note)
		add_event(MIDIator::Notes.const_get(note),
			note_to_length(len.to_s))
	end
	def drum(note)
		add_event(MIDIator::Drums.const_get(note),
			note_to_length("16th"))
	end
	def rest(len)
		@running_time=note_to_length(len.to_s)
		@len=nil
	end
	#end
	
	def reverse
		#todo: array of onn, off pairs, not just on,offs at random
		copy_map_notes do |n|
			#reverse is defined as- things that ended 'x' from the track end will now start 'x' from the beginning
			n[:from_start]=length-(n[:from_start]+n[:len])
		end
	end
	
	def transpose(offset)
		copy_map_notes {|n|n[:note]+=offset}
	end
	
	def layer(other)
		p=self.clone
		p.notes= (notes+other.notes).sort_by {|n| n[:from_start]}
		p
	end
	protected
	def add_event(num,len)
		@notes << {:note=>num,:len=>len,:from_start=>@running_time}
		@running_time+=len
		@len=nil
	end
	def copy_map_notes
		p=self.clone
		p.notes = notes.map do |n|
			n2=n.clone
			yield n2
			n2
		end.sort_by {|n| n[:from_start]}
		p
	end
	NOTE_TO_LENGTH = {
		'whole' => 4.0,
		'half' => 2.0,
		'quarter' => 1.0,
		'eighth' => 0.5,
		'8th' => 0.5,
		'sixteenth' => 0.25,
		'16th' => 0.25,
		'thirty second' => 0.125,
		'thirtysecond' => 0.125,
		'32nd' => 0.125,
		'sixty fourth' => 0.0625,
		'sixtyfourth' => 0.0625,
		'64th' => 0.0625
	}
	def note_to_length(name) #stolen from Sequence. for now, assume ppqn=480
		name.strip!
		name =~ /^(dotted)?(.*?)(triplet)?$/
		dotted, note_name, triplet = $1, $2, $3
		note_name.strip!
		mult = 1.0
		mult = 1.5 if dotted
		mult /= 3.0 if triplet
		len = NOTE_TO_LENGTH[note_name]
		raise "Sequence.note_to_length: \"#{note_name}\" not understood in \"#{name}\"" unless len
		return len * mult
	end
end

class Range
	def fixed_step(s,&block)
		raise "need positive s" unless s>0
		n=self.begin
		if (block)
			while n < self.end
				yield n
				n+=s
			end
			yield n if n==self.end && !exclude_end?
		else
			Enumerable::Enumerator.new do |yielder|
				while n < self.end
					yielder<< n
					n+=s
				end
				yielder<< n if n==self.end && !exclude_end?
			end
		end
	end
end

class DrumLine < Phrase
	def self.build(length=4,&block)
		p=self.new
		p.channel=9
		p.length=length
		p.instance_eval(&block)
		p
	end
	def b;"BassDrum1";end
	def sn;"SnareDrum1";end
	def h;"ClosedHiHat";end
	def p;"PedalHiHat";end
	def x; p; end
	def _; nil; end
	def run(arr,start=0,last=length)
		n=start
		s=(last-start)/arr.length.to_f
		
		i=0
		while n<last
			x=arr[i]
			case x
				when String: boom(n,x)
				when Array: run(x,n,n+s)
			end
			
			i+=1
			n+=s
		end
	end
	def run2(arr,start=0,len=length)
		subdivide_len = (len.to_f/arr.length)
		arr.each_with_index do |beat,i|
			time=start+i*subdivide_len
			case beat
				when String: boom(time,beat)
				when Array: run2(beat,time,subdivide_len)
			end
		end
	end
	def extra(&block)
		p=self.clone
		p.notes=self.notes.map {|x| x.dup}
		p.instance_eval(&block)
		p
	end
	def boom(time,drumname)
		@notes << {:note=>MIDIator::Drums.const_get(drumname),
			:len=>note_to_length("16th"),
			:from_start=>time}
	end
end
