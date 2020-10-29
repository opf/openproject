#!/usr/bin/env ruby
# TestWorksheet -- Spreadheet -- 30.09.2008 -- hwyss@ywesee.com

$: << File.expand_path('../lib', File.dirname(__FILE__))

require 'test/unit'
require 'spreadsheet'

module Spreadsheet
  class TestWorksheet < Test::Unit::TestCase
    def setup
      @book = Workbook.new
      @sheet = @book.create_worksheet
    end
    def test_cell_writer
      assert_nil @sheet[0,0]
      assert_equal 0, @sheet.column_count
      assert_equal 0, @sheet.row_count
      @sheet[0,0] = 'foo'
      assert_equal 'foo', @sheet[0,0]
      assert_equal 1, @sheet.column_count
      assert_equal 1, @sheet.row_count
      @sheet[1,0] = 'bar'
      assert_equal 1, @sheet.column_count
      assert_equal 2, @sheet.row_count
      @sheet[0,1] = 'bar'
      assert_equal 2, @sheet.column_count
      assert_equal 2, @sheet.row_count
      @sheet[1,0] = nil
      assert_equal 2, @sheet.column_count
      assert_equal 2, @sheet.row_count
      @sheet[0,1] = nil
      assert_equal 2, @sheet.column_count
      assert_equal 2, @sheet.row_count
    end
    def test_column_count
      assert_equal 0, @sheet.column_count
      @sheet.replace_row 3, nil, nil, 1, 2, 'foo, bar'
      assert_equal 3, @sheet.column_count
      @sheet.replace_row 8, nil, 'something', 4, 7, nil
      assert_equal 4, @sheet.column_count
      @sheet.replace_row 5, 4, 'something', 4, 7, nil
      assert_equal 5, @sheet.column_count
      @sheet.replace_row 5, nil, 'something', 4, 7, nil
      assert_equal 4, @sheet.column_count
      @sheet.replace_row 3
      assert_equal 4, @sheet.column_count
    end
    def test_row_count
      assert_equal 0, @sheet.row_count
      @sheet.replace_row 3, nil, nil, 1, 2, 'foo, bar'
      assert_equal 1, @sheet.row_count
      @sheet.replace_row 8, nil, 'something', 4, 7, nil
      assert_equal 6, @sheet.row_count
      @sheet.replace_row 5, 4, 'something', 4, 7, nil
      assert_equal 6, @sheet.row_count
      @sheet.replace_row 5, nil, 'something', 4, 7, nil
      assert_equal 6, @sheet.row_count
      @sheet.replace_row 3
      assert_equal 6, @sheet.row_count
      @sheet.delete_row 3
      assert_equal 5, @sheet.row_count
      @sheet.delete_row 3
      assert_equal 4, @sheet.row_count
      @sheet.delete_row 2
      assert_equal 4, @sheet.row_count
      @sheet.delete_row 2
      assert_equal 3, @sheet.row_count
    end
    def test_modify_column
      assert_equal 10, @sheet.column(0).width
      @sheet.column(1).width = 20
      assert_equal 10, @sheet.column(0).width
      assert_equal 20, @sheet.column(1).width
      @sheet.column(0).width = 30
      assert_equal 30, @sheet.column(0).width
      assert_equal 20, @sheet.column(1).width
    end
    def test_format_dates!
      rowi = -1

      @sheet.format_dates!
      # No dates = no new formats
      assert_equal 1, @book.formats.length # Default format

      @sheet.row(rowi+=1).concat(["Hello", "World"])
      @sheet.format_dates!
      # No dates = no new formats
      assert_equal 1, @book.formats.length

      @sheet.row(rowi+=1).concat([Date.new(2010,1,1)])
      @sheet.format_dates!
      # 1 date = 1 new format
      assert_equal 2, @book.formats.length

      @sheet.row(rowi+=1).concat([Date.new(2011,1,1)])
      @sheet.row(rowi+=1).concat([Date.new(2012,1,1)])
      @sheet.row(rowi+=1).concat([Date.new(2013,1,1)])
      @sheet.format_dates!
      # 4 dates = only 1 new format across them:
      assert_equal 3, @book.formats.length

      @sheet.row(rowi+=1).concat([Date.new(2014,1,1)])
      @sheet.row(rowi).default_format = Format.new
      @sheet.row(rowi+=1).concat([Date.new(2015,1,1)])
      @sheet.format_dates!
      # 6 dates = 2 new formats across them:
      assert_equal 6, @book.formats.length

    end

    def test_freeze_panel!
      assert_equal 0, @sheet.froze_top
      assert_equal 0, @sheet.froze_left
      assert_equal false, @sheet.has_frozen_panel?

      @sheet.freeze!(2, 3)
      assert_equal 2, @sheet.froze_top
      assert_equal 3, @sheet.froze_left
      assert_equal true, @sheet.has_frozen_panel?

    end

    def test_each_with_skip
      @sheet[0, 0] = 'foo'
      @sheet[1, 0] = 'bar'

      assert_equal @sheet.each(1).count, 1
      assert_equal @sheet.each(1).first[0], 'bar'
    end

    def test_each_with_index
      @sheet[0, 0] = 'foo'
      @sheet[1, 0] = 'bar'

      @sheet.each.with_index do |row, index|
        assert_equal row[0], @sheet[index, 0]
      end
    end

  end
end
