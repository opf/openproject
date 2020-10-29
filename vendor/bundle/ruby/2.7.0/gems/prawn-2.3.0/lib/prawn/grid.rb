# frozen_string_literal: true

# grid.rb: Provides a basic grid layout system for Prawn
#
# Contributed by Andrew O'Brien in March 2009
#
# This is free software. Please see the LICENSE and COPYING files for details.

module Prawn
  class Document
    # @group Experimental API

    # Defines the grid system for a particular document.  Takes the number of
    # rows and columns and the width to use for the gutter as the
    # keys :rows, :columns, :gutter, :row_gutter, :column_gutter
    #
    # Note that a completely new grid object is built each time define_grid()
    # is called. This means that all subsequent calls to grid() will use
    # the newly defined Grid object -- grids are not nestable like
    # bounding boxes are.

    def define_grid(options = {})
      @boxes = nil
      @grid = Grid.new(self, options)
    end

    # A method that can either be used to access a particular grid on the page
    # or work with the grid system directly.
    #
    #   @pdf.grid                 # Get the Grid directly
    #   @pdf.grid([0,1])          # Get the GridBox at [0,1]
    #   @pdf.grid([0,1], [1,2])   # Get a multi-box spanning from [0,1] to [1,2]
    #
    def grid(*args)
      @boxes ||= {}
      @boxes[args] ||=
        begin
          if args.empty?
            @grid
          else
            g1, g2 = args

            if g1.is_a?(Array) && g2.is_a?(Array) &&
                g1.length == 2 && g2.length == 2
              multi_box(single_box(*g1), single_box(*g2))
            else
              single_box(g1, g2)
            end
          end
        end
    end

    # A Grid represents the entire grid system of a Page and calculates
    # the column width and row height of the base box.
    #
    # @group Experimental API
    class Grid
      attr_reader :pdf, :columns, :rows, :gutter, :row_gutter, :column_gutter
      def initialize(pdf, options = {}) # :nodoc:
        valid_options = %i[columns rows gutter row_gutter column_gutter]
        Prawn.verify_options valid_options, options

        @pdf = pdf
        @columns = options[:columns]
        @rows = options[:rows]
        apply_gutter(options)
      end

      # Calculates the base width of boxes.
      def column_width
        @column_width ||= subdivide(pdf.bounds.width, columns, column_gutter)
      end

      # Calculates the base height of boxes.
      def row_height
        @row_height ||= subdivide(pdf.bounds.height, rows, row_gutter)
      end

      # Diagnostic tool to show all of the grids.  Defaults to gray.
      def show_all(color = 'CCCCCC')
        rows.times do |row|
          columns.times do |column|
            pdf.grid(row, column).show(color)
          end
        end
      end

      private

      def subdivide(total, num, gutter)
        (total.to_f - (gutter * (num - 1).to_f)) / num.to_f
      end

      def apply_gutter(options)
        if options.key?(:gutter)
          @gutter = options[:gutter].to_f
          @row_gutter = @gutter
          @column_gutter = @gutter
        else
          @row_gutter = options[:row_gutter].to_f
          @column_gutter = options[:column_gutter].to_f
          @gutter = 0
        end
      end
    end

    # A Box is a class that represents a bounded area of a page.
    # A Grid object has methods that allow easy access to the coordinates of
    # its corners, which can be plugged into most existing prawnmethods.
    #
    # @group Experimental API
    class GridBox
      attr_reader :pdf

      def initialize(pdf, rows, columns)
        @pdf = pdf
        @rows = rows
        @columns = columns
      end

      # Mostly diagnostic method that outputs the name of a box as
      # col_num, row_num
      #
      def name
        "#{@rows},#{@columns}"
      end

      # :nodoc
      def total_height
        pdf.bounds.height.to_f
      end

      # Width of a box
      def width
        grid.column_width.to_f
      end

      # Height of a box
      def height
        grid.row_height.to_f
      end

      # Width of the gutter
      def gutter
        grid.gutter.to_f
      end

      # x-coordinate of left side
      def left
        @left ||= (width + grid.column_gutter) * @columns.to_f
      end

      # x-coordinate of right side
      def right
        @right ||= left + width
      end

      # y-coordinate of the top
      def top
        @top ||= total_height - ((height + grid.row_gutter) * @rows.to_f)
      end

      # y-coordinate of the bottom
      def bottom
        @bottom ||= top - height
      end

      # x,y coordinates of top left corner
      def top_left
        [left, top]
      end

      # x,y coordinates of top right corner
      def top_right
        [right, top]
      end

      # x,y coordinates of bottom left corner
      def bottom_left
        [left, bottom]
      end

      # x,y coordinates of bottom right corner
      def bottom_right
        [right, bottom]
      end

      # Creates a standard bounding box based on the grid box.
      def bounding_box(&blk)
        pdf.bounding_box(top_left, width: width, height: height, &blk)
      end

      # Diagnostic method
      def show(grid_color = 'CCCCCC')
        bounding_box do
          original_stroke_color = pdf.stroke_color

          pdf.stroke_color = grid_color
          pdf.text name
          pdf.stroke_bounds

          pdf.stroke_color = original_stroke_color
        end
      end

      private

      def grid
        pdf.grid
      end
    end

    # A MultiBox is specified by 2 Boxes and spans the areas between.
    #
    # @group Experimental API
    class MultiBox < GridBox
      def initialize(pdf, box1, box2)
        @pdf = pdf
        @boxes = [box1, box2]
      end

      def name
        @boxes.map(&:name).join(':')
      end

      def total_height
        @boxes[0].total_height
      end

      def width
        right_box.right - left_box.left
      end

      def height
        top_box.top - bottom_box.bottom
      end

      def gutter
        @boxes[0].gutter
      end

      def left
        left_box.left
      end

      def right
        right_box.right
      end

      def top
        top_box.top
      end

      def bottom
        bottom_box.bottom
      end

      private

      def left_box
        @left_box ||= @boxes.min_by(&:left)
      end

      def right_box
        @right_box ||= @boxes.max_by(&:right)
      end

      def top_box
        @top_box ||= @boxes.max_by(&:top)
      end

      def bottom_box
        @bottom_box ||= @boxes.min_by(&:bottom)
      end
    end

    private

    def single_box(rows, columns)
      GridBox.new(self, rows, columns)
    end

    def multi_box(box1, box2)
      MultiBox.new(self, box1, box2)
    end
  end
end
