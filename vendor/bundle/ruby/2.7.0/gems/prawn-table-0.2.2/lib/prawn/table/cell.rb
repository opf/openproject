# encoding: utf-8

# cell.rb: Table cell drawing.
#
# Copyright December 2009, Gregory Brown and Brad Ediger. All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.

require 'date'
module Prawn
  class Document

    # @group Experimental API

    # Instantiates and draws a cell on the document.
    #
    #   cell(:content => "Hello world!", :at => [12, 34])
    #
    # See Prawn::Table::Cell.make for full options.
    #
    def cell(options={})
      cell = Table::Cell.make(self, options.delete(:content), options)
      cell.draw
      cell
    end

    # Set up, but do not draw, a cell. Useful for creating cells with
    # formatting options to be inserted into a Table. Call +draw+ on the
    # resulting Cell to ink it.
    #
    # See the documentation on Prawn::Cell for details on the arguments.
    #
    def make_cell(content, options={})
      Prawn::Table::Cell.make(self, content, options)
    end

  end

  class Table

    # A Cell is a rectangular area of the page into which content is drawn. It
    # has a framework for sizing itself and adding padding and simple styling.
    # There are several standard Cell subclasses that handle things like text,
    # Tables, and (in the future) stamps, images, and arbitrary content.
    #
    # Cells are a basic building block for table support (see Prawn::Table).
    #
    # Please subclass me if you want new content types! I'm designed to be very
    # extensible. See the different standard Cell subclasses in
    # lib/prawn/table/cell/*.rb for a template.
    #
    class Cell

      # Amount of dead space (in PDF points) inside the borders but outside the
      # content. Padding defaults to 5pt.
      #
      attr_reader :padding

      # If provided, the minimum width that this cell in its column will permit.
      #
      def min_width_ignoring_span
        set_width_constraints
        @min_width
      end

      # Minimum width of the entire span group this cell controls.
      #
      def min_width
        return min_width_ignoring_span if @colspan == 1

        # Sum up the largest min-width from each column, including myself.
        min_widths = Hash.new(0)
        dummy_cells.each do |cell|
          min_widths[cell.column] =
            [min_widths[cell.column], cell.min_width].max
        end
        min_widths[column] = [min_widths[column], min_width_ignoring_span].max
        min_widths.values.inject(0, &:+)
      end

      # Min-width of the span divided by the number of columns.
      #
      def avg_spanned_min_width
        min_width.to_f / colspan
      end

      # If provided, the maximum width that this cell can be drawn in, within
      # its column.
      #
      def max_width_ignoring_span
        set_width_constraints
        @max_width
      end

      # Maximum width of the entire span group this cell controls.
      #
      def max_width
        return max_width_ignoring_span if @colspan == 1

        # Sum the smallest max-width from each column in the group, including
        # myself.
        max_widths = Hash.new(0)
        dummy_cells.each do |cell|
          max_widths[cell.column] =
            [max_widths[cell.column], cell.max_width].min
        end
        max_widths[column] = [max_widths[column], max_width_ignoring_span].min
        max_widths.values.inject(0, &:+)
      end

      # Manually specify the cell's height.
      #
      attr_writer :height

      # Specifies which borders to enable. Must be an array of zero or more of:
      # <tt>[:left, :right, :top, :bottom]</tt>.
      #
      attr_accessor :borders

      # Width, in PDF points, of the cell's borders: [top, right, bottom, left].
      #
      attr_reader :border_widths

      # HTML RGB-format ("ccffff") border colors: [top, right, bottom, left].
      #
      attr_reader :border_colors

      # Line style
      #
      attr_reader :border_lines

      # Specifies the content for the cell. Must be a "cellable" object. See the
      # "Data" section of the Prawn::Table documentation for details on cellable
      # objects.
      #
      attr_accessor :content

      # The background color, if any, for this cell. Specified in HTML RGB
      # format, e.g., "ccffff". The background is drawn under the whole cell,
      # including any padding.
      #
      attr_accessor :background_color

      # Number of columns this cell spans. Defaults to 1.
      #
      attr_reader :colspan

      # Number of rows this cell spans. Defaults to 1.
      #
      attr_reader :rowspan

      # Array of SpanDummy cells (if any) that represent the other cells in
      # this span group. They know their own width / height, but do not draw
      # anything.
      #
      attr_reader :dummy_cells

      # Instantiates a Cell based on the given options. The particular class of
      # cell returned depends on the :content argument. See the Prawn::Table
      # documentation under "Data" for allowable content types.
      #
      def self.make(pdf, content, options={})
        at = options.delete(:at) || [0, pdf.cursor]
        content = content.to_s if content.nil? || content.kind_of?(Numeric) ||
          content.kind_of?(Date)

        if content.is_a?(Hash)
          if content[:image]
            return Cell::Image.new(pdf, at, content)
          end
          options.update(content)
          content = options[:content]
        else
          options[:content] = content
        end

        options[:content] = content = "" if content.nil?

        case content
        when Prawn::Table::Cell
          content
        when String
          Cell::Text.new(pdf, at, options)
        when Prawn::Table
          Cell::Subtable.new(pdf, at, options)
        when Array
          subtable = Prawn::Table.new(options[:content], pdf, {})
          Cell::Subtable.new(pdf, at, options.merge(:content => subtable))
        else
          raise Errors::UnrecognizedTableContent
        end
      end

      # A small amount added to the bounding box width to cover over floating-
      # point errors when round-tripping from content_width to width and back.
      # This does not change cell positioning; it only slightly expands each
      # cell's bounding box width so that rounding error does not prevent a cell
      # from rendering.
      #
      FPTolerance = 1

      # Sets up a cell on the document +pdf+, at the given x/y location +point+,
      # with the given +options+. Cell, like Table, follows the "options set
      # accessors" paradigm (see "Options" under the Table documentation), so
      # any cell accessor <tt>cell.foo = :bar</tt> can be set by providing the
      # option <tt>:foo => :bar</tt> here.
      #
      def initialize(pdf, point, options={})
        @pdf   = pdf
        @point = point

        # Set defaults; these can be changed by options
        @padding       = [5, 5, 5, 5]
        @borders       = [:top, :bottom, :left, :right]
        @border_widths = [1] * 4
        @border_colors = ['000000'] * 4
        @border_lines  = [:solid] * 4
        @colspan = 1
        @rowspan = 1
        @dummy_cells = []

        options.each { |k, v| send("#{k}=", v) }

        @initializer_run = true
      end

      # Supports setting multiple properties at once.
      #
      #   cell.style(:padding => 0, :border_width => 2)
      #
      # is the same as:
      #
      #   cell.padding = 0
      #   cell.border_width = 2
      #
      def style(options={}, &block)
        options.each do |k, v|
          send("#{k}=", v) if respond_to?("#{k}=")
        end

        # The block form supports running a single block for multiple cells, as
        # in Cells#style.
        block.call(self) if block
      end

      # Returns the width of the cell in its first column alone, ignoring any
      # colspans.
      #
      def width_ignoring_span
        # We can't ||= here because the FP error accumulates on the round-trip
        # from #content_width.
        defined?(@width) && @width || (content_width + padding_left + padding_right)
      end

      # Returns the cell's width in points, inclusive of padding. If the cell is
      # the master cell of a colspan, returns the width of the entire span
      # group.
      #
      def width
        return width_ignoring_span if @colspan == 1 && @rowspan == 1

        # We're in a span group; get the maximum width per column (including
        # the master cell) and sum each column.
        column_widths = Hash.new(0)
        dummy_cells.each do |cell|
          column_widths[cell.column] =
            [column_widths[cell.column], cell.width].max
        end
        column_widths[column] = [column_widths[column], width_ignoring_span].max
        column_widths.values.inject(0, &:+)
      end

      # Manually sets the cell's width, inclusive of padding.
      #
      def width=(w)
        @width = @min_width = @max_width = w
      end

      # Returns the width of the bare content in the cell, excluding padding.
      #
      def content_width
        if defined?(@width) && @width # manually set
          return @width - padding_left - padding_right
        end

        natural_content_width
      end

      # Width of the entire span group.
      #
      def spanned_content_width
        width - padding_left - padding_right
      end

      # Returns the width this cell would naturally take on, absent other
      # constraints. Must be implemented in subclasses.
      #
      def natural_content_width
        raise NotImplementedError,
          "subclasses must implement natural_content_width"
      end

      # Returns the cell's height in points, inclusive of padding, in its first
      # row only.
      #
      def height_ignoring_span
        # We can't ||= here because the FP error accumulates on the round-trip
        # from #content_height.
        defined?(@height) && @height || (content_height + padding_top + padding_bottom)
      end

      # Returns the cell's height in points, inclusive of padding. If the cell
      # is the master cell of a rowspan, returns the width of the entire span
      # group.
      #
      def height
        return height_ignoring_span if @colspan == 1 && @rowspan == 1

        # We're in a span group; get the maximum height per row (including the
        # master cell) and sum each row.
        row_heights = Hash.new(0)
        dummy_cells.each do |cell|
          row_heights[cell.row] = [row_heights[cell.row], cell.height].max
        end
        row_heights[row] = [row_heights[row], height_ignoring_span].max
        row_heights.values.inject(0, &:+)
      end

      # Returns the height of the bare content in the cell, excluding padding.
      #
      def content_height
        if defined?(@height) && @height # manually set
          return @height - padding_top - padding_bottom
        end

        natural_content_height
      end

      # Height of the entire span group.
      #
      def spanned_content_height
        height - padding_top - padding_bottom
      end

      # Returns the height this cell would naturally take on, absent
      # constraints. Must be implemented in subclasses.
      #
      def natural_content_height
        raise NotImplementedError,
          "subclasses must implement natural_content_height"
      end

      # Indicates the number of columns that this cell is to span. Defaults to
      # 1.
      #
      # This must be provided as part of the table data, like so:
      #
      #   pdf.table([["foo", {:content => "bar", :colspan => 2}]])
      #
      # Setting colspan from the initializer block is invalid because layout
      # has already run. For example, this will NOT work:
      #
      #   pdf.table([["foo", "bar"]]) { cells[0, 1].colspan = 2 }
      #
      def colspan=(span)
        if defined?(@initializer_run) && @initializer_run
          raise Prawn::Errors::InvalidTableSpan,
            "colspan must be provided in the table's structure, never in the " +
            "initialization block. See Prawn's documentation for details."
        end

        @colspan = span
      end

      # Indicates the number of rows that this cell is to span. Defaults to 1.
      #
      # This must be provided as part of the table data, like so:
      #
      #   pdf.table([["foo", {:content => "bar", :rowspan => 2}], ["baz"]])
      #
      # Setting rowspan from the initializer block is invalid because layout
      # has already run. For example, this will NOT work:
      #
      #   pdf.table([["foo", "bar"], ["baz"]]) { cells[0, 1].rowspan = 2 }
      #
      def rowspan=(span)
        if defined?(@initializer_run) && @initializer_run
          raise Prawn::Errors::InvalidTableSpan,
            "rowspan must be provided in the table's structure, never in the " +
            "initialization block. See Prawn's documentation for details."
        end

        @rowspan = span
      end

      # Draws the cell onto the document. Pass in a point [x,y] to override the
      # location at which the cell is drawn.
      #
      # If drawing a group of cells at known positions, look into
      # Cell.draw_cells, which ensures that the backgrounds, borders, and
      # content are all drawn in correct order so as not to overlap.
      #
      def draw(pt=[x, y])
        Prawn::Table::Cell.draw_cells([[self, pt]])
      end

      # Given an array of pairs [cell, pt], draws each cell at its
      # corresponding pt, making sure all backgrounds are behind all borders
      # and content.
      #
      def self.draw_cells(cells)
        cells.each do |cell, pt|
          cell.set_width_constraints
          cell.draw_background(pt)
        end

        cells.each do |cell, pt|
          cell.draw_borders(pt)
          cell.draw_bounded_content(pt)
        end
      end

      # Draws the cell's content at the point provided.
      #
      def draw_bounded_content(pt)
        @pdf.float do
          @pdf.bounding_box([pt[0] + padding_left, pt[1] - padding_top],
                            :width  => spanned_content_width + FPTolerance,
                            :height => spanned_content_height + FPTolerance) do
            draw_content
          end
        end
      end

      # x-position of the cell within the parent bounds.
      #
      def x
        @point[0]
      end

      # Set the x-position of the cell within the parent bounds.
      #
      def x=(val)
        @point[0] = val
      end

      def relative_x
        # Translate coordinates to the bounds we are in, since drawing is
        # relative to the cursor, not ref_bounds.
        x + @pdf.bounds.left_side - @pdf.bounds.absolute_left
      end

      # y-position of the cell within the parent bounds.
      #
      def y
        @point[1]
      end

      # Set the y-position of the cell within the parent bounds.
      #
      def y=(val)
        @point[1] = val
      end

      def relative_y(offset = 0)
        y + offset - @pdf.bounds.absolute_bottom
      end

      # Sets padding on this cell. The argument can be one of:
      #
      # * an integer (sets all padding)
      # * a two-element array [vertical, horizontal]
      # * a three-element array [top, horizontal, bottom]
      # * a four-element array [top, right, bottom, left]
      #
      def padding=(pad)
        @padding = case
        when pad.nil?
          [0, 0, 0, 0]
        when Numeric === pad # all padding
          [pad, pad, pad, pad]
        when pad.length == 2 # vert, horiz
          [pad[0], pad[1], pad[0], pad[1]]
        when pad.length == 3 # top, horiz, bottom
          [pad[0], pad[1], pad[2], pad[1]]
        when pad.length == 4 # top, right, bottom, left
          [pad[0], pad[1], pad[2], pad[3]]
        else
          raise ArgumentError, ":padding must be a number or an array [v,h] " +
            "or [t,r,b,l]"
        end
      end

      def padding_top
        @padding[0]
      end

      def padding_top=(val)
        @padding[0] = val
      end

      def padding_right
        @padding[1]
      end

      def padding_right=(val)
        @padding[1] = val
      end

      def padding_bottom
        @padding[2]
      end

      def padding_bottom=(val)
        @padding[2] = val
      end

      def padding_left
        @padding[3]
      end

      def padding_left=(val)
        @padding[3] = val
      end

      # Sets border colors on this cell. The argument can be one of:
      #
      # * an integer (sets all colors)
      # * a two-element array [vertical, horizontal]
      # * a three-element array [top, horizontal, bottom]
      # * a four-element array [top, right, bottom, left]
      #
      def border_color=(color)
        @border_colors = case
        when color.nil?
          ["000000"] * 4
        when String === color # all colors
          [color, color, color, color]
        when color.length == 2 # vert, horiz
          [color[0], color[1], color[0], color[1]]
        when color.length == 3 # top, horiz, bottom
          [color[0], color[1], color[2], color[1]]
        when color.length == 4 # top, right, bottom, left
          [color[0], color[1], color[2], color[3]]
        else
          raise ArgumentError, ":border_color must be a string " +
            "or an array [v,h] or [t,r,b,l]"
        end
      end
      alias_method :border_colors=, :border_color=

      def border_top_color
        @border_colors[0]
      end

      def border_top_color=(val)
        @border_colors[0] = val
      end

      def border_right_color
        @border_colors[1]
      end

      def border_right_color=(val)
        @border_colors[1] = val
      end

      def border_bottom_color
        @border_colors[2]
      end

      def border_bottom_color=(val)
        @border_colors[2] = val
      end

      def border_left_color
        @border_colors[3]
      end

      def border_left_color=(val)
        @border_colors[3] = val
      end

      # Sets border widths on this cell. The argument can be one of:
      #
      # * an integer (sets all widths)
      # * a two-element array [vertical, horizontal]
      # * a three-element array [top, horizontal, bottom]
      # * a four-element array [top, right, bottom, left]
      #
      def border_width=(width)
        @border_widths = case
        when width.nil?
          ["000000"] * 4
        when Numeric === width # all widths
          [width, width, width, width]
        when width.length == 2 # vert, horiz
          [width[0], width[1], width[0], width[1]]
        when width.length == 3 # top, horiz, bottom
          [width[0], width[1], width[2], width[1]]
        when width.length == 4 # top, right, bottom, left
          [width[0], width[1], width[2], width[3]]
        else
          raise ArgumentError, ":border_width must be a string " +
            "or an array [v,h] or [t,r,b,l]"
        end
      end
      alias_method :border_widths=, :border_width=

      def border_top_width
        @borders.include?(:top) ? @border_widths[0] : 0
      end

      def border_top_width=(val)
        @border_widths[0] = val
      end

      def border_right_width
        @borders.include?(:right) ? @border_widths[1] : 0
      end

      def border_right_width=(val)
        @border_widths[1] = val
      end

      def border_bottom_width
        @borders.include?(:bottom) ? @border_widths[2] : 0
      end

      def border_bottom_width=(val)
        @border_widths[2] = val
      end

      def border_left_width
        @borders.include?(:left) ? @border_widths[3] : 0
      end

      def border_left_width=(val)
        @border_widths[3] = val
      end

      # Sets the cell's minimum and maximum width. Deferred until requested
      # because padding and size can change.
      #
      def set_width_constraints
        @min_width ||= padding_left + padding_right
        @max_width ||= @pdf.bounds.width
      end

      # Sets border line style on this cell. The argument can be one of:
      #
      # Possible values are: :solid, :dashed, :dotted
      #
      # * one value (sets all lines)
      # * a two-element array [vertical, horizontal]
      # * a three-element array [top, horizontal, bottom]
      # * a four-element array [top, right, bottom, left]
      #
      def border_line=(line)
        @border_lines = case
        when line.nil?
          [:solid] * 4
        when line.length == 1 # all lines
          [line[0]] * 4
        when line.length == 2
          [line[0], line[1], line[0], line[1]]
        when line.length == 3
          [line[0], line[1], line[2], line[1]]
        when line.length == 4
          [line[0], line[1], line[2], line[3]]
        else
          raise ArgumentError, "border_line must be one of :solid, :dashed, "
            ":dotted or an array [v,h] or [t,r,b,l]"
        end
      end
      alias_method :border_lines=, :border_line=

      def border_top_line
        @borders.include?(:top) ? @border_lines[0] : 0
      end

      def border_top_line=(val)
        @border_lines[0] = val
      end

      def border_right_line
        @borders.include?(:right) ? @border_lines[1] : 0
      end

      def border_right_line=(val)
        @border_lines[1] = val
      end

      def border_bottom_line
        @borders.include?(:bottom) ? @border_lines[2] : 0
      end

      def border_bottom_line=(val)
        @border_lines[2] = val
      end

      def border_left_line
        @borders.include?(:left) ? @border_lines[3] : 0
      end

      def border_left_line=(val)
        @border_lines[3] = val
      end

      # Draws the cell's background color.
      #
      def draw_background(pt)
        return unless background_color

        @pdf.mask(:fill_color) do
          @pdf.fill_color background_color
          @pdf.fill_rectangle pt, width, height
        end
      end

      # Draws borders around the cell. Borders are centered on the bounds of
      # the cell outside of any padding, so the caller is responsible for
      # setting appropriate padding to ensure the border does not overlap with
      # cell content.
      #
      def draw_borders(pt)
        x, y = pt

        @pdf.mask(:line_width, :stroke_color) do
          @borders.each do |border|
            idx = {:top => 0, :right => 1, :bottom => 2, :left => 3}[border]
            border_color = @border_colors[idx]
            border_width = @border_widths[idx]
            border_line  = @border_lines[idx]

            next if border_width <= 0

            # Left and right borders are drawn one-half border beyond the center
            # of the corner, so that the corners end up square.
            from, to = case border
                       when :top
                         [[x, y], [x+width, y]]
                       when :bottom
                         [[x, y-height], [x+width, y-height]]
                       when :left
                         [[x, y + (border_top_width / 2.0)],
                          [x, y - height - (border_bottom_width / 2.0)]]
                       when :right
                         [[x+width, y + (border_top_width / 2.0)],
                          [x+width, y - height - (border_bottom_width / 2.0)]]
                       end

            case border_line
            when :dashed
              @pdf.dash border_width * 4
            when :dotted
              @pdf.dash border_width, :space => border_width * 2
            when :solid
              # normal line style
            else
              raise ArgumentError, "border_line must be :solid, :dotted or" +
                " :dashed"
            end

            @pdf.line_width   = border_width
            @pdf.stroke_color = border_color
            @pdf.stroke_line(from, to)
            @pdf.undash
          end
        end
      end

      # Draws cell content within the cell's bounding box. Must be implemented
      # in subclasses.
      #
      def draw_content
        raise NotImplementedError, "subclasses must implement draw_content"
      end

    end
  end
end
