# encoding: utf-8
#
# table.rb: Table drawing functionality.
#
# Copyright December 2009, Brad Ediger. All rights reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.


require 'prawn'
require_relative 'table/column_width_calculator'
require_relative 'table/cell'
require_relative 'table/cells'
require_relative 'table/cell/in_table'
require_relative 'table/cell/text'
require_relative 'table/cell/subtable'
require_relative 'table/cell/image'
require_relative 'table/cell/span_dummy'

module Prawn
  module Errors
    # This error is raised when table data is malformed
    #
    InvalidTableData = Class.new(StandardError)

    # This error is raised when an empty or nil table is rendered
    #
    EmptyTable = Class.new(StandardError)
  end

  # Next-generation table drawing for Prawn.
  #
  # = Data
  #
  # Data, for a Prawn table, is a two-dimensional array of objects that can be
  # converted to cells ("cellable" objects). Cellable objects can be:
  #
  # String::
  #   Produces a text cell. This is the most common usage.
  # Prawn::Table::Cell::
  #   If you have already built a Cell or have a custom subclass of Cell you
  #   want to use in a table, you can pass through Cell objects.
  # Prawn::Table::
  #   Creates a subtable (a table within a cell). You can use
  #   Prawn::Document#make_table to create a table for use as a subtable
  #   without immediately drawing it. See examples/table/bill.rb for a
  #   somewhat complex use of subtables.
  # Array::
  #   Creates a simple subtable. Create a Table object using make_table (see
  #   above) if you need more control over the subtable's styling.
  #
  # = Options
  #
  # Prawn/Layout provides many options to control style and layout of your
  # table. These options are implemented with a uniform interface: the +:foo+
  # option always sets the +foo=+ accessor. See the accessor and method
  # documentation for full details on the options you can pass. Some
  # highlights:
  #
  # +cell_style+::
  #   A hash of style options to style all cells. See the documentation on
  #   Prawn::Table::Cell for all cell style options.
  # +header+::
  #   If set to +true+, the first row will be repeated on every page. If set
  #   to an Integer, the first +x+ rows will be repeated on every page. Row
  #   numbering (for styling and other row-specific options) always indexes
  #   based on your data array. Whether or not you have a header, row(n) always
  #   refers to the nth element (starting from 0) of the +data+ array.
  # +column_widths+::
  #   Sets widths for individual columns. Manually setting widths can give
  #   better results than letting Prawn guess at them, as Prawn's algorithm
  #   for defaulting widths is currently pretty boneheaded. If you experience
  #   problems like weird column widths or CannotFit errors, try manually
  #   setting widths on more columns.
  # +position+::
  #   Either :left (the default), :center, :right, or a number. Specifies the
  #   horizontal position of the table within its bounding box. If a number is
  #   provided, it specifies the distance in points from the left edge.
  #
  # = Initializer Block
  #
  # If a block is passed to methods that initialize a table
  # (Prawn::Table.new, Prawn::Document#table, Prawn::Document#make_table), it
  # will be called after cell setup but before layout. This is a very flexible
  # way to specify styling and layout constraints. This code sets up a table
  # where the second through the fourth rows (1-3, indexed from 0) are each one
  # inch (72 pt) wide:
  #
  #   pdf.table(data) do |table|
  #     table.rows(1..3).width = 72
  #   end
  #
  # As with Prawn::Document#initialize, if the block has no arguments, it will
  # be evaluated in the context of the object itself. The above code could be
  # rewritten as:
  #
  #   pdf.table(data) do
  #     rows(1..3).width = 72
  #   end
  #
  class Table
    module Interface 
      # @group Experimental API

      # Set up and draw a table on this document. A block can be given, which will
      # be run after cell setup but before layout and drawing.
      #
      # See the documentation on Prawn::Table for details on the arguments.
      #
      def table(data, options={}, &block)
        t = Table.new(data, self, options, &block)
        t.draw
        t
      end

      # Set up, but do not draw, a table. Useful for creating subtables to be
      # inserted into another Table. Call +draw+ on the resulting Table to ink it.
      #
      # See the documentation on Prawn::Table for details on the arguments.
      #
      def make_table(data, options={}, &block)
        Table.new(data, self, options, &block)
      end
    end

    # Set up a table on the given document. Arguments:
    #
    # +data+::
    #   A two-dimensional array of cell-like objects. See the "Data" section
    #   above for the types of objects that can be put in a table.
    # +document+::
    #   The Prawn::Document instance on which to draw the table.
    # +options+::
    #   A hash of attributes and values for the table. See the "Options" block
    #   above for details on available options.
    #
    def initialize(data, document, options={}, &block)
      @pdf = document
      @cells = make_cells(data)
      @header = false
      options.each { |k, v| send("#{k}=", v) }

      if block
        block.arity < 1 ? instance_eval(&block) : block[self]
      end

      set_column_widths
      set_row_heights
      position_cells
    end

    # Number of rows in the table.
    #
    attr_reader :row_length

    # Number of columns in the table.
    #
    attr_reader :column_length

    # Manually set the width of the table.
    #
    attr_writer :width

    # Position (:left, :right, :center, or a number indicating distance in
    # points from the left edge) of the table within its parent bounds.
    #
    attr_writer :position

    # Returns a Prawn::Table::Cells object representing all of the cells in
    # this table.
    #
    attr_reader :cells

    # Specify a callback to be called before each page of cells is rendered.
    # The block is passed a Cells object containing all cells to be rendered on
    # that page. You can change styling of the cells in this block, but keep in
    # mind that the cells have already been positioned and sized.
    #
    def before_rendering_page(&block)
      @before_rendering_page = block
    end

    # Returns the width of the table in PDF points.
    #
    def width
      @width ||= [natural_width, @pdf.bounds.width].min
    end

    # Sets column widths for the table. The argument can be one of the following
    # types:
    #
    # +Array+::
    #   <tt>[w0, w1, w2, ...]</tt> (specify a width for each column)
    # +Hash+::
    #   <tt>{0 => w0, 1 => w1, ...}</tt> (keys are column names, values are
    #   widths)
    # +Numeric+::
    #   +72+ (sets width for all columns)
    #
    def column_widths=(widths)
      case widths
      when Array
        widths.each_with_index { |w, i| column(i).width = w }
      when Hash
        widths.each { |i, w| column(i).width = w }
      when Numeric
        cells.width = widths
      else
        raise ArgumentError, "cannot interpret column widths"
      end
    end

    # Returns the height of the table in PDF points.
    #
    def height
      cells.height
    end

    # If +true+, designates the first row as a header row to be repeated on
    # every page. If an integer, designates the number of rows to be treated
    # as a header Does not change row numbering -- row numbers always index
    # into the data array provided, with no modification.
    #
    attr_writer :header

    # Accepts an Array of alternating row colors to stripe the table.
    #
    attr_writer :row_colors

    # Sets styles for all cells.
    #
    #   pdf.table(data, :cell_style => { :borders => [:left, :right] })
    #
    def cell_style=(style_hash)
      cells.style(style_hash)
    end

    # Allows generic stylable content. This is an alternate syntax that some
    # prefer to the attribute-based syntax. This code using style:
    #
    #   pdf.table(data) do
    #     style(row(0), :background_color => 'ff00ff')
    #     style(column(0)) { |c| c.border_width += 1 }
    #   end
    #
    # is equivalent to:
    #
    #   pdf.table(data) do
    #     row(0).style :background_color => 'ff00ff'
    #     column(0).style { |c| c.border_width += 1 }
    #   end
    #
    def style(stylable, style_hash={}, &block)
      stylable.style(style_hash, &block)
    end

    # Draws the table onto the document at the document's current y-position.
    #
    def draw
      with_position do
        # Reference bounds are the non-stretchy bounds used to decide when to
        # flow to a new column / page.
        ref_bounds = @pdf.reference_bounds

        # Determine whether we're at the top of the current bounds (margin box or
        # bounding box). If we're at the top, we couldn't gain any more room by
        # breaking to the next page -- this means, in particular, that if the
        # first row is taller than the margin box, we will only move to the next
        # page if we're below the top. Some floating-point tolerance is added to
        # the calculation.
        #
        # Note that we use the actual bounds, not the reference bounds. This is
        # because even if we are in a stretchy bounding box, flowing to the next
        # page will not buy us any space if we are at the top.
        #
        # initial_row_on_initial_page may return 0 (already at the top OR created
        # a new page) or -1 (enough space)
        started_new_page_at_row = initial_row_on_initial_page

        # The cell y-positions are based on an infinitely long canvas. The offset
        # keeps track of how much we have to add to the original, theoretical
        # y-position to get to the actual position on the current page.
        offset = @pdf.y

        # Duplicate each cell of the header row into @header_row so it can be
        # modified in before_rendering_page callbacks.
        @header_row = header_rows if @header

        # Track cells to be drawn on this page. They will all be drawn when this
        # page is finished.
        cells_this_page = []

        @cells.each do |cell|
          if start_new_page?(cell, offset, ref_bounds) 
            # draw cells on the current page and then start a new one
            # this will also add a header to the new page if a header is set
            # reset array of cells for the new page
            cells_this_page, offset = ink_and_draw_cells_and_start_new_page(cells_this_page, cell)

            # remember the current row for background coloring
            started_new_page_at_row = cell.row
          end

          # Set background color, if any.
          cell = set_background_color(cell, started_new_page_at_row)

          # add the current cell to the cells array for the current page
          cells_this_page << [cell, [cell.relative_x, cell.relative_y(offset)]]
        end

        # Draw the last page of cells
        ink_and_draw_cells(cells_this_page)

        @pdf.move_cursor_to(@cells.last.relative_y(offset) - @cells.last.height)
      end
    end

    # Calculate and return the constrained column widths, taking into account
    # each cell's min_width, max_width, and any user-specified constraints on
    # the table or column size.
    #
    # Because the natural widths can be silly, this does not always work so well
    # at guessing a good size for columns that have vastly different content. If
    # you see weird problems like CannotFit errors or shockingly bad column
    # sizes, you should specify more column widths manually.
    #
    def column_widths
      @column_widths ||= begin
        if width - cells.min_width < -Prawn::FLOAT_PRECISION
          raise Errors::CannotFit,
            "Table's width was set too small to contain its contents " +
            "(min width #{cells.min_width}, requested #{width})"
        end

        if width - cells.max_width > Prawn::FLOAT_PRECISION
          raise Errors::CannotFit,
            "Table's width was set larger than its contents' maximum width " +
            "(max width #{cells.max_width}, requested #{width})"
        end

        if width - natural_width < -Prawn::FLOAT_PRECISION
          # Shrink the table to fit the requested width.
          f = (width - cells.min_width).to_f / (natural_width - cells.min_width)

          (0...column_length).map do |c|
            min, nat = column(c).min_width, natural_column_widths[c]
            (f * (nat - min)) + min
          end
        elsif width - natural_width > Prawn::FLOAT_PRECISION
          # Expand the table to fit the requested width.
          f = (width - cells.width).to_f / (cells.max_width - cells.width)

          (0...column_length).map do |c|
            nat, max = natural_column_widths[c], column(c).max_width
            (f * (max - nat)) + nat
          end
        else
          natural_column_widths
        end
      end
    end

    # Returns an array with the height of each row.
    #
    def row_heights
      @natural_row_heights ||=
        begin
          heights_by_row = Hash.new(0)
          cells.each do |cell|
            next if cell.is_a?(Cell::SpanDummy)

            # Split the height of row-spanned cells evenly by rows
            height_per_row = cell.height.to_f / cell.rowspan
            cell.rowspan.times do |i|
              heights_by_row[cell.row + i] =
                [heights_by_row[cell.row + i], height_per_row].max
            end
          end
          heights_by_row.sort_by { |row, _| row }.map { |_, h| h }
        end
    end

    protected
    
    # sets the background color (if necessary) for the given cell
    def set_background_color(cell, started_new_page_at_row)
      if defined?(@row_colors) && @row_colors && (!@header || cell.row > 0)
        # Ensure coloring restarts on every page (to make sure the header
        # and first row of a page are not colored the same way).
        rows = number_of_header_rows

        index = cell.row - [started_new_page_at_row, rows].max

        cell.background_color ||= @row_colors[index % @row_colors.length]
      end
      cell
    end

    # number of rows of the header
    # @return [Integer] the number of rows of the header
    def number_of_header_rows
      # header may be set to any integer value -> number of rows
      if @header.is_a? Integer
        return @header
      # header may be set to true -> first row is repeated
      elsif @header
        return 1
      end
      # defaults to 0 header rows
      0
    end

    # should we start a new page? (does the current row fail to fit on this page)
    def start_new_page?(cell, offset, ref_bounds)
      # we only need to run this test on the first cell in a row
      # check if the rows height fails to fit on the page
      # check if the row is not the first on that page (wouldn't make sense to go to next page in this case)
      (cell.column == 0 && cell.row > 0 &&
       !row(cell.row).fits_on_current_page?(offset, ref_bounds))
    end

    # ink cells and then draw them
    def ink_and_draw_cells(cells_this_page, draw_cells = true)
      ink_cells(cells_this_page)
      Cell.draw_cells(cells_this_page) if draw_cells
    end

    # ink and draw cells, then start a new page
    def ink_and_draw_cells_and_start_new_page(cells_this_page, cell)
      # don't draw only a header
      draw_cells = (@header_row.nil? || cells_this_page.size > @header_row.size)
      
      ink_and_draw_cells(cells_this_page, draw_cells)
      
      # start a new page or column
      @pdf.bounds.move_past_bottom

      offset = (@pdf.y - cell.y)

      cells_next_page = []

      header_height = add_header(cell.row, cells_next_page)

      # account for header height in newly generated offset
      offset -= header_height

      # reset cells_this_page in calling function and return new offset
      return cells_next_page, offset
    end

    # Ink all cells on the current page
    def ink_cells(cells_this_page)
      if defined?(@before_rendering_page) && @before_rendering_page
        c = Cells.new(cells_this_page.map { |ci, _| ci })
        @before_rendering_page.call(c)
      end
    end

    # Determine whether we're at the top of the current bounds (margin box or
    # bounding box). If we're at the top, we couldn't gain any more room by
    # breaking to the next page -- this means, in particular, that if the
    # first row is taller than the margin box, we will only move to the next
    # page if we're below the top. Some floating-point tolerance is added to
    # the calculation.
    #
    # Note that we use the actual bounds, not the reference bounds. This is
    # because even if we are in a stretchy bounding box, flowing to the next
    # page will not buy us any space if we are at the top.
    # @return [Integer] 0 (already at the top OR created a new page) or -1 (enough space)
    def initial_row_on_initial_page
      # we're at the top of our bounds
      return 0 if fits_on_page?(@pdf.bounds.height)

      needed_height = row(0..number_of_header_rows).height

      # have we got enough room to fit the first row (including header row(s))
      use_reference_bounds = true
      return -1 if fits_on_page?(needed_height, use_reference_bounds)

      # If there isn't enough room left on the page to fit the first data row
      # (including the header), start the table on the next page.
      @pdf.bounds.move_past_bottom

      # we are at the top of a new page
      0
    end

    # do we have enough room to fit a given height on to the current page?
    def fits_on_page?(needed_height, use_reference_bounds = false)
      if use_reference_bounds
        bounds = @pdf.reference_bounds
      else
        bounds = @pdf.bounds
      end
      needed_height < @pdf.y - (bounds.absolute_bottom - Prawn::FLOAT_PRECISION)
    end

    # return the header rows
    # @api private
    def header_rows
      header_rows = Cells.new
      number_of_header_rows.times do |r|
        row(r).each { |cell| header_rows[cell.row, cell.column] = cell.dup }
      end
      header_rows
    end

    # Converts the array of cellable objects given into instances of
    # Prawn::Table::Cell, and sets up their in-table properties so that they
    # know their own position in the table.
    #
    def make_cells(data)
      assert_proper_table_data(data)

      cells = Cells.new

      row_number = 0
      data.each do |row_cells|
        column_number = 0
        row_cells.each do |cell_data|
          # If we landed on a spanned cell (from a rowspan above), continue
          # until we find an empty spot.
          column_number += 1 until cells[row_number, column_number].nil?

          # Build the cell and store it in the Cells collection.
          cell = Cell.make(@pdf, cell_data)
          cells[row_number, column_number] = cell

          # Add dummy cells for the rest of the cells in the span group. This
          # allows Prawn to keep track of the horizontal and vertical space
          # occupied in each column and row spanned by this cell, while still
          # leaving the master (top left) cell in the group responsible for
          # drawing. Dummy cells do not put ink on the page.
          cell.rowspan.times do |i|
            cell.colspan.times do |j|
              next if i == 0 && j == 0

              # It is an error to specify spans that overlap; catch this here
              if cells[row_number + i, column_number + j]
                raise Prawn::Errors::InvalidTableSpan,
                  "Spans overlap at row #{row_number + i}, " +
                  "column #{column_number + j}."
              end

              dummy = Cell::SpanDummy.new(@pdf, cell)
              cells[row_number + i, column_number + j] = dummy
              cell.dummy_cells << dummy
            end
          end

          column_number += cell.colspan
        end

        row_number += 1
      end

      # Calculate the number of rows and columns in the table, taking into
      # account that some cells may span past the end of the physical cells we
      # have.
      @row_length = cells.map do |cell|
        cell.row + cell.rowspan
      end.max

      @column_length = cells.map do |cell|
        cell.column + cell.colspan
      end.max

      cells
    end

    def add_header(row_number, cells_this_page)
      x_offset = @pdf.bounds.left_side - @pdf.bounds.absolute_left
      header_height = 0
      if row_number > 0 && @header
        y_coord = @pdf.cursor
        number_of_header_rows.times do |h|
          additional_header_height = add_one_header_row(cells_this_page, x_offset, y_coord-header_height, row_number-1, h)
          header_height += additional_header_height
        end        
      end
      header_height
    end

    # Add the header row(s) to the given array of cells at the given y-position.
    # Number the row with the given +row+ index, so that the header appears (in
    # any Cells built for this page) immediately prior to the first data row on
    # this page.
    #
    # Return the height of the header.
    #
    def add_one_header_row(page_of_cells, x_offset, y, row, row_of_header=nil)
      rows_to_operate_on = @header_row
      rows_to_operate_on = @header_row.rows(row_of_header) if row_of_header
      rows_to_operate_on.each do |cell|
        cell.row = row
        cell.dummy_cells.each {|c| 
          if cell.rowspan > 1
            # be sure to account for cells that span multiple rows
            # in this case you need multiple row numbers
            c.row += row
          else
            c.row = row
          end
        }
        page_of_cells << [cell, [cell.x + x_offset, y]]
      end
      rows_to_operate_on.height
    end

    # Raises an error if the data provided cannot be converted into a valid
    # table.
    #
    def assert_proper_table_data(data)
      if data.nil? || data.empty?
        raise Prawn::Errors::EmptyTable,
          "data must be a non-empty, non-nil, two dimensional array " +
          "of cell-convertible objects"
      end

      unless data.all? { |e| Array === e }
        raise Prawn::Errors::InvalidTableData,
          "data must be a two dimensional array of cellable objects"
      end
    end

    # Returns an array of each column's natural (unconstrained) width.
    #
    def natural_column_widths
      @natural_column_widths ||= ColumnWidthCalculator.new(cells).natural_widths
    end

    # Returns the "natural" (unconstrained) width of the table. This may be
    # extremely silly; for example, the unconstrained width of a paragraph of
    # text is the width it would assume if it were not wrapped at all. Could be
    # a mile long.
    #
    def natural_width
      @natural_width ||= natural_column_widths.inject(0, &:+)
    end

    # Assigns the calculated column widths to each cell. This ensures that each
    # cell in a column is the same width. After this method is called,
    # subsequent calls to column_widths and width should return the finalized
    # values that will be used to ink the table.
    #
    def set_column_widths
      column_widths.each_with_index do |w, col_num|
        column(col_num).width = w
      end
    end

    # Assigns the row heights to each cell. This ensures that every cell in a
    # row is the same height.
    #
    def set_row_heights
      row_heights.each_with_index { |h, row_num| row(row_num).height = h }
    end

    # Set each cell's position based on the widths and heights of cells
    # preceding it.
    #
    def position_cells
      # Calculate x- and y-positions as running sums of widths / heights.
      x_positions = column_widths.inject([0]) { |ary, x|
        ary << (ary.last + x); ary }[0..-2]
      x_positions.each_with_index { |x, i| column(i).x = x }

      # y-positions assume an infinitely long canvas starting at zero -- this
      # is corrected for in Table#draw, and page breaks are properly inserted.
      y_positions = row_heights.inject([0]) { |ary, y|
        ary << (ary.last - y); ary}[0..-2]
      y_positions.each_with_index { |y, i| row(i).y = y }
    end

    # Sets up a bounding box to position the table according to the specified
    # :position option, and yields.
    #
    def with_position
      x = case defined?(@position) && @position || :left
          when :left   then return yield
          when :center then (@pdf.bounds.width - width) / 2.0
          when :right  then  @pdf.bounds.width - width
          when Numeric then  @position
          else raise ArgumentError, "unknown position #{@position.inspect}"
          end
      dy = @pdf.bounds.absolute_top - @pdf.y
      final_y = nil

      @pdf.bounding_box([x, @pdf.bounds.top], :width => width) do
        @pdf.move_down dy
        yield
        final_y = @pdf.y
      end

      @pdf.y = final_y
    end

  end
end

Prawn::Document.extensions << Prawn::Table::Interface
