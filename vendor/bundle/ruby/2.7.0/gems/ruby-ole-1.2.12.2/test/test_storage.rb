#! /usr/bin/ruby
# coding: utf-8

$: << File.dirname(__FILE__) + '/../lib'
#require 'rubygems'

require 'test/unit'
require 'ole/storage'
require 'digest/sha1'
require 'stringio'
require 'tempfile'

#
# = TODO
#
# These tests could be a lot more complete.
#

# should test resizeable and migrateable IO.

class TestStorageRead < Test::Unit::TestCase
	TEST_DIR = File.dirname __FILE__

	def setup
		@ole = Ole::Storage.open "#{TEST_DIR}/test_word_6.doc", 'rb'
	end

	def teardown
		@ole.close
	end

	def test_header
		# should have further header tests, testing the validation etc.
		assert_equal 17,  @ole.header.to_a.length
		assert_equal 117, @ole.header.dirent_start
		assert_equal 1,   @ole.header.num_bat
		assert_equal 1,   @ole.header.num_sbat
		assert_equal 0,   @ole.header.num_mbat
	end
	
	def test_new_without_explicit_mode
		open "#{TEST_DIR}/test_word_6.doc", 'rb' do |f|
			assert_equal false, Ole::Storage.new(f).writeable
		end
	end

	def capture_warnings
		@warn = []
		outer_warn = @warn
		old_log = Ole::Log
		old_verbose = $VERBOSE
		begin
			$VERBOSE = nil
			Ole.const_set :Log, Object.new
			# restore for the yield
			$VERBOSE = old_verbose
			(class << Ole::Log; self; end).send :define_method, :warn do |message|
				outer_warn << message
			end
			yield
		ensure
			$VERBOSE = nil
			Ole.const_set :Log, old_log
			$VERBOSE = old_verbose
		end
	end

	def test_invalid
		assert_raises Ole::Storage::FormatError do
			Ole::Storage.open StringIO.new(0.chr * 1024)
		end
		assert_raises Ole::Storage::FormatError do
			Ole::Storage.open StringIO.new(Ole::Storage::Header::MAGIC + 0.chr * 1024)
		end
		capture_warnings do
			head = Ole::Storage::Header.new
			head.threshold = 1024
			assert_raises NoMethodError do
				Ole::Storage.open StringIO.new(head.to_s + 0.chr * 1024)
			end
		end
		assert_equal ['may not be a valid OLE2 structured storage file'], @warn
	end
	
	def test_inspect
		assert_match(/#<Ole::Storage io=#<File:.*?test_word_6.doc> root=#<Dirent:"Root Entry">>/, @ole.inspect)
	end

	def test_fat
		# the fat block has all the numbers from 5..118 bar 117
		bbat_table = [112] + ((5..118).to_a - [112, 117])
		assert_equal bbat_table, @ole.bbat.reject { |i| i >= (1 << 32) - 3 }, 'bbat'
		sbat_table = (1..43).to_a - [2, 3]
		assert_equal sbat_table, @ole.sbat.reject { |i| i >= (1 << 32) - 3 }, 'sbat'
	end

	def test_directories
		assert_equal 5, @ole.dirents.length, 'have all directories'
		# a more complicated one would be good for this
		assert_equal 4, @ole.root.children.length, 'properly nested directories'
	end

	def test_utf16_conversion
		assert_equal 'Root Entry', @ole.root.name
		assert_equal 'WordDocument', @ole.root.children[2].name
	end

	def test_read
		# the regular String#hash was different on the mac, so asserting
		# against full strings. switch this to sha1 instead of this fugly blob
		sha1sums = %w[
			d3d1cde9eb43ed4b77d197af879f5ca8b8837577
			65b75cbdd1f94ade632baeeb0848dec2a342c844
			cfc230ec7515892cfdb85e4a173e0ce364094970
			ffd859d94647a11b693f06f092d1a2bccc59d50d
		]

		# test the ole storage type
		type = 'Microsoft Word 6.0-Dokument'
		assert_equal type, (@ole.root/"\001CompObj").read[32..-1][/([^\x00]+)/m, 1]
		# i was actually not loading data correctly before, so carefully check everything here
		assert_equal sha1sums, @ole.root.children.map { |child| Digest::SHA1.hexdigest child.read }
	end

	def test_dirent
		dirent = @ole.root.children.first
		assert_equal "\001Ole", dirent.name
		assert_equal 20, dirent.size
		assert_equal '#<Dirent:"Root Entry">', @ole.root.inspect
		
		# exercise Dirent#[]. note that if you use a number, you get the Struct
		# fields.
		assert_equal dirent, @ole.root["\001Ole"]
		assert_equal dirent.name_utf16, dirent[0]
		assert_equal nil, @ole.root.time
		
		assert_equal @ole.root.children, @ole.root.to_enum(:each_child).to_a

		dirent.open('r') { |f| assert_equal 2, f.first_block }
		dirent.open('w') { |f| }
		dirent.open('a') { |f| }
	end

	def test_delete
		dirent = @ole.root.children.first
		assert_raises(ArgumentError) { @ole.root.delete nil }
		assert_equal [dirent], @ole.root.children & [dirent]
		assert_equal 20, dirent.size
		@ole.root.delete dirent
		assert_equal [], @ole.root.children & [dirent]
		assert_equal 0, dirent.size
	end
end

class TestStorageWrite < Test::Unit::TestCase
	TEST_DIR = File.dirname __FILE__

	def sha1 str
		Digest::SHA1.hexdigest str
	end

	# try and test all the various things the #flush function does
	def test_flush
	end
	
	# FIXME
	# don't really want to lock down the actual internal api's yet. this will just
	# ensure for the time being that #flush continues to work properly. need a host
	# of checks involving writes that resize their file bigger/smaller, that resize
	# the bats to more blocks, that resizes the sb_blocks, that has migration etc.
	def test_write_hash
		io = StringIO.open open("#{TEST_DIR}/test_word_6.doc", 'rb', &:read)
		assert_equal '9974e354def8471225f548f82b8d81c701221af7', sha1(io.string)
		Ole::Storage.open(io, :update_timestamps => false) { }
		# hash changed. used to be efa8cfaf833b30b1d1d9381771ddaafdfc95305c
		# thats because i now truncate the io, and am probably removing some trailing
		# allocated available blocks.
		assert_equal 'a39e3c4041b8a893c753d50793af8d21ca8f0a86', sha1(io.string)
		# add a repack test here
		Ole::Storage.open io, :update_timestamps => false, &:repack
		assert_equal 'c8bb9ccacf0aaad33677e1b2a661ee6e66a48b5a', sha1(io.string)
	end

	def test_plain_repack
		io = StringIO.open open("#{TEST_DIR}/test_word_6.doc", 'rb', &:read)
		assert_equal '9974e354def8471225f548f82b8d81c701221af7', sha1(io.string)
		Ole::Storage.open io, :update_timestamps => false, &:repack
		# note equivalence to the above flush, repack, flush
		assert_equal 'c8bb9ccacf0aaad33677e1b2a661ee6e66a48b5a', sha1(io.string)
		# lets do it again using memory backing
		Ole::Storage.open(io, :update_timestamps => false) { |ole| ole.repack :mem }
		# note equivalence to the above flush, repack, flush
		assert_equal 'c8bb9ccacf0aaad33677e1b2a661ee6e66a48b5a', sha1(io.string)
		assert_raises ArgumentError do
			Ole::Storage.open(io, :update_timestamps => false) { |ole| ole.repack :typo }
		end
	end

	def test_create_from_scratch_hash
		io = StringIO.new(''.dup)
		Ole::Storage.open(io) { }
		assert_equal '6bb9d6c1cdf1656375e30991948d70c5fff63d57', sha1(io.string)
		# more repack test, note invariance
		Ole::Storage.open io, :update_timestamps => false, &:repack
		assert_equal '6bb9d6c1cdf1656375e30991948d70c5fff63d57', sha1(io.string)
	end

	def test_create_dirent
		Ole::Storage.open StringIO.new do |ole|
			dirent = Ole::Storage::Dirent.new ole, :name => 'test name', :type => :dir
			assert_equal 'test name', dirent.name
			assert_equal :dir, dirent.type
			# for a dirent created from scratch, type_id is currently not set until serialization:
			assert_equal 0, dirent.type_id
			dirent.to_s
			assert_equal 1, dirent.type_id
			assert_raises(ArgumentError) { Ole::Storage::Dirent.new ole, :type => :bogus }
		end
	end
end

