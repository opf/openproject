#! /usr/bin/ruby
# encoding: ASCII-8BIT

$: << File.dirname(__FILE__) + '/../lib'

require 'test/unit'
require 'ole/types'

class TestTypes < Test::Unit::TestCase
	include Ole::Types

	def test_lpwstr
		assert_equal "t\000e\000s\000t\000", Lpwstr.dump('test')
		str = Lpwstr.load "t\000e\000s\000t\000"
		assert_equal 'test', str
		assert_equal Lpwstr, str.class
	end

	def test_lpstr
		# no null byte? probably wrong
		assert_equal 'test', Lpstr.dump('test')
		assert_equal 'test', Lpstr.load("test\000")
	end

	# in actual fact the same code path would be used for systime i expect
	def test_filetime
		# for saving, we can use Date, Time, or DateTime.
		assert_equal "\000\000\260\3077-\307\001", FileTime.dump(Time.gm(2007, 1, 1))
		time = FileTime.load "\000\000\260\3077-\307\001"
		assert_equal FileTime, time.class
		assert_equal '2007-01-01T00:00:00+00:00', time.to_s
		# note that if we'd used Time.local, instead of gm, we'd get a different value. eg
		assert_equal "\000\370\331\336\r-\307\001", FileTime.dump(DateTime.parse('2007-01-01 00:00 +0500'))
		# note that it still loads up as GMT, because there's no associated time zone.
		# essentially, i'm storing and loading times as GMT. maybe i should add in conversion to local time
		# zone when loading
		assert_equal '2006-12-31T19:00:00+00:00', FileTime.load("\000\370\331\336\r-\307\001").to_s
		# test loading a bogus time
		assert_equal nil, FileTime.load(0.chr * 8)
		# this used to be counted as an "unlikely time", and discarded. that has been removed
		assert_equal '1700-01-01T00:00:00+00:00', FileTime.load(FileTime.dump(Date.new(1700, 1, 1))).to_s
		assert_equal '#<Ole::Types::FileTime 2006-12-31T19:00:00+00:00>', FileTime.load("\000\370\331\336\r-\307\001").inspect
	end

	def test_guid
		assert_equal "\x29\x03\x02\x00\x80\x08\x07\x40\xc0\x01\x12\x34\x56\x78\x90\x46",
								 Clsid.dump('{00020329-0880-4007-c001-123456789046}')
		assert_equal '#<Ole::Types::Clsid:{00020329-0880-4007-c001-123456789046}>',
								 Clsid.load("\x29\x03\x02\x00\x80\x08\x07\x40\xc0\x01\x12\x34\x56\x78\x90\x46").inspect
	end

	def test_variant
		assert_equal "\x29\x03\x02\x00\x80\x08\x07\x40\xc0\x01\x12\x34\x56\x78\x90\x46",
								 Variant.dump(VT_CLSID, '{00020329-0880-4007-c001-123456789046}')
		assert_equal "2006-12-31T19:00:00+00:00", Variant.load(VT_FILETIME, "\000\370\331\336\r-\307\001").to_s
		data = Variant.load VT_DATE, 'blahblah'
		assert_equal Data, data.class
		assert_equal 'blahblah', Variant.dump(VT_DATE, 'blahblah')
	end
	
	# purely for the purposes of coverage, i'll test these old aliases:
	def test_deprecated_aliases
		assert_equal '#<Ole::Types::Clsid:{00020329-0880-4007-c001-123456789046}>',
								 Ole::Types.load_guid("\x29\x03\x02\x00\x80\x08\x07\x40\xc0\x01\x12\x34\x56\x78\x90\x46").inspect
		assert_equal '2006-12-31T19:00:00+00:00', Ole::Types.load_time("\000\370\331\336\r-\307\001").to_s
	end
end

