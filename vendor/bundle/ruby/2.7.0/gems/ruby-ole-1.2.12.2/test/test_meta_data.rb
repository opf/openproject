#! /usr/bin/ruby

$: << File.dirname(__FILE__) + '/../lib'

require 'test/unit'
require 'ole/storage'

class TestMetaData < Test::Unit::TestCase
	def test_meta_data
		Ole::Storage.open File.dirname(__FILE__) + '/test.doc', 'rb' do |ole|
			assert_equal 'Charles Lowe', ole.meta_data[:doc_author]
			assert_equal 'Charles Lowe', ole.meta_data['doc_author']
			assert_equal 'Charles Lowe', ole.meta_data.to_h[:doc_author]
			assert_equal 'Title', ole.meta_data.doc_title
			assert_equal 'MSWordDoc', ole.meta_data.file_format
			assert_equal 'application/msword', ole.meta_data.mime_type
			assert_raises NotImplementedError do
				ole.meta_data[:doc_author] = 'New Author'
			end
		end
	end
	
	# this tests the other ways of getting the mime_type, than using "\001CompObj",
	# ie, relying on root clsid, and on the heuristics
	def test_mime_type
		ole = Ole::Storage.new StringIO.new
		ole.root.clsid = Ole::Storage::MetaData::CLSID_EXCEL97.to_s
		assert_equal nil, ole.meta_data.file_format
		assert_equal 'application/vnd.ms-excel', ole.meta_data.mime_type
		
		ole.root.clsid = 0.chr * Ole::Types::Clsid::SIZE
		assert_equal nil, ole.meta_data.file_format
		assert_equal 'application/x-ole-storage', ole.meta_data.mime_type
		
		ole.file.open('Book', 'w') { |f| }
		assert_equal 'application/vnd.ms-excel', ole.meta_data.mime_type
		ole.file.open('WordDocument', 'w') { |f| }
		assert_equal 'application/msword', ole.meta_data.mime_type
		ole.file.open('__properties_version1.0', 'w') { |f| }
		assert_equal 'application/vnd.ms-outlook', ole.meta_data.mime_type
	end
end

