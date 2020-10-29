require 'spreadsheet/workbook'
require 'spreadsheet/excel/offset'
require 'spreadsheet/excel/writer'
require 'ole/storage'

module Spreadsheet
  module Excel
##
# Excel-specific Workbook methods. These are mostly pertinent to the Excel
# reader. You should have no reason to use any of these.
class Workbook < Spreadsheet::Workbook
  include Spreadsheet::Encodings
  include Spreadsheet::Excel::Offset
  BIFF_VERSIONS = {
    0x000 => 2,
    0x007 => 2,
    0x200 => 2,
    0x300 => 3,
    0x400 => 4,
    0x500 => 5,
    0x600 => 8,
  }
  VERSION_STRINGS = {
    0x600 => 'Microsoft Excel 97/2000/XP',
    0x500 => 'Microsoft Excel 95',
  }
  offset :encoding, :boundsheets, :sst
  attr_accessor :bof, :ole
  attr_writer :date_base
  def Workbook.open io, opts = {}
    Reader.new(opts).read(io)    
  end
  def initialize *args
    super
    enc = 'UTF-16LE'
    if RUBY_VERSION >= '1.9'
      enc = Encoding.find enc
    end
    @encoding = enc
    @version = 0x600
    @sst = []
  end
  def add_shared_string str
    @sst.push str
  end
  def add_worksheet worksheet
    @changes.store :boundsheets, true
    super
  end
  def biff_version
    case @bof
    when 0x009
      2
    when 0x209
      3
    when 0x409
      4
    else
      BIFF_VERSIONS.fetch(@version) { raise "Unkown BIFF_VERSION '#@version'" }
    end
  end
  def date_base
    @date_base ||= DateTime.new 1899, 12, 31
  end
  def inspect
    self.worksheets
  end
  def shared_string idx
    @sst[idx.to_i].content
  end
  def sst_size
    @sst.size
  end
  def uninspect_variables
    super.push '@sst', '@offsets', '@changes'
  end
  def version_string
    client VERSION_STRINGS.fetch(@version, "Unknown"), 'UTF-8'
  end
end
  end
end
