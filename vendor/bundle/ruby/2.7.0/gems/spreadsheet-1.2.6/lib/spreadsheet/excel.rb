require 'spreadsheet'

warn <<-EOS
[DEPRECATED] By requiring 'spreadsheet/excel' you are loading a Compatibility
             layer which provides a drop-in replacement for Spreadsheet::Excel
             versions <= 0.3.5.1. This code will be removed in Spreadsheet
             version 1.0.0
EOS
##
# Spreadsheet::Excel Compatibility Layer.
# Drop-in replacement for Spreadsheet::Excel version <= 0.3.5.1
module Spreadsheet
  module Excel
    class ExcelCompatibleWorkbook < Workbook
      def initialize file_path, *args
        super *args
        @file_path = file_path
      end
      def close
        write @file_path
      end
    end
    def Excel.new file_path
      ExcelCompatibleWorkbook.new file_path
    end
    class Workbook
      def add_worksheet name
        if name.is_a? String
          create_worksheet :name => name
        else
          super
        end
      end
    end
  end
  class Worksheet
    unless instance_methods.include? "new_format_column"
      alias :new_format_column :format_column
      def format_column column, width=nil, format=nil
        if width.is_a? Format
          new_format_column column, width, format
        else
          new_format_column column, format, :width => width
        end
      end
    end
    def write row, col, data=nil, format=nil
      if data.is_a? Array
        write_row row, col, data, format
      else
        row = row(row)
        row[col] = data
        row.set_format col, format
      end
    end
    def write_column row, col, data=nil, format=nil
      if data.is_a? Array
        data.each do |token|
          if token.is_a? Array
            write_row row, col, token, format
          else
            write row, col, token, format
          end
          row += 1
        end
      else
        write row, col, data, format
      end
    end
    def write_row row, col, data=nil, format=nil
      if data.is_a? Array
        data.each do |token|
          if token.is_a? Array
            write_column row, col, token, format
          else
            write row, col, token, format
          end
          col += 1
        end
      else
        write row, col, data, format
      end
    end
    def write_url row, col, url, string=url, format=nil
      row(row)[col] = Link.new url, string
    end
  end
end
