#!/usr/bin/env ruby
# TestWorkbook -- Spreadsheet -- 24.09.2008 -- hwyss@ywesee.com

$: << File.expand_path('../lib', File.dirname(__FILE__))

require 'test/unit'
require 'spreadsheet'
require 'fileutils'
require 'stringio'

module Spreadsheet
  class TestWorkbook < Test::Unit::TestCase
    def setup
      @io = StringIO.new ''
      @book = Workbook.new
    end
    def test_writer__default_excel
      assert_instance_of Excel::Writer::Workbook, @book.writer(@io)
    end
    def test_sheet_count
        @worksheet1 = Excel::Worksheet.new
        @book.add_worksheet @worksheet1
        assert_equal 1, @book.sheet_count
        @worksheet2 = Excel::Worksheet.new
        @book.add_worksheet @worksheet2
        assert_equal 2, @book.sheet_count
    end
    def test_add_format

      assert_equal 1, @book.formats.length # Received a default format

      f1 = Format.new
      @book.add_format f1
      assert_equal 2, @book.formats.length

      f2 = Format.new
      @book.add_format f2
      assert_equal 3, @book.formats.length

      @book.add_format f2
      assert_equal 3, @book.formats.length # Rejected duplicate insertion
    end

    def test_delete_worksheet
      original_count = @book.sheet_count
      @sheet = @book.create_worksheet
      changed_count = @book.sheet_count
      @book.delete_worksheet(@book.sheet_count - 1)

      assert_equal(changed_count, original_count + 1)
      assert_equal(original_count, @book.sheet_count)
    end

  end
end
