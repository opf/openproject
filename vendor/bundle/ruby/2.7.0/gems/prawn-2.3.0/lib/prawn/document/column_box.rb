# frozen_string_literal: true

# column_box.rb: Extends BoundingBox to allow for columns of text
#
# Author Paul Ostazeski.
#
# This is free software. Please see the LICENSE and COPYING files for details.

require_relative 'bounding_box'

module Prawn
  class Document
    # @group Experimental API

    # A column box is a bounding box with the additional property that when
    # text flows past the bottom, it will wrap first to another column on the
    # same page, and only flow to the next page when all the columns are
    # filled.
    #
    # column_box accepts the same parameters as bounding_box, as well as the
    # number of :columns and a :spacer (in points) between columns. If resetting
    # the top margin is desired on a new page (e.g. to allow for initial page
    # wide column titles) the option :reflow_margins => true can be set.
    #
    # Defaults are :columns = 3, :spacer = font_size, and
    # :reflow_margins => false
    #
    # Under PDF::Writer, "spacer" was known as "gutter"
    #
    def column_box(*args, &block)
      init_column_box(block) do |parent_box|
        map_to_absolute!(args[0])
        @bounding_box = ColumnBox.new(self, parent_box, *args)
      end
    end

    private

    def init_column_box(user_block, options = {})
      parent_box = @bounding_box

      yield(parent_box)

      self.y = @bounding_box.absolute_top
      user_block.call
      self.y = @bounding_box.absolute_bottom unless options[:hold_position]

      @bounding_box = parent_box
    end

    # Implements the necessary functionality to allow Document#column_box to
    # work.
    #
    class ColumnBox < BoundingBox
      def initialize(document, parent, point, options = {}) #:nodoc:
        super
        @columns = options[:columns] || 3
        @spacer = options[:spacer] || @document.font_size
        @current_column = 0
        @reflow_margins = options[:reflow_margins]
      end

      # The column width, not the width of the whole box,
      # before left and/or right padding
      def bare_column_width
        (@width - @spacer * (@columns - 1)) / @columns
      end

      # The column width after padding.
      # Used to calculate how long a line of text can be.
      #
      def width
        bare_column_width - (@total_left_padding + @total_right_padding)
      end

      # Column width including the spacer.
      #
      def width_of_column
        bare_column_width + @spacer
      end

      # x coordinate of the left edge of the current column
      #
      def left_side
        absolute_left + (width_of_column * @current_column)
      end

      # Relative position of the left edge of the current column
      #
      def left
        width_of_column * @current_column
      end

      # x co-orordinate of the right edge of the current column
      #
      def right_side
        columns_from_right = @columns - (1 + @current_column)
        absolute_right - (width_of_column * columns_from_right)
      end

      # Relative position of the right edge of the current column.
      #
      def right
        left + width
      end

      # Moves to the next column or starts a new page if currently positioned at
      # the rightmost column.
      def move_past_bottom
        @current_column = (@current_column + 1) % @columns
        @document.y = @y
        if @current_column.zero?
          if @reflow_margins
            @y = @parent.absolute_top
          end
          @document.start_new_page
        end
      end

      # Override the padding functions so as not to split the padding amount
      # between all columns on the page.

      def add_left_padding(left_padding)
        @total_left_padding += left_padding
        @x += left_padding
      end

      def subtract_left_padding(left_padding)
        @total_left_padding -= left_padding
        @x -= left_padding
      end

      def add_right_padding(right_padding)
        @total_right_padding += right_padding
      end

      def subtract_right_padding(right_padding)
        @total_right_padding -= right_padding
      end
    end
  end
end
