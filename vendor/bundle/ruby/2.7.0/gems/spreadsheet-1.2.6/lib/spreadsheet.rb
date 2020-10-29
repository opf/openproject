
### Spreadsheet - A Library for reading and writing Spreadsheet Documents.
#
#   Copyright (C) 2008-2010 ywesee GmbH
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#   Contact Information:
#
#     E-Mail: zdavatz@ywesee.com
#     P-Mail: ywesee GmbH
#             Zeno R.R. Davatz
#             Winterthurerstrasse 52
#             8006 Zürich
###           Switzerland

require 'spreadsheet/version'
require 'spreadsheet/errors'

require 'spreadsheet/excel/workbook'
require 'spreadsheet/excel/reader'
require 'spreadsheet/excel/rgb'

# = Synopsis
# The Spreadsheet Library is designed to read and write Spreadsheet Documents.
# As of version 0.6.0, only Microsoft Excel compatible spreadsheets are
# supported.
#
# == Example
#  require 'spreadsheet'
#
#  book = Spreadsheet.open '/path/to/an/excel-file.xls'
#  sheet = book.worksheet 0
#  sheet.each do |row| puts row[0] end
module Spreadsheet

  ##
  # Default client Encoding. Change this value if your application uses a
  # different Encoding:
  # Spreadsheet.client_encoding = 'ISO-LATIN-1//TRANSLIT//IGNORE'
  @client_encoding = 'UTF-8'
  @enc_translit = 'TRANSLIT'
  @enc_ignore = 'IGNORE'

  class << self

    attr_accessor :client_encoding, :enc_translit, :enc_ignore

    ##
    # Parses a Spreadsheet Document and returns a Workbook object. At present,
    # only Excel-Documents can be read.
    def open io_or_path, mode="rb+"
      if io_or_path.respond_to? :seek
        Excel::Workbook.open(io_or_path)
      elsif block_given?
        File.open(io_or_path, mode) do |fh|
          yield open(fh)
        end
      else
        open File.open(io_or_path, mode)
      end
    end

    ##
    # Returns a Writer object for the specified path. At present, only the
    # Excel-Writer is available.
    def writer io_or_path, type=Excel
      Excel::Writer::Workbook.new io_or_path
    end
  end
end
