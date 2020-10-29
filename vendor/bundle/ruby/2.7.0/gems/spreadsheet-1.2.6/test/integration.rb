#!/usr/bin/env ruby
# encoding: utf-8
# TestIntegration -- spreadheet -- 07.09.2011 -- mhatakeyama@ywesee.com
# TestIntegration -- spreadheet -- 08.10.2007 -- hwyss@ywesee.com

$: << File.expand_path('../lib', File.dirname(__FILE__))

require 'test/unit'
require 'spreadsheet'
require 'fileutils'

module Spreadsheet
  class TestIntegration < Test::Unit::TestCase
    if RUBY_VERSION >= '1.9'
      class IconvStub
        def initialize to, from
          @to, @from = to, from
        end
        def iconv str
          dp = str.dup
          dp.force_encoding @from
          dp.encode @to
        end
      end
      @@iconv = IconvStub.new('UTF-16LE', 'UTF-8')
      @@bytesize = :bytesize
    else
      @@iconv = Iconv.new('UTF-16LE', 'UTF-8')
      @@bytesize = :size
    end
    def setup
      @var = File.expand_path 'var', File.dirname(__FILE__)
      FileUtils.mkdir_p @var
      @data = File.expand_path 'data', File.dirname(__FILE__)
      FileUtils.mkdir_p @data
    end
    def teardown
      Spreadsheet.client_encoding = 'UTF-8'
      FileUtils.rm_rf @var
    end
    def test_copy__identical__file_paths
      path = File.join @data, 'test_copy.xls'
      copy = File.join @data, 'test_copy1.xls'
      book = Spreadsheet.open path
      assert_instance_of Excel::Workbook, book
      book.write copy
      assert_equal File.read(path), File.read(copy)
    ensure
      File.delete copy if File.exist? copy
    end
    def test_empty_workbook
      path = File.join @data, 'test_empty.xls'
      book = Spreadsheet.open path
      assert_instance_of Excel::Workbook, book
      assert_equal 8, book.biff_version
      assert_equal 'Microsoft Excel 97/2000/XP', book.version_string
      enc = 'UTF-16LE'
      if defined? Encoding
        enc = Encoding.find enc
      end
      assert_equal enc, book.encoding
      assert_equal 21, book.formats.size
      assert_equal 4, book.fonts.size
      assert_equal 0, book.sst.size
      sheet = book.worksheet 0
      assert_equal 0, sheet.row_count
      assert_equal 0, sheet.column_count
      assert_nothing_raised do sheet.inspect end
    end
    def test_missing_format
      path = File.join @data, 'test_missing_format.xls'
      assert_nothing_thrown do
        Spreadsheet.open(path, "rb")
      end
    end
    def test_version_excel97__excel2010__utf16
      Spreadsheet.client_encoding = 'UTF-16LE'
      assert_equal 'UTF-16LE', Spreadsheet.client_encoding
      path = File.join @data, 'test_version_excel97_2010.xls'
      book = Spreadsheet.open path
      assert_instance_of Excel::Workbook, book
      assert_equal 8, book.biff_version
      assert_equal @@iconv.iconv('Microsoft Excel 97/2000/XP'),
                   book.version_string
      enc = 'UTF-16LE'
      if defined? Encoding
        enc = Encoding.find enc
      end
      assert_equal enc, book.encoding
      sheet = book.worksheet 0
      row = sheet.row 9
      assert_equal 0.00009, row[0]
      link = row[1]
      assert_instance_of Link, link
      assert_equal @@iconv.iconv('Link-Text'), link
      assert_equal @@iconv.iconv('http://scm.ywesee.com/spreadsheet'), link.url
      assert_equal @@iconv.iconv('http://scm.ywesee.com/spreadsheet'), link.href
    end
    def test_version_excel97__ooffice__utf16
      Spreadsheet.client_encoding = 'UTF-16LE'
      assert_equal 'UTF-16LE', Spreadsheet.client_encoding
      path = File.join @data, 'test_version_excel97.xls'
      book = Spreadsheet.open path
      assert_instance_of Excel::Workbook, book
      assert_equal 8, book.biff_version
      assert_equal @@iconv.iconv('Microsoft Excel 97/2000/XP'),
                   book.version_string
      enc = 'UTF-16LE'
      if defined? Encoding
        enc = Encoding.find enc
      end
      assert_equal enc, book.encoding
      assert_equal 25, book.formats.size
      assert_equal 5, book.fonts.size
      str1 = @@iconv.iconv('Shared String')
      str2 = @@iconv.iconv('Another Shared String')
      str3 = @@iconv.iconv('1234567890 ' * 1000)
      str4 = @@iconv.iconv('9876543210 ' * 1000)
      assert_valid_sst(book, :contains => [str1, str2, str3, str4])
      sheet = book.worksheet 0
      assert_equal 11, sheet.row_count
      assert_equal 12, sheet.column_count
      useds = [0,0,0,0,0,0,0,1,0,0,11]
      unuseds = [2,2,1,1,1,2,1,11,1,2,12]
      sheet.each do |row|
        assert_equal useds.shift, row.first_used
        assert_equal unuseds.shift, row.first_unused
      end
      assert unuseds.empty?, "not all rows were visited in Spreadsheet#each"
      row = sheet.row 0
      assert_equal str1, row[0]
      assert_equal str1, sheet[0,0]
      assert_equal str1, sheet.cell(0,0)
      assert_equal str1, row[1]
      assert_equal str1, sheet[0,1]
      assert_equal str1, sheet.cell(0,1)
      row = sheet.row 1
      assert_equal str2, row[0]
      assert_equal str2, sheet[1,0]
      assert_equal str2, sheet.cell(1,0)
      assert_equal str2, row[1]
      assert_equal str2, sheet[1,1]
      assert_equal str2, sheet.cell(1,1)
      row = sheet.row 2
      assert_equal str3, row[0]
      assert_equal str3, sheet[2,0]
      assert_equal str3, sheet.cell(2,0)
      assert_nil row[1]
      assert_nil sheet[2,1]
      assert_nil sheet.cell(2,1)
      row = sheet.row 3
      assert_equal str4, row[0]
      assert_equal str4, sheet[3,0]
      assert_equal str4, sheet.cell(3,0)
      assert_nil row[1]
      assert_nil sheet[3,1]
      assert_nil sheet.cell(3,1)
      row = sheet.row 4
      assert_equal 0.25, row[0]
      assert_equal 0.25, sheet[4,0]
      assert_equal 0.25, sheet.cell(4,0)
      row = sheet.row 5
      assert_equal 0.75, row[0]
      assert_equal 0.75, sheet[5,0]
      assert_equal 0.75, sheet.cell(5,0)
      date = Date.new 1975, 8, 21
      assert_equal date, row[1]
      assert_equal date, sheet[5,1]
      assert_equal date, sheet.cell(5,1)
      row = sheet.row 6
      assert_equal 1, row[0]
      assert_equal 1, sheet[6,0]
      assert_equal 1, sheet.cell(6,0)
      row = sheet.row 7
      assert_nil row[0]
      assert_equal [1,2,3,4,5,6,7,8,9,0], row[1,10]
      assert_equal [1,2,3,4,5,6,7,8,9,0], sheet[7,1..10]
      assert_equal [1,2,3,4,5,6,7,8,9,0], sheet.cell(7,1..10)
      row = sheet.row 8
      assert_equal 0.0001, row[0]
      row = sheet.row 9
      assert_equal 0.00009, row[0]
      assert_equal :green, sheet.row(10).format(11).pattern_fg_color
    end
    def test_version_excel97__ooffice
      path = File.join @data, 'test_version_excel97.xls'
      book = Spreadsheet.open path
      assert_instance_of Excel::Workbook, book
      assert_equal 8, book.biff_version
      assert_equal 'Microsoft Excel 97/2000/XP', book.version_string
      enc = 'UTF-16LE'
      if defined? Encoding
        enc = Encoding.find enc
      end
      assert_equal enc, book.encoding
      assert_equal 25, book.formats.size
      assert_equal 5, book.fonts.size
      str1 = 'Shared String'
      str2 = 'Another Shared String'
      str3 = '1234567890 ' * 1000
      str4 = '9876543210 ' * 1000
      assert_valid_sst(book, :contains => [str1, str2, str3, str4])
      sheet = book.worksheet 0
      assert_equal 11, sheet.row_count
      assert_equal 12, sheet.column_count
      useds = [0,0,0,0,0,0,0,1,0,0,11]
      unuseds = [2,2,1,1,1,2,1,11,1,2,12]
      sheet.each do |row|
        assert_equal useds.shift, row.first_used
        assert_equal unuseds.shift, row.first_unused
      end
      assert unuseds.empty?, "not all rows were visited in Spreadsheet#each"
      row = sheet.row 0
      assert_equal str1, row[0]
      assert_equal str1, sheet[0,0]
      assert_equal str1, sheet.cell(0,0)
      assert_equal str1, row[1]
      assert_equal str1, sheet[0,1]
      assert_equal str1, sheet.cell(0,1)
      row = sheet.row 1
      assert_equal str2, row[0]
      assert_equal str2, sheet[1,0]
      assert_equal str2, sheet.cell(1,0)
      assert_equal str2, row[1]
      assert_equal str2, sheet[1,1]
      assert_equal str2, sheet.cell(1,1)
      row = sheet.row 2
      assert_equal str3, row[0]
      assert_equal str3, sheet[2,0]
      assert_equal str3, sheet.cell(2,0)
      assert_nil row[1]
      assert_nil sheet[2,1]
      assert_nil sheet.cell(2,1)
      row = sheet.row 3
      assert_equal str4, row[0]
      assert_equal str4, sheet[3,0]
      assert_equal str4, sheet.cell(3,0)
      assert_nil row[1]
      assert_nil sheet[3,1]
      assert_nil sheet.cell(3,1)
      row = sheet.row 4
      assert_equal 0.25, row[0]
      assert_equal 0.25, sheet[4,0]
      assert_equal 0.25, sheet.cell(4,0)
      row = sheet.row 5
      assert_equal 0.75, row[0]
      assert_equal 0.75, sheet[5,0]
      assert_equal 0.75, sheet.cell(5,0)
      date = Date.new 1975, 8, 21
      assert_equal date, row[1]
      assert_equal date, sheet[5,1]
      assert_equal date, sheet.cell(5,1)
      row = sheet.row 6
      assert_equal 1, row[0]
      assert_equal 1, sheet[6,0]
      assert_equal 1, sheet.cell(6,0)
      row = sheet.row 7
      assert_nil row[0]
      assert_equal [1,2,3,4,5,6,7,8,9,0], row[1,10]
      assert_equal [1,2,3,4,5,6,7,8,9,0], sheet[7,1..10]
      assert_equal [1,2,3,4,5,6,7,8,9,0], sheet.cell(7,1..10)
      row = sheet.row 8
      assert_equal 0.0001, row[0]
      row = sheet.row 9
      assert_equal 0.00009, row[0]
      link = row[1]
      assert_instance_of Link, link
      assert_equal 'Link-Text', link
      assert_equal 'http://scm.ywesee.com/spreadsheet', link.url
      assert_equal 'http://scm.ywesee.com/spreadsheet', link.href
    end
    def test_version_excel95__ooffice__utf16
      Spreadsheet.client_encoding = 'UTF-16LE'
      path = File.join @data, 'test_version_excel95.xls'
      book = Spreadsheet.open path
      assert_instance_of Excel::Workbook, book
      assert_equal 5, book.biff_version
      assert_equal @@iconv.iconv('Microsoft Excel 95'), book.version_string
      enc = 'WINDOWS-1252'
      if defined? Encoding
        enc = Encoding.find enc
      end
      assert_equal enc, book.encoding
      str1 = @@iconv.iconv('Shared String')
      str2 = @@iconv.iconv('Another Shared String')
      str3 = @@iconv.iconv(('1234567890 ' * 26)[0,255])
      str4 = @@iconv.iconv(('9876543210 ' * 26)[0,255])
      sheet = book.worksheet 0
      assert_equal 8, sheet.row_count
      assert_equal 11, sheet.column_count
      useds = [0,0,0,0,0,0,0,1]
      unuseds = [2,2,1,1,1,1,1,11]
      sheet.each do |row|
        assert_equal useds.shift, row.first_used
        assert_equal unuseds.shift, row.first_unused
      end
      assert unuseds.empty?, "not all rows were visited in Spreadsheet#each"
      row = sheet.row 0
      assert_equal str1, row[0]
      assert_equal str1, sheet[0,0]
      assert_equal str1, sheet.cell(0,0)
      assert_equal str1, row[1]
      assert_equal str1, sheet[0,1]
      assert_equal str1, sheet.cell(0,1)
      row = sheet.row 1
      assert_equal str2, row[0]
      assert_equal str2, sheet[1,0]
      assert_equal str2, sheet.cell(1,0)
      assert_equal str2, row[1]
      assert_equal str2, sheet[1,1]
      assert_equal str2, sheet.cell(1,1)
      row = sheet.row 2
      assert_equal 510, row[0].send(@@bytesize)
      assert_equal str3, row[0]
      assert_equal str3, sheet[2,0]
      assert_equal str3, sheet.cell(2,0)
      assert_nil row[1]
      assert_nil sheet[2,1]
      assert_nil sheet.cell(2,1)
      row = sheet.row 3
      assert_equal 510, row[0].send(@@bytesize)
      assert_equal str4, row[0]
      assert_equal str4, sheet[3,0]
      assert_equal str4, sheet.cell(3,0)
      assert_nil row[1]
      assert_nil sheet[3,1]
      assert_nil sheet.cell(3,1)
      row = sheet.row 4
      assert_equal 0.25, row[0]
      assert_equal 0.25, sheet[4,0]
      assert_equal 0.25, sheet.cell(4,0)
      row = sheet.row 5
      assert_equal 0.75, row[0]
      assert_equal 0.75, sheet[5,0]
      assert_equal 0.75, sheet.cell(5,0)
      row = sheet.row 6
      assert_equal 1, row[0]
      assert_equal 1, sheet[6,0]
      assert_equal 1, sheet.cell(6,0)
      row = sheet.row 7
      assert_nil row[0]
      assert_equal [1,2,3,4,5,6,7,8,9,0], row[1,10]
      assert_equal [1,2,3,4,5,6,7,8,9,0], sheet[7,1..10]
      assert_equal [1,2,3,4,5,6,7,8,9,0], sheet.cell(7,1..10)
    end
    def test_version_excel95__ooffice
      path = File.join @data, 'test_version_excel95.xls'
      book = Spreadsheet.open path
      assert_instance_of Excel::Workbook, book
      assert_equal 5, book.biff_version
      assert_equal 'Microsoft Excel 95', book.version_string
      enc = 'WINDOWS-1252'
      if defined? Encoding
        enc = Encoding.find enc
      end
      assert_equal enc, book.encoding
      str1 = 'Shared String'
      str2 = 'Another Shared String'
      str3 = ('1234567890 ' * 26)[0,255]
      str4 = ('9876543210 ' * 26)[0,255]
      sheet = book.worksheet 0
      assert_equal 8, sheet.row_count
      assert_equal 11, sheet.column_count
      useds = [0,0,0,0,0,0,0,1]
      unuseds = [2,2,1,1,1,1,1,11]
      sheet.each do |row|
        assert_equal useds.shift, row.first_used
        assert_equal unuseds.shift, row.first_unused
      end
      assert unuseds.empty?, "not all rows were visited in Spreadsheet#each"
      row = sheet.row 0
      assert_equal str1, row[0]
      assert_equal str1, sheet[0,0]
      assert_equal str1, sheet.cell(0,0)
      assert_equal str1, row[1]
      assert_equal str1, sheet[0,1]
      assert_equal str1, sheet.cell(0,1)
      row = sheet.row 1
      assert_equal str2, row[0]
      assert_equal str2, sheet[1,0]
      assert_equal str2, sheet.cell(1,0)
      assert_equal str2, row[1]
      assert_equal str2, sheet[1,1]
      assert_equal str2, sheet.cell(1,1)
      row = sheet.row 2
      assert_equal 255, row[0].send(@@bytesize)
      assert_equal str3, row[0]
      assert_equal str3, sheet[2,0]
      assert_equal str3, sheet.cell(2,0)
      assert_nil row[1]
      assert_nil sheet[2,1]
      assert_nil sheet.cell(2,1)
      row = sheet.row 3
      assert_equal 255, row[0].send(@@bytesize)
      assert_equal str4, row[0]
      assert_equal str4, sheet[3,0]
      assert_equal str4, sheet.cell(3,0)
      assert_nil row[1]
      assert_nil sheet[3,1]
      assert_nil sheet.cell(3,1)
      row = sheet.row 4
      assert_equal 0.25, row[0]
      assert_equal 0.25, sheet[4,0]
      assert_equal 0.25, sheet.cell(4,0)
      row = sheet.row 5
      assert_equal 0.75, row[0]
      assert_equal 0.75, sheet[5,0]
      assert_equal 0.75, sheet.cell(5,0)
      row = sheet.row 6
      assert_equal 1, row[0]
      assert_equal 1, sheet[6,0]
      assert_equal 1, sheet.cell(6,0)
      row = sheet.row 7
      assert_nil row[0]
      assert_equal [1,2,3,4,5,6,7,8,9,0], row[1,10]
      assert_equal [1,2,3,4,5,6,7,8,9,0], sheet[7,1..10]
      assert_equal [1,2,3,4,5,6,7,8,9,0], sheet.cell(7,1..10)
    end
    def test_version_excel5__ooffice
      path = File.join @data, 'test_version_excel5.xls'
      book = Spreadsheet.open path
      assert_instance_of Excel::Workbook, book
      assert_equal 5, book.biff_version
      assert_equal 'Microsoft Excel 95', book.version_string
      enc = 'WINDOWS-1252'
      if defined? Encoding
        enc = Encoding.find enc
      end
      assert_equal enc, book.encoding
      str1 = 'Shared String'
      str2 = 'Another Shared String'
      str3 = ('1234567890 ' * 26)[0,255]
      str4 = ('9876543210 ' * 26)[0,255]
      sheet = book.worksheet 0
      assert_equal 8, sheet.row_count
      assert_equal 11, sheet.column_count
      useds = [0,0,0,0,0,0,0,1]
      unuseds = [2,2,1,1,1,1,1,11]
      sheet.each do |row|
        assert_equal useds.shift, row.first_used
        assert_equal unuseds.shift, row.first_unused
      end
      assert unuseds.empty?, "not all rows were visited in Spreadsheet#each"
      row = sheet.row 0
      assert_equal str1, row[0]
      assert_equal str1, sheet[0,0]
      assert_equal str1, sheet.cell(0,0)
      assert_equal str1, row[1]
      assert_equal str1, sheet[0,1]
      assert_equal str1, sheet.cell(0,1)
      row = sheet.row 1
      assert_equal str2, row[0]
      assert_equal str2, sheet[1,0]
      assert_equal str2, sheet.cell(1,0)
      assert_equal str2, row[1]
      assert_equal str2, sheet[1,1]
      assert_equal str2, sheet.cell(1,1)
      row = sheet.row 2
      assert_equal 255, row[0].send(@@bytesize)
      assert_equal str3, row[0]
      assert_equal str3, sheet[2,0]
      assert_equal str3, sheet.cell(2,0)
      assert_nil row[1]
      assert_nil sheet[2,1]
      assert_nil sheet.cell(2,1)
      row = sheet.row 3
      assert_equal 255, row[0].send(@@bytesize)
      assert_equal str4, row[0]
      assert_equal str4, sheet[3,0]
      assert_equal str4, sheet.cell(3,0)
      assert_nil row[1]
      assert_nil sheet[3,1]
      assert_nil sheet.cell(3,1)
      row = sheet.row 4
      assert_equal 0.25, row[0]
      assert_equal 0.25, sheet[4,0]
      assert_equal 0.25, sheet.cell(4,0)
      row = sheet.row 5
      assert_equal 0.75, row[0]
      assert_equal 0.75, sheet[5,0]
      assert_equal 0.75, sheet.cell(5,0)
      row = sheet.row 6
      assert_equal 1, row[0]
      assert_equal 1, sheet[6,0]
      assert_equal 1, sheet.cell(6,0)
      row = sheet.row 7
      assert_nil row[0]
      assert_equal [1,2,3,4,5,6,7,8,9,0], row[1,10]
      assert_equal [1,2,3,4,5,6,7,8,9,0], sheet[7,1..10]
      assert_equal [1,2,3,4,5,6,7,8,9,0], sheet.cell(7,1..10)
    end
    def test_worksheets
      path = File.join @data, 'test_copy.xls'
      book = Spreadsheet.open path
      sheets = book.worksheets
      assert_equal 3, sheets.size
      sheet = book.worksheet 0
      assert_instance_of Excel::Worksheet, sheet
      assert_equal sheet, book.worksheet('Sheet1')
    end
    def test_worksheets__utf16
      Spreadsheet.client_encoding = 'UTF-16LE'
      path = File.join @data, 'test_copy.xls'
      book = Spreadsheet.open path
      sheets = book.worksheets
      assert_equal 3, sheets.size
      sheet = book.worksheet 0
      assert_instance_of Excel::Worksheet, sheet
      str = "S\000h\000e\000e\000t\0001\000".dup
      if RUBY_VERSION >= '1.9'
        str.force_encoding 'UTF-16LE' if str.respond_to?(:force_encoding)
      end
      assert_equal sheet, book.worksheet(str)
    end
    def test_read_datetime
      path = File.join @data, 'test_datetime.xls'
      book = Spreadsheet.open path
      assert_instance_of Excel::Workbook, book
      sheet = book.worksheet 0
      time = sheet[0,0]
      assert_equal 22, time.hour
      assert_equal 00, time.min
      assert_equal 00, time.sec
      time = sheet[1,0]
      assert_equal 1899, time.year
      assert_equal 12, time.month
      assert_equal 30, time.day
      assert_equal 22, time.hour
      assert_equal 30, time.min
      assert_equal 45, time.sec
      time = sheet[0,1]
      assert_equal 1899, time.year
      assert_equal 12, time.month
      assert_equal 31, time.day
      assert_equal 4, time.hour
      assert_equal 30, time.min
      assert_equal 45, time.sec
    end
    def test_change_encoding
      path = File.join @data, 'test_version_excel95.xls'
      book = Spreadsheet.open path
      assert_instance_of Excel::Workbook, book
      assert_equal 5, book.biff_version
      assert_equal 'Microsoft Excel 95', book.version_string
      enc = 'WINDOWS-1252'
      if defined? Encoding
        enc = Encoding.find enc
      end
      assert_equal enc, book.encoding
      enc = 'WINDOWS-1256'
      if defined? Encoding
        enc = Encoding.find enc
      end
      book.encoding = enc
      path = File.join @var, 'test_change_encoding.xls'
      book.write path
      assert_nothing_raised do book = Spreadsheet.open path end
      assert_equal enc, book.encoding
    end
    def test_change_cell
      path = File.join @data, 'test_version_excel97.xls'
      book = Spreadsheet.open path
      assert_instance_of Excel::Workbook, book
      assert_equal 8, book.biff_version
      assert_equal 'Microsoft Excel 97/2000/XP', book.version_string
      path = File.join @var, 'test_change_cell.xls'
      str1 = 'Shared String'
      str2 = 'Another Shared String'
      str3 = '1234567890 ' * 1000
      str4 = '9876543210 ' * 1000
      str5 = "Link-Text"
      assert_valid_sst(book, :is => [str1, str2, str3, str4, str5])
      sheet = book.worksheet 0
      sheet[0,0] = 4
      row = sheet.row 1
      row[0] = 3
      book.write path
      assert_nothing_raised do book = Spreadsheet.open path end
      sheet = book.worksheet 0
      assert_equal 11, sheet.row_count
      assert_equal 12, sheet.column_count
      useds = [0,0,0,0,0,0,0,0,0,0,0]
      unuseds = [2,2,1,1,1,2,1,11,1,2,12]
      sheet.each do |rw|
        assert_equal useds.shift, rw.first_used
        assert_equal unuseds.shift, rw.first_unused
      end
      assert unuseds.empty?, "not all rows were visited in Spreadsheet#each"
      row = sheet.row 0
      assert_equal 4, row[0]
      assert_equal 4, sheet[0,0]
      assert_equal 4, sheet.cell(0,0)
      assert_equal str1, row[1]
      assert_equal str1, sheet[0,1]
      assert_equal str1, sheet.cell(0,1)
      row = sheet.row 1
      assert_equal 3, row[0]
      assert_equal 3, sheet[1,0]
      assert_equal 3, sheet.cell(1,0)
      assert_equal str2, row[1]
      assert_equal str2, sheet[1,1]
      assert_equal str2, sheet.cell(1,1)
      row = sheet.row 2
      assert_equal str3, row[0]
      assert_equal str3, sheet[2,0]
      assert_equal str3, sheet.cell(2,0)
      assert_nil row[1]
      assert_nil sheet[2,1]
      assert_nil sheet.cell(2,1)
      row = sheet.row 3
      assert_equal str4, row[0]
      assert_equal str4, sheet[3,0]
      assert_equal str4, sheet.cell(3,0)
      assert_nil row[1]
      assert_nil sheet[3,1]
      assert_nil sheet.cell(3,1)
      row = sheet.row 4
      assert_equal 0.25, row[0]
      assert_equal 0.25, sheet[4,0]
      assert_equal 0.25, sheet.cell(4,0)
      row = sheet.row 5
      assert_equal 0.75, row[0]
      assert_equal 0.75, sheet[5,0]
      assert_equal 0.75, sheet.cell(5,0)
      date = Date.new 1975, 8, 21
      assert_equal date, row[1]
      assert_equal date, sheet[5,1]
      assert_equal date, sheet.cell(5,1)
      row = sheet.row 6
      assert_equal 1, row[0]
      assert_equal 1, sheet[6,0]
      assert_equal 1, sheet.cell(6,0)
      row = sheet.row 7
      assert_nil row[0]
      assert_equal [1,2,3,4,5,6,7,8,9,0], row[1,10]
      assert_equal [1,2,3,4,5,6,7,8,9,0], sheet[7,1..10]
      assert_equal [1,2,3,4,5,6,7,8,9,0], sheet.cell(7,1..10)
      row = sheet.row 8
      assert_equal 0.0001, row[0]
      row = sheet.row 9
      assert_equal 0.00009, row[0]
    end
    def test_change_cell__complete_sst_rewrite
      path = File.join @data, 'test_version_excel97.xls'
      book = Spreadsheet.open path
      assert_instance_of Excel::Workbook, book
      assert_equal 8, book.biff_version
      assert_equal 'Microsoft Excel 97/2000/XP', book.version_string
      path = File.join @var, 'test_change_cell.xls'
      str1 = 'Shared String'
      str2 = 'Another Shared String'
      str3 = '1234567890 ' * 1000
      str4 = '9876543210 ' * 1000
      str5 = 'Link-Text'
      assert_valid_sst(book, :is => [str1, str2, str3, str4, str5])
      sheet = book.worksheet 0
      sheet[0,0] = 4
      str6 = 'A completely different String'
      sheet[0,1] = str6
      row = sheet.row 1
      row[0] = 3
      book.write path
      assert_nothing_raised do book = Spreadsheet.open path end
      assert_valid_sst(book, :is => [str2, str3, str4, str5, str6])
      sheet = book.worksheet 0
      assert_equal 11, sheet.row_count
      assert_equal 12, sheet.column_count
      useds = [0,0,0,0,0,0,0,0,0,0,0]
      unuseds = [2,2,1,1,1,2,1,11,1,2,12]
      sheet.each do |rw|
        assert_equal useds.shift, rw.first_used
        assert_equal unuseds.shift, rw.first_unused
      end
      assert unuseds.empty?, "not all rows were visited in Spreadsheet#each"
      row = sheet.row 0
      assert_equal 4, row[0]
      assert_equal 4, sheet[0,0]
      assert_equal 4, sheet.cell(0,0)
      assert_equal str6, row[1]
      assert_equal str6, sheet[0,1]
      assert_equal str6, sheet.cell(0,1)
      row = sheet.row 1
      assert_equal 3, row[0]
      assert_equal 3, sheet[1,0]
      assert_equal 3, sheet.cell(1,0)
      assert_equal str2, row[1]
      assert_equal str2, sheet[1,1]
      assert_equal str2, sheet.cell(1,1)
      row = sheet.row 2
      assert_equal str3, row[0]
      assert_equal str3, sheet[2,0]
      assert_equal str3, sheet.cell(2,0)
      assert_nil row[1]
      assert_nil sheet[2,1]
      assert_nil sheet.cell(2,1)
      row = sheet.row 3
      assert_equal str4, row[0]
      assert_equal str4, sheet[3,0]
      assert_equal str4, sheet.cell(3,0)
      assert_nil row[1]
      assert_nil sheet[3,1]
      assert_nil sheet.cell(3,1)
      row = sheet.row 4
      assert_equal 0.25, row[0]
      assert_equal 0.25, sheet[4,0]
      assert_equal 0.25, sheet.cell(4,0)
      row = sheet.row 5
      assert_equal 0.75, row[0]
      assert_equal 0.75, sheet[5,0]
      assert_equal 0.75, sheet.cell(5,0)
      date = Date.new 1975, 8, 21
      assert_equal date, row[1]
      assert_equal date, sheet[5,1]
      assert_equal date, sheet.cell(5,1)
      row = sheet.row 6
      assert_equal 1, row[0]
      assert_equal 1, sheet[6,0]
      assert_equal 1, sheet.cell(6,0)
      row = sheet.row 7
      assert_nil row[0]
      assert_equal [1,2,3,4,5,6,7,8,9,0], row[1,10]
      assert_equal [1,2,3,4,5,6,7,8,9,0], sheet[7,1..10]
      assert_equal [1,2,3,4,5,6,7,8,9,0], sheet.cell(7,1..10)
      row = sheet.row 8
      assert_equal 0.0001, row[0]
      row = sheet.row 9
      assert_equal 0.00009, row[0]
    end
    def test_write_to_stringio
      book = Spreadsheet::Excel::Workbook.new
      sheet = book.create_worksheet :name => 'My Worksheet'
      sheet[0,0] = 'my cell'
      data = StringIO.new ''.dup
      assert_nothing_raised do
        book.write data
      end
      assert_nothing_raised do
        book = Spreadsheet.open data
      end
      assert_instance_of Spreadsheet::Excel::Workbook, book
      assert_equal 1, book.worksheets.size
      sheet = book.worksheet 0
      assert_equal 'My Worksheet', sheet.name
      assert_equal 'my cell', sheet[0,0]
    end
    def test_write_new_workbook
      book = Spreadsheet::Workbook.new
      path = File.join @var, 'test_write_workbook.xls'
      sheet1 = book.create_worksheet
      str1 = 'My Shared String'
      str2 = 'Another Shared String'
      assert_equal 1, (str1.size + str2.size) % 2,
        "str3 should start at an odd offset to test splitting of wide strings"
      str3 = '–––––––––– ' * 1000
      str4 = '1234567890 ' * 1000
      fmt1 = Format.new :italic => true, :color => :blue
      sheet1.format_column 1, fmt1, :width => 20
      fmt2 = Format.new(:weight => :bold, :color => :yellow)
      sheet1.format_column 2, fmt2
      sheet1.format_column 3, Format.new(:weight => :bold, :color => :red)
      sheet1.format_column 6..9, fmt1
      sheet1.format_column [4,5,7], fmt2
      sheet1.row(0).height = 20
      sheet1[0,0] = str1
      sheet1.row(0).push str1
      sheet1.row(1).concat [str2, str2]
      sheet1[2,0] = str3
      sheet1[3,0] = str4
      fmt = Format.new :color => 'red'
      sheet1[4,0] = 0.25
      sheet1.row(4).set_format 0, fmt
      fmt = Format.new :color => 'aqua'
      sheet1[5,0] = 0.75
      sheet1.row(5).set_format 0, fmt
      link = Link.new 'http://scm.ywesee.com/?p=spreadsheet;a=summary',
                      'The Spreadsheet GitWeb', 'top'
      sheet1[5,1] = link
      sheet1[6,0] = 1
      fmt = Format.new :color => 'green'
      sheet1.row(6).set_format 0, fmt
      sheet1[6,1] = Date.new 2008, 10, 10
      sheet1[6,2] = Date.new 2008, 10, 12
      fmt = Format.new :number_format => 'D.M.YY'
      sheet1.row(6).set_format 1, fmt
      sheet1.update_row 7, nil, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0
      sheet1[8,0] = 0.0005
      sheet1[8,1] = 0.005
      sheet1[8,2] = 0.05
      sheet1[8,3] = 10.5
      sheet1[8,4] = 1.05
      sheet1[8,5] = 100.5
      sheet1[8,6] = 10.05
      sheet1[8,7] = 1.005
      sheet1[9,0] = 100.5
      sheet1[9,1] = 10.05
      sheet1[9,2] = 1.005
      sheet1[9,3] = 1000.5
      sheet1[9,4] = 100.05
      sheet1[9,5] = 10.005
      sheet1[9,6] = 1.0005
      sheet1[10,0] = 10000.5
      sheet1[10,1] = 1000.05
      sheet1[10,2] = 100.005
      sheet1[10,3] = 10.0005
      sheet1[10,4] = 1.00005
      sheet1.insert_row 9, ['a', 'b', 'c']
      assert_equal 'a', sheet1[9,0]
      assert_equal 'b', sheet1[9,1]
      assert_equal 'c', sheet1[9,2]
      sheet1.delete_row 9
      row = sheet1.row(11)
      row.height = 40
      row.push 'x'
      row.pop
      book.create_worksheet :name => 'my name' #=> sheet2
      book.write path
      Spreadsheet.client_encoding = 'UTF-16LE'
      str1 = @@iconv.iconv str1
      str2 = @@iconv.iconv str2
      str3 = @@iconv.iconv str3
      str4 = @@iconv.iconv str4
      assert_nothing_raised do book = Spreadsheet.open path end
      if RUBY_VERSION >= '1.9'
        assert_equal 'UTF-16LE', book.encoding.name
      else
        assert_equal 'UTF-16LE', book.encoding
      end
      assert_valid_sst(book, :contains => [str1, str2, str3, str4])
      assert_equal 2, book.worksheets.size
      sheet = book.worksheets.first
      assert_instance_of Spreadsheet::Excel::Worksheet, sheet
      name = "W\000o\000r\000k\000s\000h\000e\000e\000t\0001\000".dup
      name.force_encoding 'UTF-16LE' if name.respond_to?(:force_encoding)
      assert_equal name, sheet.name
      assert_not_nil sheet.offset
      assert_not_nil col = sheet.column(1)
      assert_equal true, col.default_format.font.italic?
      assert_equal :blue, col.default_format.font.color
      assert_equal 20, col.width
      row = sheet.row 0
      assert_equal col.default_format, row.format(1)
      assert_equal 20, row.height
      assert_equal str1, row[0]
      assert_equal str1, sheet[0,0]
      assert_equal str1, sheet.cell(0,0)
      assert_equal str1, row[1]
      assert_equal str1, sheet[0,1]
      assert_equal str1, sheet.cell(0,1)
      row = sheet.row 1
      assert_equal str2, row[0]
      assert_equal str2, sheet[1,0]
      assert_equal str2, sheet.cell(1,0)
      assert_equal str2, row[1]
      assert_equal str2, sheet[1,1]
      assert_equal str2, sheet.cell(1,1)
      row = sheet.row 2
      assert_equal str3, row[0]
      assert_equal str3, sheet[2,0]
      assert_equal str3, sheet.cell(2,0)
      assert_nil row[1]
      assert_nil sheet[2,1]
      assert_nil sheet.cell(2,1)
      row = sheet.row 3
      assert_equal str4, row[0]
      assert_equal str4, sheet[3,0]
      assert_equal str4, sheet.cell(3,0)
      assert_nil row[1]
      assert_nil sheet[3,1]
      assert_nil sheet.cell(3,1)
      row = sheet.row 4
      assert_equal :red, row.format(0).font.color
      assert_equal 0.25, row[0]
      assert_equal 0.25, sheet[4,0]
      assert_equal 0.25, sheet.cell(4,0)
      row = sheet.row 5
      assert_equal :cyan, row.format(0).font.color
      assert_equal 0.75, row[0]
      assert_equal 0.75, sheet[5,0]
      assert_equal 0.75, sheet.cell(5,0)
      link = row[1]
      assert_instance_of Link, link
      url = @@iconv.iconv 'http://scm.ywesee.com/?p=spreadsheet;a=summary'
      assert_equal @@iconv.iconv('The Spreadsheet GitWeb'), link
      assert_equal url, link.url
      assert_equal @@iconv.iconv('top'), link.fragment
      row = sheet.row 6
      assert_equal :green, row.format(0).font.color
      assert_equal 1, row[0]
      assert_equal 1, sheet[6,0]
      assert_equal 1, sheet.cell(6,0)
      assert_equal @@iconv.iconv('D.M.YY'), row.format(1).number_format
      date = Date.new 2008, 10, 10
      assert_equal date, row[1]
      assert_equal date, sheet[6,1]
      assert_equal date, sheet.cell(6,1)
      assert_equal @@iconv.iconv('DD.MM.YYYY'), row.format(2).number_format
      date = Date.new 2008, 10, 12
      assert_equal date, row[2]
      assert_equal date, sheet[6,2]
      assert_equal date, sheet.cell(6,2)
      row = sheet.row 7
      assert_nil row[0]
      assert_equal [1,2,3,4,5,6,7,8,9,0], row[1,10]
      assert_equal [1,2,3,4,5,6,7,8,9,0], sheet[7,1..10]
      assert_equal [1,2,3,4,5,6,7,8,9,0], sheet.cell(7,1..10)
      assert_equal 0.0005, sheet1[8,0]
      assert_equal 0.005, sheet1[8,1]
      assert_equal 0.05, sheet1[8,2]
      assert_equal 10.5, sheet1[8,3]
      assert_equal 1.05, sheet1[8,4]
      assert_equal 100.5, sheet1[8,5]
      assert_equal 10.05, sheet1[8,6]
      assert_equal 1.005, sheet1[8,7]
      assert_equal 100.5, sheet1[9,0]
      assert_equal 10.05, sheet1[9,1]
      assert_equal 1.005, sheet1[9,2]
      assert_equal 1000.5, sheet1[9,3]
      assert_equal 100.05, sheet1[9,4]
      assert_equal 10.005, sheet1[9,5]
      assert_equal 1.0005, sheet1[9,6]
      assert_equal 10000.5, sheet1[10,0]
      assert_equal 1000.05, sheet1[10,1]
      assert_equal 100.005, sheet1[10,2]
      assert_equal 10.0005, sheet1[10,3]
      assert_equal 1.00005, sheet1[10,4]
      assert_equal 40, sheet1.row(11).height
      assert_instance_of Spreadsheet::Excel::Worksheet, sheet
      sheet = book.worksheets.last
      name = "m\000y\000 \000n\000a\000m\000e\000".dup
      name.force_encoding 'UTF-16LE' if name.respond_to?(:force_encoding)
      assert_equal name, sheet.name
      assert_not_nil sheet.offset
    end
    def test_write_new_workbook__utf16
      Spreadsheet.client_encoding = 'UTF-16LE'
      book = Spreadsheet::Workbook.new
      path = File.join @var, 'test_write_workbook.xls'
      sheet1 = book.create_worksheet
      str1 = @@iconv.iconv 'Shared String'
      str2 = @@iconv.iconv 'Another Shared String'
      str3 = @@iconv.iconv('1234567890 ' * 1000)
      str4 = @@iconv.iconv('9876543210 ' * 1000)
      fmt = Format.new :italic => true, :color => :blue
      sheet1.format_column 1, fmt, :width => 20
      sheet1[0,0] = str1
      sheet1.row(0).push str1
      sheet1.row(1).concat [str2, str2]
      sheet1[2,0] = str3
      sheet1[3,0] = str4
      fmt = Format.new :color => 'red'
      sheet1[4,0] = 0.25
      sheet1.row(4).set_format 0, fmt
      fmt = Format.new :color => 'aqua'
      sheet1[5,0] = 0.75
      sheet1.row(5).set_format 0, fmt
      sheet1[6,0] = 1
      fmt = Format.new :color => 'green'
      sheet1.row(6).set_format 0, fmt
      sheet1[6,1] = Date.new 2008, 10, 10
      sheet1[6,2] = Date.new 2008, 10, 12
      fmt = Format.new :number_format => @@iconv.iconv("DD.MM.YYYY")
      sheet1.row(6).set_format 1, fmt
      sheet1.update_row 7, nil, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0
      sheet1.row(8).default_format = fmt
      sheet1[8,0] = @@iconv.iconv 'formatted when empty'
      book.create_worksheet :name => @@iconv.iconv("my name") #=> sheet2
      book.write path
      Spreadsheet.client_encoding = 'UTF-8'
      str1 = 'Shared String'
      str2 = 'Another Shared String'
      str3 = '1234567890 ' * 1000
      str4 = '9876543210 ' * 1000
      assert_nothing_raised do book = Spreadsheet.open path end
      if RUBY_VERSION >= '1.9'
        assert_equal 'UTF-16LE', book.encoding.name
      else
        assert_equal 'UTF-16LE', book.encoding
      end
      assert_valid_sst(book, :is => [str1, str2, str3, str4, "formatted when empty"])
      assert_equal 2, book.worksheets.size
      sheet = book.worksheets.first
      assert_instance_of Spreadsheet::Excel::Worksheet, sheet
      assert_equal "Worksheet1", sheet.name
      assert_not_nil sheet.offset
      assert_not_nil col = sheet.column(1)
      assert_equal true, col.default_format.font.italic?
      assert_equal :blue, col.default_format.font.color
      row = sheet.row 0
      assert_equal col.default_format, row.format(1)
      assert_equal str1, row[0]
      assert_equal str1, sheet[0,0]
      assert_equal str1, sheet.cell(0,0)
      assert_equal str1, row[1]
      assert_equal str1, sheet[0,1]
      assert_equal str1, sheet.cell(0,1)
      row = sheet.row 1
      assert_equal str2, row[0]
      assert_equal str2, sheet[1,0]
      assert_equal str2, sheet.cell(1,0)
      assert_equal str2, row[1]
      assert_equal str2, sheet[1,1]
      assert_equal str2, sheet.cell(1,1)
      row = sheet.row 2
      assert_equal str3, row[0]
      assert_equal str3, sheet[2,0]
      assert_equal str3, sheet.cell(2,0)
      assert_nil row[1]
      assert_nil sheet[2,1]
      assert_nil sheet.cell(2,1)
      row = sheet.row 3
      assert_equal str4, row[0]
      assert_equal str4, sheet[3,0]
      assert_equal str4, sheet.cell(3,0)
      assert_nil row[1]
      assert_nil sheet[3,1]
      assert_nil sheet.cell(3,1)
      row = sheet.row 4
      assert_equal :red, row.format(0).font.color
      assert_equal 0.25, row[0]
      assert_equal 0.25, sheet[4,0]
      assert_equal 0.25, sheet.cell(4,0)
      row = sheet.row 5
      assert_equal :cyan, row.format(0).font.color
      assert_equal 0.75, row[0]
      assert_equal 0.75, sheet[5,0]
      assert_equal 0.75, sheet.cell(5,0)
      row = sheet.row 6
      assert_equal :green, row.format(0).font.color
      assert_equal 1, row[0]
      assert_equal 1, sheet[6,0]
      assert_equal 1, sheet.cell(6,0)
      assert_equal 'DD.MM.YYYY', row.format(1).number_format
      date = Date.new 2008, 10, 10
      assert_equal date, row[1]
      assert_equal date, sheet[6,1]
      assert_equal date, sheet.cell(6,1)
      assert_equal 'DD.MM.YYYY', row.format(2).number_format
      date = Date.new 2008, 10, 12
      assert_equal date, row[2]
      assert_equal date, sheet[6,2]
      assert_equal date, sheet.cell(6,2)
      row = sheet.row 7
      assert_nil row[0]
      assert_equal [1,2,3,4,5,6,7,8,9,0], row[1,10]
      assert_equal [1,2,3,4,5,6,7,8,9,0], sheet[7,1..10]
      assert_equal [1,2,3,4,5,6,7,8,9,0], sheet.cell(7,1..10)
      row = sheet.row 8
      assert_equal 'formatted when empty', row[0]
      assert_not_nil row.default_format
      assert_instance_of Spreadsheet::Excel::Worksheet, sheet
      sheet = book.worksheets.last
      assert_equal "my name",
                   sheet.name
      assert_not_nil sheet.offset
    end
    def test_template
      template = File.join @data, 'test_copy.xls'
      output = File.join @var, 'test_template.xls'
      book = Spreadsheet.open template
      sheet1 = book.worksheet 0
      sheet1.row(4).replace [ 'Daniel J. Berger', 'U.S.A.',
        'Author of original code for Spreadsheet::Excel' ]
      book.write output
      assert_nothing_raised do
        book = Spreadsheet.open output
      end
      sheet = book.worksheet 0
      row = sheet.row(4)
      assert_equal 'Daniel J. Berger', row[0]
    end
    def test_bignum
      smallnum = 0x1fffffff
      bignum = smallnum + 1
      book = Spreadsheet::Workbook.new
      sheet = book.create_worksheet
      sheet[0,0] = bignum
      sheet[1,0] = -bignum
      sheet[0,1] = smallnum
      sheet[1,1] = -smallnum
      sheet[0,2] = bignum - 0.1
      sheet[1,2] = -bignum - 0.1
      sheet[0,3] = smallnum - 0.1
      sheet[1,3] = -smallnum - 0.1
      path = File.join @var, 'test_big-number.xls'
      book.write path
      assert_nothing_raised do
        book = Spreadsheet.open path
      end
      assert_equal bignum, book.worksheet(0)[0,0]
      assert_equal(-bignum, book.worksheet(0)[1,0])
      assert_equal smallnum, book.worksheet(0)[0,1]
      assert_equal(-smallnum, book.worksheet(0)[1,1])
      assert_equal bignum - 0.1, book.worksheet(0)[0,2]
      assert_equal(-bignum - 0.1, book.worksheet(0)[1,2])
      assert_equal smallnum - 0.1, book.worksheet(0)[0,3]
      assert_equal(-smallnum - 0.1, book.worksheet(0)[1,3])
    end
    def test_bigfloat
      # reported in http://rubyforge.org/tracker/index.php?func=detail&aid=24119&group_id=678&atid=2677
      bigfloat = 10000000.0
      book = Spreadsheet::Workbook.new
      sheet = book.create_worksheet
      sheet[0,0] = bigfloat
      sheet[0,1] = bigfloat + 0.1
      sheet[0,2] = bigfloat - 0.1
      sheet[1,0] = -bigfloat
      sheet[1,1] = -bigfloat + 0.1
      sheet[1,2] = -bigfloat - 0.1
      path = File.join @var, 'test_big-float.xls'
      book.write path
      assert_nothing_raised do
        book = Spreadsheet.open path
      end
      sheet = book.worksheet(0)
      assert_equal bigfloat, sheet[0,0]
      assert_equal bigfloat + 0.1, sheet[0,1]
      assert_equal bigfloat - 0.1, sheet[0,2]
      assert_equal(-bigfloat, sheet[1,0])
      assert_equal(-bigfloat + 0.1, sheet[1,1])
      assert_equal(-bigfloat - 0.1, sheet[1,2])
    end
    def test_datetime__off_by_one
      # reported in http://rubyforge.org/tracker/index.php?func=detail&aid=24414&group_id=678&atid=2677
      datetime1 = DateTime.new(2008)
      datetime2 = DateTime.new(2008, 1, 1, 1, 0, 1)
      date1 = Date.new(2008)
      date2 = Date.new(2009)
      book = Spreadsheet::Workbook.new
      sheet = book.create_worksheet
      sheet[0,0] = datetime1
      sheet[0,1] = datetime2
      sheet[1,0] = date1
      sheet[1,1] = date2
      path = File.join @var, 'test_datetime.xls'
      book.write path
      assert_nothing_raised do
        book = Spreadsheet.open path
      end
      sheet = book.worksheet(0)
      assert_equal datetime1, sheet[0,0]
      assert_equal datetime2, sheet[0,1]
      assert_equal date1, sheet[1,0]
      assert_equal date2, sheet[1,1]
      assert_equal date1, sheet.row(0).date(0)
      assert_equal datetime1, sheet.row(1).datetime(0)
    end

    def test_rational
      r1 = Rational(0x1fffffff + 1)
      r2 = Rational(0xfffffffc + 1)
      r3 = Rational(20, 3)
      r4 = Rational(1238237, 378122)
      r5 = Rational(200)
      r6 = Rational(1012, 100)

      book = Spreadsheet::Workbook.new
      sheet = book.create_worksheet
      sheet.insert_row 0, [r1, r2, r3]
      sheet.insert_row 1, [r4, r5, r6]

      path = File.join @var, 'test_rational.xls'
      book.write path

      assert_nothing_raised do
        book = Spreadsheet.open path
      end

      sheet = book.worksheet(0)
      assert_equal r1, sheet[0, 0]
      assert_equal r2, sheet[0, 1]
      assert_equal r3, sheet[0, 2]
      assert_equal r4, sheet[1, 0]
      assert_equal r5, sheet[1, 1]
      assert_equal r6, sheet[1, 2]
    end

    def test_sharedfmla
      path = File.join @data, 'test_formula.xls'
      book = Spreadsheet.open path
      assert_instance_of Excel::Workbook, book
      sheet = book.worksheet 0
      64.times do |idx|
        assert_equal '5026', sheet[idx.next, 2].value
      end
    end
    def test_missing_row_op
      path = File.join @data, 'test_missing_row.xls'
      book = Spreadsheet.open path
      assert_instance_of Excel::Workbook, book
      sheet = book.worksheet 0
      assert_not_nil sheet[1,0]
      assert_not_nil sheet[2,1]
    end
    def test_changes
      path = File.join @data, 'test_changes.xls'
      book = Spreadsheet.open path
      assert_instance_of Excel::Workbook, book
      sheet = book.worksheet 1
      sheet[20,0] = 'Ciao Mundo!'
      target = File.join @var, 'test_changes.xls'
      assert_nothing_raised do book.write target end
    end
    def test_long_sst_record
      path = File.join @data, 'test_long_sst_record.xls'
      book = Spreadsheet.open path
      sheet = book.worksheet(0)
      expected_result = 'A1,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,187,188,189,190,191,192,193,194,195,196,197,198,199,200,201,202,203,204,205,206,207,208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,223,224,225,226,227,228,229,230,231,232,233,234,235,236,237,238,239,240,241,242,243,244,245,246,247,248,249,250,251,252,253,254,255,256,257,258,259,260,261,262,263,264,265,266,267,268,269,270,271,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,287,288,289,290,291,292,293,294,295,296,297,298,299,300,301,302,303,304,305,306,307,308,309,310,311,312,313,314,315,316,317,318,319,320,321,322,323,324,325,326,327,328,329,330,331,332,333,334,335,336,337,338,339,340,341,342,343,344,345,346,347,348,349,350,351,352,353,354,355,356,357,358,359,360,361,362,363,364,365,366,367,368,369,370,371,372,373,374,375,376,377,378,379,380,381,382,383,384,385,386,387,388,389,390,391,392,393,394,395,396,397,398,399,400,401,402,403,404,405,406,407,408,409,410,411,412,413,414,415,416,417,418,419,420,421,422,423,424,425,426,427,428,429,430,431,432,433,434,435,436,437,438,439,440,441,442,443,444,445,446,447,448,449,450,451,452,453,454,455,456,457,458,459,460,461,462,463,464,465,466,467,468,469,470,471,472,473,474,475,476,477,478,479,480,481,482,483,484,485,486,487,488,489,490,491,492,493,494,495,496,497,498,499,500,501,502,503,504,505,506,507,508,509,510,511,512,513,514,515,516,517,518,519,520,521,522,523,524,525,526,527,528,529,530,531,532,533,534,535,536,537,538,539,540,541,542,543,544,545,546,547,548,549,550,551,552,553,554,555,556,557,558,559,560,561,562,563,564,565,566,567,568,569,570,571,572,573,574,575,576,577,578,579,580,581,582,583,584,585,586,587,588,589,590,591,592,593,594,595,596,597,598,599,600,601,602,603,604,605,606,607,608,609,610,611,612,613,614,615,616,617,618,619,620,621,622,623,624,625,626,627,628,629,630,631,632,633,634,635,636,637,638,639,640,641,642,643,644,645,646,647,648,649,650,651,652,653,654,655,656,657,658,659,660,661,662,663,664,665,666,667,668,669,670,671,672,673,674,675,676,677,678,679,680,681,682,683,684,685,686,687,688,689,690,691,692,693,694,695,696,697,698,699,700,701,702,703,704,705,706,707,708,709,710,711,712,713,714,715,716,717,718,719,720,721,722,723,724,725,726,727,728,729,730,731,732,733,734,735,736,737,738,739,740,741,742,743,744,745,746,747,748,749,750,751,752,753,754,755,756,757,758,759,760,761,762,763,764,765,766,767,768,769,770,771,772,773,774,775,776,777,778,779,780,781,782,783,784,785,786,787,788,789,790,791,792,793,794,795,796,797,798,799,800,801,802,803,804,805,806,807,808,809,810,811,812,813,814,815,816,817,818,819,820,821,822,823,824,825,826,827,828,829,830,831,832,833,834,835,836,837,838,839,840,841,842,843,844,845,846,847,848,849,850,851,852,853,854,855,856,857,858,859,860,861,862,863,864,865,866,867,868,869,870,871,872,873,874,875,876,877,878,879,880,881,882,883,884,885,886,887,888,889,890,891,892,893,894,895,896,897,898,899,900,901,902,903,904,905,906,907,908,909,910,911,912,913,914,915,916,917,918,919,920,921,922,923,924,925,926,927,928,929,930,931,932,933,934,935,936,937,938,939,940,941,942,943,944,945,946,947,948,949,950,951,952,953,954,955,956,957,958,959,960,961,962,963,964,965,966,967,968,969,970,971,972,973,974,975,976,977,978,979,980,981,982,983,984,985,986,987,988,989,990,991,992,993,994,995,996,997,998'
      assert_equal(expected_result, sheet[0,0])
    end
    def test_special_chars
      book = Spreadsheet::Workbook.new
      sheet = book.create_worksheet
      (0..200).each { |i| sheet.row(i).push "ëçáéíóú" }
      assert_nothing_raised do
        book.write StringIO.new("".dup, "w+")
      end
    end

    def test_read_protected_sheet
      path = File.join @data, "test_merged_and_protected.xls"
      book = Spreadsheet.open path
      sheet = book.worksheet(0)
      sheet.ensure_rows_read # FIXME HACK
      assert sheet.protected?, "Expected sheet to be protected"
      assert_equal Spreadsheet::Excel::Password.password_hash('testing'), sheet.password_hash
    end

    def test_write_protected_sheet
      path = File.join @var, 'test_protected.xls'
      book = Spreadsheet::Workbook.new
      sheet = book.create_worksheet
      sheet.protect! 'secret'
      assert_nothing_raised do
        book.write path
      end

      read_back = Spreadsheet.open path
      sheet = read_back.worksheet(0)
      sheet.ensure_rows_read # FIXME HACK
      assert sheet.protected?, "Expected sheet to be proteced"
      assert_equal Spreadsheet::Excel::Password.password_hash('secret'), sheet.password_hash
    end

=begin
    def test_read_baltic
      path = File.join @data, 'test_baltic.xls'
      assert_nothing_raised do
        Spreadsheet.open path
      end
    end
=end
    def test_write_frozen_string
      Spreadsheet.client_encoding = 'UTF-16LE'
      book = Spreadsheet::Workbook.new
      path = File.join @var, 'test_write_workbook.xls'
      sheet1 = book.create_worksheet
      str1 = "Frozen String.".freeze
      sheet1[0,0] = str1
      sheet1.row(0).push str1
      assert_nothing_raised do
        book.write path
      end
    end
    def test_read_merged_cells
      path = File.join(@data, 'test_merged_cells.xls')
      book = Spreadsheet.open(path)
      assert_equal 8, book.biff_version
      sheet = book.worksheet(0)
      sheet[0,0] # trigger read_worksheet
      assert_equal [[2, 4, 1, 1], [3, 3, 2, 3]], sheet.merged_cells
    end
    def test_read_borders
      path = File.join @data, 'test_borders.xls'
      book = Spreadsheet.open path
      assert_instance_of Excel::Workbook, book
      sheet = book.worksheet 0
      format  = sheet.row(0).format 0
      assert_equal :none, format.left
      assert_equal :thin, format.top
      assert_equal :medium, format.right
      assert_equal :thick, format.bottom
      assert_equal :builtin_black, format.left_color
      assert_equal :red, format.top_color
      assert_equal :green, format.right_color
      assert_equal :yellow, format.bottom_color
    end
    def test_write_borders
      book = Spreadsheet::Workbook.new
      path = File.join @var, 'test_write_borders.xls'
      sheet1 = book.create_worksheet
      (sheet1.row(0).format 0).border = :hair
      (sheet1.row(0).format 0).border_color = :brown
      assert_nothing_raised do
        book.write path
      end
      book2 = Spreadsheet.open path
      assert_instance_of Excel::Workbook, book2
      sheet2 = book2.worksheet 0
      format = sheet2.row(0).format 0
      assert_equal :hair, format.left
      assert_equal :brown, format.top_color
    end

    def test_adding_data_to_existing_file
      path = File.join @data, 'test_adding_data_to_existing_file.xls'
      book = Spreadsheet.open path
      assert_equal(1, book.worksheet(0).rows.count)

      book.worksheet(0).insert_row(1, [12, 23, 34, 45])
      temp_file = Tempfile.new('temp')
      book.write(temp_file.path)

      temp_book = Spreadsheet.open temp_file.path
      assert_equal(2, temp_book.worksheet(0).rows.count)

      temp_file.unlink
    end

    def test_comment
      path = File.join @data, 'test_comment.xls'
      book = Spreadsheet.open path
      assert_instance_of Excel::Workbook, book
      sheet = book.worksheet 0
      sheet.ensure_rows_read
      #Now two commented fields in sheet
      assert_equal(true, book.worksheet(0).notes.has_key?([0,18]))
      assert_equal(true, book.worksheet(0).notes.has_key?([0,2]))
      assert_equal(false, book.worksheet(0).notes.has_key?([0,3]))
      assert_equal("Another Author:\n0: switch it off\n1: switch it on",
                   book.worksheet(0).notes[[0,18]])
      assert_equal("Some author:\nI have a register name",
                   book.worksheet(0).notes[[0,2]])
    end
    def test_read_pagesetup
      path = File.join @data, 'test_pagesetup.xls'
      book = Spreadsheet.open path
      assert_instance_of Excel::Workbook, book
      sheet = book.worksheet(0)
      assert_equal(:landscape, sheet.pagesetup[:orientation])
      assert_equal(130, sheet.pagesetup[:adjust_to])
    end

    def test_write_pagesetup
      book = Spreadsheet::Workbook.new
      path = File.join @var, 'test_write_pagesetup.xls'
      sheet1 = book.create_worksheet
      sheet1.pagesetup[:orientation] = :landscape
      sheet1.pagesetup[:adjust_to] = 93
      assert_nothing_raised do
        book.write path
      end
      book2 = Spreadsheet.open path
      assert_instance_of Excel::Workbook, book2
      sheet2 = book2.worksheet(0)
      assert_equal(:landscape, sheet2.pagesetup[:orientation])
      assert_equal(93, sheet2.pagesetup[:adjust_to])
    end

    def test_read_margins
      path = File.join @data, 'test_margin.xls'
      book = Spreadsheet.open path
      assert_instance_of Excel::Workbook, book
      sheet = book.worksheet(0)
      assert_equal(2.0, sheet.margins[:left])
    end

    def test_write_margins
      book = Spreadsheet::Workbook.new
      path = File.join @var, 'test_write_margins.xls'
      sheet1 = book.create_worksheet
      sheet1.margins[:left] = 3
      assert_nothing_raised do
        book.write path
      end
      book2 = Spreadsheet.open path
      assert_instance_of Excel::Workbook, book2
      sheet2 = book2.worksheet(0)
      assert_equal(3.0, sheet2.margins[:left])
    end

    def test_read_worksheet_visibility
      path = File.join @data, 'test_worksheet_visibility.xls'
      book = Spreadsheet.open path
      assert_instance_of Excel::Workbook, book
      assert_equal(:visible, book.worksheet(0).visibility)
      assert_equal(:hidden, book.worksheet(1).visibility)
    end

    def test_write_worksheet_visibility
      book = Spreadsheet::Workbook.new
      path = File.join @var, 'test_write_worksheet_visibility.xls'
      sheet1 = book.create_worksheet
      sheet1.visibility = :hidden
      _sheet2 = book.create_worksheet
      assert_nothing_raised do
        book.write path
      end
      book2 = Spreadsheet.open path
      assert_instance_of Excel::Workbook, book2
      assert_equal(:hidden, book2.worksheet(0).visibility)
      assert_equal(:visible, book2.worksheet(1).visibility)
    end

    def test_text_drawing
      path = File.join @data, 'test_text_drawing.xls'
      book = Spreadsheet.open path
      assert_nothing_raised do
        book.worksheet(0).row(0)
      end
    end

    def test_compact
      path = File.join @data, 'test_compact_many_rows.xls'
      book = Spreadsheet.open path
      sheets = book.worksheets
      assert_equal 1, sheets.size
      sheet = book.worksheet 0
      assert_instance_of Excel::Worksheet, sheet
      assert_equal sheet, book.worksheet('Planilha1')
      assert_equal sheet.dimensions, [0, 65534, 0, 25]
      sheet.compact!
      assert_equal sheet.dimensions, [0, 502, 0, 1]
      path = File.join @data, 'test_sizes.xls'
      book = Spreadsheet.open path
      sheet = book.worksheet 0
      assert_instance_of Excel::Worksheet, sheet
      assert_equal sheet.dimensions, [1, 38, 1, 15]
      sheet.compact!
      assert_equal sheet.dimensions, [1, 3, 1, 3]
      sheet = book.worksheet 1
      assert_instance_of Excel::Worksheet, sheet
      assert_equal sheet.dimensions, [1, 3, 1, 3]
      sheet.compact!
      assert_equal sheet.dimensions, [1, 3, 1, 3]
      sheet = book.worksheet 2
      assert_instance_of Excel::Worksheet, sheet
      assert_equal sheet.dimensions, [0, 4, 0, 4]
      sheet.compact!
      assert_equal sheet.dimensions, [0, 2, 0, 2]
      path = File.join @data, 'test_compact_format_date.xls'
      book = Spreadsheet.open path
      sheet = book.worksheet 0
      assert_instance_of Excel::Worksheet, sheet
      assert_nothing_raised do
        sheet.compact!
      end
    end

    private

    # Validates the workbook's SST
    # Valid options:
    #   :is       => [array]
    #   :contains => [array]
    #   :length   => num
    def assert_valid_sst(workbook, opts = {})
      assert workbook.is_a?(Spreadsheet::Excel::Workbook)
      sst = workbook.sst
      assert sst.is_a?(Array)
      strings = sst.map do |entry|
        assert entry.is_a?(Spreadsheet::Excel::SstEntry)
        entry.content
      end
      sorted_strings = strings.sort
      # Make sure there are no duplicates, the whole point of the SST:
      assert_equal strings.uniq.sort, sorted_strings
      if opts[:is]
        assert_equal opts[:is].sort, sorted_strings
      end
      if opts[:contains]
        assert_equal [], opts[:contains] - sorted_strings
      end
      if opts[:length]
        assert_equal opts[:length], sorted_strings
      end
    end

  end
end
