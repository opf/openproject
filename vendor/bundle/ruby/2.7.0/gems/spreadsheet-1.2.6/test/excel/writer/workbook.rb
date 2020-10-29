#!/usr/bin/env ruby
# Excel::Writer::TestWorkbook -- Spreadsheet -- 20.07.2011 -- vanderhoorn@gmail.com

$: << File.expand_path('../../../lib', File.dirname(__FILE__))

require 'test/unit'
require 'spreadsheet'

module Spreadsheet
  module Excel
    module Writer
      class TestWorkbook < Test::Unit::TestCase
        def setup
          @book = Spreadsheet::Excel::Workbook.new
          assert_instance_of Excel::Workbook, @book
          assert_equal @book.worksheets.size, 0
          @workbook_writer = Excel::Writer::Workbook.new @book
        end
        def test_sanitize_worksheets
          assert_nothing_raised { @workbook_writer.sanitize_worksheets @book.worksheets }
        end
        def test_collect_formats
          assert_equal 17, @workbook_writer.collect_formats(@book).length # Expected for vanilla
          sheet = @book.create_worksheet
          rowi=-1

          f1 = Spreadsheet::Format.new
          sheet.row(rowi+=1).default_format = f1
          assert_equal 18, @workbook_writer.collect_formats(@book).length

          f2 = Spreadsheet::Format.new
          sheet.row(rowi+=1).default_format = f2
          assert_equal 19, @workbook_writer.collect_formats(@book).length

          sheet.row(rowi+=1).default_format = f2
          assert_equal 19, @workbook_writer.collect_formats(@book).length # Ignores duplicates
        end
        def test_xf_index
          sheet = @book.create_worksheet
          rowi=-1

          f1 = Spreadsheet::Format.new
          sheet.row(rowi+=1).default_format = f1
          @workbook_writer.collect_formats(@book)
          assert_equal 17, @workbook_writer.xf_index(@book, f1)

          f2 = Spreadsheet::Format.new
          sheet.row(rowi+=1).default_format = f2
          @workbook_writer.collect_formats(@book)
          assert_equal 18, @workbook_writer.xf_index(@book, f2)

        end
        def test_write_fonts
          num_written = 0
          sheet = @book.create_worksheet
          rowi=-1
          # Stub inner #write_font as a counter:
          (class << @workbook_writer; self; end).send(:define_method, :write_font) do |*args|
            num_written += 1
          end
          io = StringIO.new("")

          num_written = 0
          @workbook_writer.collect_formats(@book)
          @workbook_writer.write_fonts(@book, io)
          assert_equal 1, num_written # Default format's font

          f1 = Spreadsheet::Format.new
          sheet.row(rowi+=1).default_format = f1
          num_written = 0
          @workbook_writer.collect_formats(@book)
          @workbook_writer.write_fonts(@book, io)
          assert_equal 1, num_written # No new fonts

          f2 = Spreadsheet::Format.new
          f2.font = Spreadsheet::Font.new("Foo")
          sheet.row(rowi+=1).default_format = f2
          num_written = 0
          @workbook_writer.collect_formats(@book)
          @workbook_writer.write_fonts(@book, io)
          assert_equal 2, num_written # 2 distinct fonts total

          f3 = Spreadsheet::Format.new
          f3.font = f2.font # Re-use previous font
          sheet.row(rowi+=1).default_format = f3
          num_written = 0
          @workbook_writer.collect_formats(@book)
          @workbook_writer.write_fonts(@book, io)
          assert_equal 2, num_written # 2 distinct fonts total still

        end
      end
    end
  end
end
