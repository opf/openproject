# encoding: utf-8

# cells.rb: Methods for accessing rows, columns, and cells of a Prawn::Table.
#
# Copyright December 2009, Brad Ediger. All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.

module Prawn
  class Table
    # Selects the given rows (0-based) for styling. Returns a Cells object --
    # see the documentation on Cells for things you can do with cells.
    #
    def rows(row_spec)
      cells.rows(row_spec)
    end
    alias_method :row, :rows

    # Selects the given columns (0-based) for styling. Returns a Cells object
    # -- see the documentation on Cells for things you can do with cells.
    #
    def columns(col_spec)
      cells.columns(col_spec)
    end
    alias_method :column, :columns

    # Represents a selection of cells to be styled. Operations on a CellProxy
    # can be chained, and cell properties can be set one-for-all on the proxy.
    #
    # To set vertical borders only:
    #
    #   table.cells.borders = [:left, :right]
    #
    # To highlight a rectangular area of the table:
    #
    #   table.rows(1..3).columns(2..4).background_color = 'ff0000'
    #
    class Cells < Array

      def fits_on_current_page?(offset, ref_bounds)
        # an empty row array means it definitely fits
        return true if self.empty?

        height_with_span < (self[0,0].y + offset) - ref_bounds.absolute_bottom
      end

      # @group Experimental API

      # Limits selection to the given row or rows. +row_spec+ can be anything
      # that responds to the === operator selecting a set of 0-based row
      # numbers; most commonly a number or a range.
      #
      #   table.row(0)     # selects first row
      #   table.rows(3..4) # selects rows four and five
      #
      def rows(row_spec)
        index_cells unless defined?(@indexed) && @indexed
        row_spec = transform_spec(row_spec, @first_row, @row_count)
        Cells.new(@rows[row_spec] ||= select { |c|
                    row_spec.respond_to?(:include?) ?
                      row_spec.include?(c.row) : row_spec === c.row })
      end
      alias_method :row, :rows

      # Returns the number of rows in the list.
      #
      def row_count
        index_cells unless defined?(@indexed) && @indexed
        @row_count
      end

      # Limits selection to the given column or columns. +col_spec+ can be
      # anything that responds to the === operator selecting a set of 0-based
      # column numbers; most commonly a number or a range.
      #
      #   table.column(0)     # selects first column
      #   table.columns(3..4) # selects columns four and five
      #
      def columns(col_spec)
        index_cells unless defined?(@indexed) && @indexed
        col_spec = transform_spec(col_spec, @first_column, @column_count)
        Cells.new(@columns[col_spec] ||= select { |c|
                    col_spec.respond_to?(:include?) ?
                      col_spec.include?(c.column) : col_spec === c.column })
      end
      alias_method :column, :columns

      # Returns the number of columns in the list.
      #
      def column_count
        index_cells unless defined?(@indexed) && @indexed
        @column_count
      end

      # Allows you to filter the given cells by arbitrary properties.
      #
      #   table.column(4).filter { |cell| cell.content =~ /Yes/ }.
      #     background_color = '00ff00'
      #
      def filter(&block)
        Cells.new(select(&block))
      end

      # Retrieves a cell based on its 0-based row and column. Returns an
      # individual Cell, not a Cells collection.
      #
      #   table.cells[0, 0].content # => "First cell content"
      #
      def [](row, col)
        return nil if empty?
        index_cells unless defined?(@indexed) && @indexed
        row_array, col_array = @rows[@first_row + row] || [], @columns[@first_column + col] || []
        if row_array.length < col_array.length
          row_array.find { |c| c.column == @first_column + col }
        else
          col_array.find { |c| c.row == @first_row + row }
        end
      end

      # Puts a cell in the collection at the given position. Internal use only.
      #
      def []=(row, col, cell) # :nodoc:
        cell.extend(Cell::InTable)
        cell.row = row
        cell.column = col

        if defined?(@indexed) && @indexed
          (@rows[row]    ||= []) << cell
          (@columns[col] ||= []) << cell
          @first_row    = row if !@first_row    || row < @first_row
          @first_column = col if !@first_column || col < @first_column
          @row_count    = @rows.size
          @column_count = @columns.size
        end

        self << cell
      end

      # Supports setting multiple properties at once.
      #
      #   table.cells.style(:padding => 0, :border_width => 2)
      #
      # is the same as:
      #
      #   table.cells.padding = 0
      #   table.cells.border_width = 2
      #
      # You can also pass a block, which will be called for each cell in turn.
      # This allows you to set more complicated properties:
      #
      #   table.cells.style { |cell| cell.border_width += 12 }
      #
      def style(options={}, &block)
        each do |cell|
          next if cell.is_a?(Cell::SpanDummy)
          cell.style(options, &block)
        end
      end

      # Returns the total width of all columns in the selected set.
      #
      def width
        ColumnWidthCalculator.new(self).natural_widths.inject(0, &:+)
      end

      # Returns minimum width required to contain cells in the set.
      #
      def min_width
        aggregate_cell_values(:column, :avg_spanned_min_width, :max)
      end

      # Returns maximum width that can contain cells in the set.
      #
      def max_width
        aggregate_cell_values(:column, :max_width_ignoring_span, :max)
      end

      # Returns the total height of all rows in the selected set.
      #
      def height
        aggregate_cell_values(:row, :height_ignoring_span, :max)
      end

      # Returns the total height of all rows in the selected set
      # including spanned cells if the cell is the master cell
      #
      def height_with_span
        aggregate_cell_values(:row, :height, :max)
      end

      # Supports setting arbitrary properties on a group of cells.
      #
      #   table.cells.row(3..6).background_color = 'cc0000'
      #
      def method_missing(id, *args, &block)
        if id.to_s =~ /=\z/
          each { |c| c.send(id, *args, &block) if c.respond_to?(id) }
        else
          super
        end
      end

      protected

      # Defers indexing until rows() or columns() is actually called on the
      # Cells object. Without this, we would needlessly index the leaf nodes of
      # the object graph, the ones that are only there to be iterated over.
      #
      # Make sure to call this before using @rows or @columns.
      #
      def index_cells
        @rows = {}
        @columns = {}

        each do |cell|
          @rows[cell.row] ||= []
          @rows[cell.row] << cell

          @columns[cell.column] ||= []
          @columns[cell.column] << cell
        end

        @first_row    = @rows.keys.min
        @first_column = @columns.keys.min

        @row_count    = @rows.size
        @column_count = @columns.size

        @indexed = true
      end

      # Sum up a min/max value over rows or columns in the cells selected.
      # Takes the min/max (per +aggregate+) of the result of sending +meth+ to
      # each cell, grouped by +row_or_column+.
      #
      def aggregate_cell_values(row_or_column, meth, aggregate)
        ColumnWidthCalculator.new(self).aggregate_cell_values(row_or_column, meth, aggregate)
      end

      # Transforms +spec+, a column / row specification, into an object that
      # can be compared against a row or column number using ===. Normalizes
      # negative indices to be positive, given a total size of +total+. The
      # first row/column is indicated by +first+; this value is considered row
      # or column 0.
      #
      def transform_spec(spec, first, total)
        case spec
        when Range
          transform_spec(spec.begin, first, total) ..
            transform_spec(spec.end, first, total)
        when Integer
          spec < 0 ? (first + total + spec) : first + spec
        when Enumerable
          spec.map { |x| first + x }
        else # pass through
          raise "Don't understand spec #{spec.inspect}"
        end
      end
    end
  end
end
