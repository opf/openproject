#! /usr/bin/ruby

$: << File.dirname(__FILE__) + '/../lib'

require 'test/unit'
require 'ole/storage'
require 'tempfile'

class TestWriteMbat < Test::Unit::TestCase
	def test_write_mbat
		Tempfile.open 'myolefile' do |temp|
			temp.binmode

			# this used to raise an error at flush time, due to failure to write the mbat
			Ole::Storage.open temp do |ole|
				# create a 10mb file
				ole.file.open 'myfile', 'w' do |f|
					s = 0.chr * 1_000_000
					10.times { f.write s }
				end
			end

			assert((10_000_000..10_100_000) === temp.size, 'check file size')

			Ole::Storage.open temp do |ole|
				assert_equal 10_000_000, ole.file.size('myfile')
				compare = ole.bbat.truncate[(0...ole.bbat.length).find { |i| ole.bbat[i] > 50_000 }..-1]
				c = Ole::Storage::AllocationTable
				# 10_000_000 * 4 / 512 / 512 rounded up is 153. but then there is room needed to store the
				# bat in the bat, and the mbat too. hence 154. 
				expect = [c::EOC] * 2 + [c::BAT] * 154 + [c::META_BAT]
				assert_equal expect, compare, 'allocation table structure'
				# the sbat should be empty. in fact the file shouldn't exist at all, so the root's first
				# block should be EOC
				assert ole.sbat.empty?
				assert_equal c::EOC, ole.root.first_block
			end
		end
	end
end
