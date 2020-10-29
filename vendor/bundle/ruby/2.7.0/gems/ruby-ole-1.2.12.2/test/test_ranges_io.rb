#! /usr/bin/ruby

$: << File.dirname(__FILE__) + '/../lib'

require 'test/unit'
require 'ole/ranges_io'
require 'stringio'

class TestRangesIO < Test::Unit::TestCase
	TEST_DIR = File.dirname __FILE__

	def setup
		# read from ourself, also using overlaps.
		ranges = [100..200, 0..10, 100..150]
		@io = RangesIO.new open("#{TEST_DIR}/test_ranges_io.rb"), :ranges => ranges, :close_parent => true
	end

	def teardown
		@io.close
	end

	def test_open
		# block form
		f = open("#{TEST_DIR}/test_ranges_io.rb")
		assert_equal false, f.closed?
		RangesIO.open f, :ranges => []
		assert_equal false, f.closed?
		RangesIO.open(f, :ranges => [], :close_parent => true) {}
		assert_equal true, f.closed?
	end

	def test_combine
		ranges = [[0, 100], 100...200, [200, 100]]
		io = RangesIO.new STDOUT, 'r+', :ranges => ranges
		assert_equal [[0, 300]], io.ranges
		io = RangesIO.new STDOUT, 'r+', :ranges => ranges, :combine => false
		assert_equal [[0, 100], [100, 100], [200, 100]], io.ranges
	end

	def test_basics
		assert_equal 160, @io.size
		assert_match %r{size=160}, @io.inspect
	end

	def test_truncate
		assert_raises(NotImplementedError) { @io.size += 10 }
	end

	def test_seek
		@io.pos = 10
		@io.seek(-100, IO::SEEK_END)
		@io.seek(-10, IO::SEEK_CUR)
		@io.pos += 20
		assert_equal 70, @io.pos
		@io.rewind
		assert_equal 0, @io.pos
		# seeking past the end doesn't throw an exception for normal
		# files, even in read mode, but RangesIO does
		assert_raises(Errno::EINVAL) { @io.seek 500 }
		assert_raises(Errno::EINVAL) { @io.seek(-500, IO::SEEK_END) }
		assert_raises(Errno::EINVAL) { @io.seek 1, 10 }
	end

	def test_read
		# this will map to the start of the file:
		@io.pos = 100
		assert_equal '#! /usr/bi', @io.read(10)
		# test selection of initial range, offset within that range
		pos = 80
		@io.seek pos
		# test advancing of pos properly, by...
		chunked = (0...10).map { @io.read 10 }.join
		# given the file is 160 long:
		assert_equal 80, chunked.length
		@io.seek pos
		# comparing with a flat read
		assert_equal chunked, @io.read(80)
	end

	# should test gets, lineno, and other IO methods we want to have
	def test_gets
		assert_equal "io'\n", @io.gets
	end

	def test_write
		str = File.read "#{TEST_DIR}/test_ranges_io.rb"
		@io = RangesIO.new StringIO.new(str), :ranges => @io.ranges
		assert_equal "io'\nrequir", str[100, 10]
		@io.write 'testing testing'
		assert_equal 'testing te', str[100, 10]
		@io.seek 0
		assert_equal 'testing te', @io.read(10)
		# lets write over a range barrier
		assert_equal '#! /usr/bi', str[0, 10]
		assert_equal "LE__\n\n\tdef", str[195, 10]
		@io.write 'x' * 100
		assert_equal 'x' * 10, str[0, 10]
		assert_equal "xxxxx\n\tdef", str[195, 10]
		# write enough to overflow the file
		assert_raises(IOError) { @io.write 'x' * 60 }
	end
	
	def test_non_resizeable
		# will try to truncate, which will fail
		assert_raises NotImplementedError do
			@io = RangesIO.new(StringIO.new, 'w', :ranges => [])
		end
		# will be fine
		@io = RangesIONonResizeable.new(StringIO.new, 'w', :ranges => [])
		assert_equal '#<Ole::IOMode wronly|creat>', @io.instance_variable_get(:@mode).inspect
	end
end

