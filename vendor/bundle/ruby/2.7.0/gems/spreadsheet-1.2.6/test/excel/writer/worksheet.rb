#!/usr/bin/env ruby
# Excel::Writer::TestWorksheet -- Spreadheet -- 21.11.2007 -- hwyss@ywesee.com

require 'test/unit'
require 'spreadsheet/excel/writer/worksheet'

module Spreadsheet
  module Excel
    module Writer
      class TestWorksheet < Test::Unit::TestCase
        def test_need_number
          sheet = Worksheet.new nil, nil
          assert_equal false, sheet.need_number?(10)
          assert_equal false, sheet.need_number?(114.55)
          assert_equal false, sheet.need_number?(0.1)
          assert_equal false, sheet.need_number?(0.01)
          assert_equal false, sheet.need_number?(0 / 0.0) # NaN
          assert_equal true, sheet.need_number?(0.001)
          assert_equal true, sheet.need_number?(10000000.0)
        end

        class RowMock
          attr_accessor :idx, :first_used, :first_unused, :height, :outline_level

          def initialize
            @idx, @first_used, @first_unused, @height, @outline_level = 0,0,0,0,1
          end

          def method_missing name, *args
            nil
          end
        end

        def test_write_row_should_not_write_if_the_row_has_no_used_columns
          sheet = Worksheet.new nil, nil
          row = RowMock.new
          row.first_used = nil

          sheet.write_row row

          assert_equal '', sheet.data
        end

        def test_write_row_should_write_if_any_column_is_used
          sheet = Worksheet.new nil, nil
          row = RowMock.new

          sheet.write_row row

          assert_equal false, sheet.data.empty?
        end

        def test_strings
          book = Spreadsheet::Excel::Workbook.new
          sheet = book.create_worksheet
          writer = Worksheet.new book, sheet
          rowi = -1

          assert_equal(
            {},
            writer.strings
          )

          sheet.row(rowi+=1).concat(["Hello", "World"])
          assert_equal(
            {"Hello" => 1, "World" => 1},
            writer.strings
          )

          sheet.row(rowi+=1).concat(["Goodbye", "Cruel", "World", 2012])
          assert_equal(
            {"Hello" => 1, "Goodbye" => 1, "Cruel" => 1, "World" => 2},
            writer.strings
          )

        end

      end
    end
  end
end
