require 'spreadsheet/excel/offset'
require 'spreadsheet/excel/row'
require 'spreadsheet/worksheet'

module Spreadsheet
  module Excel
##
# Excel-specific Worksheet methods. These are mostly pertinent to the Excel
# reader, and to recording changes to the Worksheet. You should have no reason
# to use any of these.
class Worksheet < Spreadsheet::Worksheet
  include Spreadsheet::Excel::Offset
  offset :dimensions
  attr_reader :offset, :ole, :links, :guts, :notes
  def initialize opts = {}
    @row_addresses = nil
    super
    @offset, @ole, @reader = opts[:offset], opts[:ole], opts[:reader]
    @dimensions = nil
    @links = {}
    @guts = {}
    @notes = {}
  end
  def add_link row, column, link
    @links.store [row, column], link
  end
  def add_note row, column, note
    @notes.store [row, column], note
  end
  def column idx
    ensure_rows_read
    super
  end
  def date_base
    @workbook.date_base
  end
  def margins
    ensure_rows_read
    super
  end
  def pagesetup
    ensure_rows_read
    super
  end
  def each *args
    ensure_rows_read
    super
  end
  def ensure_rows_read
    return if @row_addresses
    @dimensions = nil
    @row_addresses = []
    @reader.read_worksheet self, @offset if @reader
  end
  def row idx
    @rows[idx] or begin
      ensure_rows_read
      if addr = @row_addresses[idx]
        row = @reader.read_row self, addr
        [:default_format, :height, :outline_level, :hidden, ].each do |key|
          row.send "unupdated_#{key}=", addr[key]
        end
        row.worksheet = self
        row
      else
        Row.new self, idx
      end
    end
  end
  def rows
    self.to_a
  end
  def row_updated idx, row
    res = super
    @workbook.changes.store self, true
    @workbook.changes.store :boundsheets, true
    @changes.store idx, true
    @changes.store :dimensions, true
    res
  end
  def set_row_address idx, opts
    @offsets.store idx, opts[:row_block]
    @row_addresses[idx] = opts
  end
  def shared_string idx
    @workbook.shared_string idx
  end
  private
  ## premature optimization?
  def have_set_dimensions value, pos, len
    if @row_addresses.size < row_count
      @row_addresses.concat Array.new(row_count - @row_addresses.size)
    end
  end
  def recalculate_dimensions
    ensure_rows_read
    shorten @rows
    @dimensions = []
    @dimensions[0] = [ index_of_first(@rows),
                       index_of_first(@row_addresses) ].compact.min || 0
    @dimensions[1] = [ @rows.size, @row_addresses.size ].compact.max || 0
    compact = @rows.compact
    first_rows = compact.collect do |row| row.first_used end.compact.min
    first_addrs = @row_addresses.compact.collect do |addr|
      addr[:first_used] end.compact.min
    @dimensions[2] = [ first_rows, first_addrs ].compact.min || 0
    last_rows = compact.collect do |row| row.first_unused end.max
    last_addrs = @row_addresses.compact.collect do |addr|
      addr[:first_unused] end.compact.max
    @dimensions[3] = [last_rows, last_addrs].compact.max || 0
    @dimensions
  end
end
  end
end
