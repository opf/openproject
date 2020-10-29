require 'spreadsheet'

warn <<-EOS
[DEPRECATED] By requiring 'parseexcel', 'parseexcel/parseexcel' and/or
             'parseexcel/parser' you are loading a Compatibility layer which
             provides a drop-in replacement for the ParseExcel library. This
             code makes the reading of Spreadsheet documents less efficient and
             will be removed in Spreadsheet version 1.0.0
EOS

module Spreadsheet
  ##
  # The ParseExcel module is provided as a drop-in replacement for the
  # ParseExcel library. This code is deprecated and will be removed in
  # Spreadsheet version 1.0.0
  module ParseExcel
def ParseExcel.parse path
  Spreadsheet.open path
end
class Worksheet
  class Cell
    attr_accessor :value, :kind, :numeric, :code, :book,
      :format, :rich, :encoding, :annotation
    def initialize value, format, row, idx
      @format = format
      @idx = idx
      @row = row
      @value = value
      @encoding = Spreadsheet.client_encoding
    end
    def date
      @row.date @idx
    end
    def datetime
      @row.datetime @idx
    end
    def to_i
      @value.to_i
    end
    def to_f
      @value.to_f
    end
    def to_s(target_encoding=nil)
      if(target_encoding)
        begin
          Iconv.new(target_encoding, @encoding).iconv(@value)
        rescue
          Iconv.new(target_encoding, 'ascii').iconv(@value.to_s)
        end
      else
        @value.to_s
      end
    end
    def type
      if @format && (@format.date? || @format.time?)
        :date
      elsif @value.is_a?(Numeric)
        :numeric
      else
        :text
      end
    end
  end
end
  end
  module Excel
class Reader # :nodoc: all
  def set_cell worksheet, row, column, xf, value=nil
    cells = @current_row_block[row] ||= Row.new(nil, row)
    cells.formats[column] = xf = @workbook.format(xf)
    cells[column] = ParseExcel::Worksheet::Cell.new(value, xf, cells, column)
  end
end
  end
end
