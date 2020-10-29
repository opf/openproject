#!/usr/bin/env ruby
# TestRow -- Spreadsheet -- 08.01.2009 -- hwyss@ywesee.com

$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'test/unit'
require 'spreadsheet'

module Spreadsheet
  class TestRow < Test::Unit::TestCase
    def setup
      @workbook = Excel::Workbook.new
      @worksheet = Excel::Worksheet.new
      @workbook.add_worksheet @worksheet
    end
    def test_formatted
      row = Row.new @worksheet, 0, [nil, 1]
      assert_equal 2, row.formatted.size
      row.set_format 3, Format.new
      assert_equal 4, row.formatted.size
    end
    def test_concat
      row = Row.new @worksheet, 0, [nil, 1, nil]
      assert_equal [nil, 1, nil], row
      row.concat [2, nil]
      assert_equal [nil, 1, nil, 2, nil], row
      row.concat [3]
      assert_equal [nil, 1, nil, 2, nil, 3], row
      row.concat [nil, 4]
      assert_equal [nil, 1, nil, 2, nil, 3, nil, 4], row
    end
  end
end
