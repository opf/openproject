require 'date'
require 'spreadsheet/column'
require 'spreadsheet/encodings'
require 'spreadsheet/row'
require 'spreadsheet/excel/password_hash'

module Spreadsheet
  ##
  # The Worksheet class. Contains most of the Spreadsheet data in Rows.
  #
  # Interesting Attributes
  # #name          :: The Name of this Worksheet.
  # #default_format:: The default format used for all cells in this Workhseet
  #                   that have no format set explicitly or in
  #                   Row#default_format.
  # #rows          :: The Rows in this Worksheet. It is not recommended to
  #                   Manipulate this Array directly. If you do, call
  #                   #updated_from with the smallest modified index.
  # #columns       :: The Column formatting in this Worksheet. Column
  #                   instances may appear at more than one position in #columns.
  #                   If you modify a Column directly, your changes will be
  #                   reflected in all those positions.
  # #selected      :: When a user chooses to print a Workbook, Excel will include
  #                   all selected Worksheets. If no Worksheet is selected at
  #                   Workbook#write, then the first Worksheet is selected by
  #                   default.
  class Worksheet
    include Spreadsheet::Encodings
    include Spreadsheet::Datatypes
    include Enumerable
    attr_accessor :name, :selected, :workbook, :password_hash
    attr_reader :rows, :columns, :merged_cells, :margins, :pagesetup
    attr_reader :froze_top, :froze_left
    enum :visibility, :visible, :hidden, :strong_hidden
    def initialize opts={}
      @froze_top = 0
      @froze_left = 0
      @default_format = nil
      @selected = opts[:selected]
      @dimensions = [0,0,0,0]
      @pagesetup = {
        :orig_data => [9, 100, 1, 1, 1, 0, 300, 300, 0.5, 0.5, 1],
        :orientation => :portrait,
        :adjust_to => 100
      }
      @margins = {
        :top => 1,
        :left => 0.75,
        :right => 0.75,
        :bottom => 1
      }
      @name = opts[:name] || 'Worksheet'
      @workbook = opts[:workbook]
      @rows = []
      @columns = []
      @links = {}
      @merged_cells = []
      @protected = false
      @password_hash = 0
      @visibility = opts[:visibility]
    end
    def has_frozen_panel?
      @froze_top > 0 or @froze_left > 0
    end

    def freeze!(top, left)
      @froze_top = top.to_i
      @froze_left = left.to_i
    end
    def active # :nodoc:
      warn "Worksheet#active is deprecated. Please use Worksheet#selected instead."
      selected
    end
    def active= selected # :nodoc:
      warn "Worksheet#active= is deprecated. Please use Worksheet#selected= instead."
      self.selected = selected
    end
    ##
    # Add a Format to the Workbook. If you use Row#set_format, you should not
    # need to use this Method.
    def add_format fmt
      @workbook.add_format fmt if fmt
    end
    ##
    # Get the enriched value of the Cell at _row_, _column_.
    # See also Worksheet#[], Row#[].
    def cell row, column
      row(row)[column]
    end
    ##
    # Returns the Column at _idx_.
    def column idx
      @columns[idx] || Column.new(idx, default_format, :worksheet => self)
    end
    ##
    # The number of columns in this Worksheet which contain data.
    def column_count
      dimensions[3] - dimensions[2]
    end
    def column_updated idx, column
      @columns[idx] = column
    end
    ##
    # Delete the Row at _idx_ (0-based) from this Worksheet.
    def delete_row idx
      res = @rows.delete_at idx
      updated_from idx
      res
    end
    ##
    # The default Format of this Worksheet, if you have set one.
    # Returns the Workbook's default Format otherwise.
    def default_format
      @default_format || @workbook.default_format
    end
    ##
    # Set the default Format of this Worksheet.
    def default_format= format
      @default_format = format
      add_format format
      format
    end
    ##
    # Is the worksheet protected?
    def protected?
      @protected
    end
    ##
    # Set worklist protection
    def protect! password = ''
      @protected = true
      password = password.to_s
      if password.size == 0
        @password_hash = 0
      else
        @password_hash = Excel::Password.password_hash password
      end
    end

    ##
    # Dimensions:: [ first used row, first unused row,
    #              first used column, first unused column ]
    #              ( First used means that all rows or columns before that are
    #              empty. First unused means that this and all following rows
    #              or columns are empty. )
    def dimensions
      @dimensions || recalculate_dimensions
    end
    ##
    # If no argument is given, #each iterates over all used Rows (from the first
    # used Row until but omitting the first unused Row, see also #dimensions).
    #
    # If the argument skip is given, #each iterates from that row until but
    # omitting the first unused Row, effectively skipping the first _skip_ Rows
    # from the top of the Worksheet.
    def each(skip=dimensions[0], &block)
      rows = skip.upto(dimensions[1] - 1).map { |index| row(index) }.to_enum

      if block_given?
        rows.each(&block)
      else
        rows
      end
    end
    def encoding # :nodoc:
      @workbook.encoding
    end
    ##
    # Sets the default Format of the column at _idx_.
    #
    # _idx_ may be an Integer, or an Enumerable that iterates over a number of
    # Integers.
    #
    # _format_ is a Format, or nil if you want to remove the Formatting at _idx_
    #
    # Returns an instance of Column if _idx_ is an Integer, an Array of Columns
    # otherwise.
    def format_column idx, format=nil, opts={}
      opts[:worksheet] = self
      res = case idx
            when Integer
              column = nil
              if format
                column = Column.new(idx, format, opts)
              end
              @columns[idx] = column
            else
              idx.collect do |col| format_column col, format, opts end
            end
      shorten @columns
      res
    end
    ##
    # Formats all Date, DateTime and Time cells with _format_ or the default
    # formats:
    # - 'DD.MM.YYYY' for Date
    # - 'DD.MM.YYYY hh:mm:ss' for DateTime and Time
    def format_dates! format=nil
      new_formats = {}
      fmt_str_time = client('DD.MM.YYYY hh:mm:ss', 'UTF-8')
      fmt_str_date = client('DD.MM.YYYY', 'UTF-8')
      each do |row|
        row.each_with_index do |value, idx|
          unless row.formats[idx] || row.format(idx).date_or_time?
            numfmt = case value
                     when DateTime, Time
                       format || fmt_str_time
                     when Date
                       format || fmt_str_date
                     end
            case numfmt
            when Format
              row.set_format idx, numfmt
            when String
              existing_format = row.format(idx)
              new_formats[existing_format] ||= {}
              new_format = new_formats[existing_format][numfmt]
              if !new_format
                new_format = new_formats[existing_format][numfmt] = existing_format.dup
                new_format.number_format = numfmt
              end
              row.set_format idx, new_format
            end
          end
        end
      end
    end
    ##
    # Insert a Row at _idx_ (0-based) containing _cells_
    def insert_row idx, cells=[]
      res = @rows.insert idx, Row.new(self, idx, cells)
      updated_from idx
      res
    end
    def << cells=[]
      insert_row last_row_index + 1, cells
    end
    def inspect
      names = instance_variables
      names.delete '@rows'
      variables = names.collect do |name|
        "%s=%s" % [name, instance_variable_get(name)]
      end.join(' ')
      sprintf "#<%s:0x%014x %s @rows[%i]>", self.class, object_id,
                                            variables, row_count
    end
    ## The last Row containing any data
    def last_row
      row(last_row_index)
    end
    ## The index of the last Row containing any data
    def last_row_index
      [dimensions[1] - 1, 0].max
    end
    ##
    # Replace the Row at _idx_ with the following arguments. Like #update_row,
    # but truncates the Row if there are fewer arguments than Cells in the Row.
    def replace_row idx, *cells
      if(row = @rows[idx]) && cells.size < row.size
        cells.concat Array.new(row.size - cells.size)
      end
      update_row idx, *cells
    end
    ##
    # The Row at _idx_ or a new Row.
    def row idx
      @rows[idx] || Row.new(self, idx)
    end
    ##
    # The number of Rows in this Worksheet which contain data.
    def row_count
      dimensions[1] - dimensions[0]
    end
    ##
    # Tell Worksheet that the Row at _idx_ has been updated and the #dimensions
    # need to be recalculated. You should not need to call this directly.
    def row_updated idx, row
      @dimensions = nil
      @rows[idx] = row
    end
    ##
    # Updates the Row at _idx_ with the following arguments.
    def update_row idx, *cells
      res = if row = @rows[idx]
              row[0, cells.size] = cells
              row
            else
              Row.new self, idx, cells
            end
      row_updated idx, res
      res
    end
    ##
    # Renumbers all Rows starting at _idx_ and calls #row_updated for each of
    # them.
    def updated_from index
      index.upto(@rows.size - 1) do |idx|
        row = row(idx)
        row.idx = idx
        row_updated idx, row
      end
    end
    ##
    # Get the enriched value of the Cell at _row_, _column_.
    # See also Worksheet#cell, Row#[].
    def [] row, column
      row(row)[column]
    end
    ##
    # Set the value of the Cell at _row_, _column_ to _value_.
    # See also Row#[]=.
    def []= row, column, value
      row(row)[column] = value
    end
    ##
    # Merges multiple cells into one.
    def merge_cells start_row, start_col, end_row, end_col
      # FIXME enlarge or dup check
      @merged_cells.push [start_row, end_row, start_col, end_col]
    end

    def compact!
      recalculate_dimensions

      # detect first non-nil non-empty row if given first row is empty or nil
      if row(@dimensions[0]).empty? || row(@dimensions[0]).compact.join('').empty?
        (@dimensions[0]...@dimensions[1]).each do |i|
          break unless row(i).empty? || row(i).compact.join('').empty?
          @dimensions[0] = i
        end
      end

      # detect last non-nil non-empty row if given last row is empty or nil
      if row(@dimensions[1] - 1).empty? || row(@dimensions[1] - 1).compact.join('').empty?
        row_size = @dimensions[1] - 1
        @dimensions[1] = @dimensions[0]
        # divide and conquer
        while(row_size - @dimensions[1] > 1) do
          if row(row_size).empty? || row(row_size).compact.join('').empty?
            row_size = @dimensions[1] + (((row_size - @dimensions[1]) + 1) / 2).to_i
          else
            _i = ((row_size - @dimensions[1]) / 2).to_i + 1
            @dimensions[1] = row_size
            row_size = row_size + _i
          end
        end
        @dimensions[1] = row_size + 1
      end

      # detect first non-empty non-nil column if first column is empty or nil
      if (@dimensions[0]..@dimensions[1]).inject(true){|t, j| t && row(j)[@dimensions[2]].nil?}
        (@dimensions[2]..@dimensions[3]).each do |i|
          break unless (@dimensions[0]..@dimensions[1]).inject(true){|t, j| t && row(j)[i].to_s.empty?}
          @dimensions[2] = i
        end
      end

      # detect last non-empty non-nil column if last column is empty or nil
      if (@dimensions[0]..@dimensions[1]).inject(true){|t, j| t && row(j)[@dimensions[3]].nil?}
        (@dimensions[2]..@dimensions[3]).reverse_each do |i|
          break unless (@dimensions[0]..@dimensions[1]).inject(true){|t, j| t && row(j)[i].to_s.empty?}
          @dimensions[3] = i
        end
        @dimensions[3] = @dimensions[3]
      end
    end

    private
    def index_of_first ary # :nodoc:
      return unless ary
      ary.index(ary.find do |elm| elm end)
    end
    def recalculate_dimensions # :nodoc:
      shorten @rows
      @dimensions = []
      @dimensions[0] = index_of_first(@rows) || 0
      @dimensions[1] = @rows.size
      compact = @rows.compact
      @dimensions[2] = compact.collect do |row| row.first_used end.compact.min || 0
      @dimensions[3] = compact.collect do |row| row.first_unused end.max || 0
      @dimensions
    end
    def shorten ary # :nodoc:
      return unless ary
      while !ary.empty? && !ary.last
        ary.pop
      end
      ary unless ary.empty?
    end
  end
end
