#! /usr/bin/ruby

$: << File.dirname(__FILE__) + '/../lib'

require 'test/unit'
require 'ole/types'

class TestPropertySet < Test::Unit::TestCase
	include Ole::Types

	def setup
		@io = open File.dirname(__FILE__) + '/test_SummaryInformation', 'rb'
	end

	def teardown
		@io.close
	end

	def test_property_set
		propset = PropertySet.new @io
		assert_equal :mac, propset.os
		assert_equal 1, propset.sections.length
		section = propset.sections.first
		assert_equal 14, section.length
		assert_equal 'f29f85e0-4ff9-1068-ab91-08002b27b3d9', section.guid.format
		assert_equal PropertySet::FMTID_SummaryInformation, section.guid
		assert_equal 'Charles Lowe', section.to_a.assoc(4).last
		assert_equal 'Charles Lowe', propset.doc_author
		assert_equal 'Charles Lowe', propset.to_h[:doc_author]

		# knows the difference between existent and non-existent properties
		assert_raise(NoMethodError) { propset.non_existent_key }
		assert_raise(NotImplementedError) { propset.doc_author = 'New Author'}
		assert_raise(NoMethodError) { propset.non_existent_key = 'Value'}
		
		# a valid property that has no value in this property set
		assert_equal nil, propset.security
	end
end

