# encoding: ASCII-8BIT

# need Ole::IOMode
require 'ole/support'

#
# = Introduction
#
# +RangesIO+ is a basic class for wrapping another IO object allowing you to arbitrarily reorder
# slices of the input file by providing a list of ranges. Intended as an initial measure to curb
# inefficiencies in the Dirent#data method just reading all of a file's data in one hit, with
# no method to stream it.
# 
# This class will encapuslate the ranges (corresponding to big or small blocks) of any ole file
# and thus allow reading/writing directly to the source bytes, in a streamed fashion (so just
# getting 16 bytes doesn't read the whole thing).
#
# In the simplest case it can be used with a single range to provide a limited io to a section of
# a file.
#
# = Limitations
#
# * No buffering. by design at the moment. Intended for large reads
# 
# = TODO
# 
# On further reflection, this class is something of a joining/optimization of
# two separate IO classes. a SubfileIO, for providing access to a range within
# a File as a separate IO object, and a ConcatIO, allowing the presentation of
# a bunch of io objects as a single unified whole.
# 
# I will need such a ConcatIO if I'm to provide Mime#to_io, a method that will
# convert a whole mime message into an IO stream, that can be read from.
# It will just be the concatenation of a series of IO objects, corresponding to
# headers and boundaries, as StringIO's, and SubfileIO objects, coming from the
# original message proper, or RangesIO as provided by the Attachment#data, that
# will then get wrapped by Mime in a Base64IO or similar, to get encoded on-the-
# fly. Thus the attachment, in its plain or encoded form, and the message as a
# whole never exists as a single string in memory, as it does now. This is a
# fair bit of work to achieve, but generally useful I believe.
# 
# This class isn't ole specific, maybe move it to my general ruby stream project.
# 
class RangesIO
	attr_reader :io, :mode, :ranges, :size, :pos
	# +io+:: the parent io object that we are wrapping.
	# +mode+:: the mode to use
	# +params+:: hash of params.
	# * :ranges - byte offsets, either:
	#   1. an array of ranges [1..2, 4..5, 6..8] or
	#   2. an array of arrays, where the second is length [[1, 1], [4, 1], [6, 2]] for the above
	#      (think the way String indexing works)
	# * :close_parent - boolean to close parent when this object is closed
	#
	# NOTE: the +ranges+ can overlap.
	def initialize io, mode='r', params={}
		mode, params = 'r', mode if Hash === mode
		ranges = params[:ranges]
		@params = {:close_parent => false}.merge params
		@mode = Ole::IOMode.new mode
		@io = io
		# initial position in the file
		@pos = 0
		self.ranges = ranges || [[0, io.size]]
		# handle some mode flags
		truncate 0 if @mode.truncate?
		seek size if @mode.append?
	end
	
	# add block form. TODO add test for this
	def self.open(*args, &block)
		ranges_io = new(*args)
		if block_given?
			begin;  yield ranges_io
			ensure; ranges_io.close
			end
		else
			ranges_io
		end
	end

	def ranges= ranges
		# convert ranges to arrays. check for negative ranges?
		ranges = ranges.map { |r| Range === r ? [r.begin, r.end - r.begin] : r }
		# combine ranges
		if @params[:combine] == false
			# might be useful for debugging...
			@ranges = ranges
		else
			@ranges = []
			next_pos = nil
			ranges.each do |pos, len|
				if next_pos == pos
					@ranges.last[1] += len
					next_pos += len
				else
					@ranges << [pos, len]
					next_pos = pos + len
				end
			end
		end
		# calculate cumulative offsets from range sizes
		@size = 0
		@offsets = []
		@ranges.each do |pos, len|
			@offsets << @size
			@size += len
		end
		self.pos = @pos
	end

	def pos= pos, whence=IO::SEEK_SET
		case whence
		when IO::SEEK_SET
		when IO::SEEK_CUR
			pos += @pos
		when IO::SEEK_END
			pos = @size + pos
		else raise Errno::EINVAL
		end
		raise Errno::EINVAL unless (0..@size) === pos
		@pos = pos

		# do a binary search throuh @offsets to find the active range.
		a, c, b = 0, 0, @offsets.length
		while a < b
			c = (a + b).div(2)
			pivot = @offsets[c]
			if pos == pivot
				@active = c
				return
			elsif pos < pivot
				b = c
			else
				a = c + 1
			end
		end

		@active = a - 1
	end

	alias seek :pos=
	alias tell :pos

	def rewind
		seek 0
	end

	def close
		@io.close if @params[:close_parent]
	end

	def eof?
		@pos == @size
	end

	# read bytes from file, to a maximum of +limit+, or all available if unspecified.
	def read limit=nil
		data = ''.dup
		return data if eof?
		limit ||= size
		pos, len = @ranges[@active]
		diff = @pos - @offsets[@active]
		pos += diff
		len -= diff
		loop do
			@io.seek pos
			if limit < len
				s = @io.read(limit).to_s
				@pos += s.length
				data << s
				break
			end
			s = @io.read(len).to_s
			@pos += s.length
			data << s
			break if s.length != len
			limit -= len
			break if @active == @ranges.length - 1
			@active += 1
			pos, len = @ranges[@active]
		end
		data
	end

	# you may override this call to update @ranges and @size, if applicable.
	def truncate size
		raise NotImplementedError, 'truncate not supported'
	end

	# using explicit forward instead of an alias now for overriding.
	# should override truncate.
	def size=	size
		truncate size
	end

	def write data
		# duplicates object to avoid side effects for the caller, but do so only if
		# encoding isn't already ASCII-8BIT (slight optimization)
		if data.respond_to?(:encoding) and data.encoding != Encoding::ASCII_8BIT
			data = data.dup.force_encoding(Encoding::ASCII_8BIT)
		end
		return 0 if data.empty?
		data_pos = 0
		# if we don't have room, we can use the truncate hook to make more space.
		if data.length > @size - @pos
			begin
				truncate @pos + data.length
			rescue NotImplementedError
				raise IOError, "unable to grow #{inspect} to write #{data.length} bytes" 
			end
		end
		pos, len = @ranges[@active]
		diff = @pos - @offsets[@active]
		pos += diff
		len -= diff
		loop do
			@io.seek pos
			if data_pos + len > data.length
				chunk = data[data_pos..-1]
				@io.write chunk
				@pos += chunk.length
				data_pos = data.length
				break
			end
			@io.write data[data_pos, len]
			@pos += len
			data_pos += len
			break if @active == @ranges.length - 1
			@active += 1
			pos, len = @ranges[@active]
		end
		data_pos
	end
	
	alias << write

	# i can wrap it in a buffered io stream that
	# provides gets, and appropriately handle pos,
	# truncate. mostly added just to past the tests.
	# FIXME
	def gets
		s = read 1024
		i = s.index "\n"
		self.pos -= s.length - (i+1)
		s[0..i]
	end
	alias readline :gets

	def inspect
		"#<#{self.class} io=#{io.inspect}, size=#{@size}, pos=#{@pos}>"
	end
end

# this subclass of ranges io explicitly ignores the truncate part of 'w' modes.
# only really needed for the allocation table writes etc. maybe just use explicit modes
# for those
# better yet write a test that breaks before I fix it. added nodoc for the 
# time being.
class RangesIONonResizeable < RangesIO # :nodoc:
	def initialize io, mode='r', params={}
		mode, params = 'r', mode if Hash === mode
		flags = Ole::IOMode.new(mode).flags & ~IO::TRUNC
		super io, flags, params
	end
end

