# encoding: utf-8

# subtable.rb: Yo dawg.
#
# Copyright January 2010, Brad Ediger. All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.
module Prawn
  class Table
    class Cell

      # A Cell that contains another table.
      #
      # @private
      class Subtable < Cell

        attr_reader :subtable

        def initialize(pdf, point, options={})
          super
          @subtable = options[:content]

          # Subtable padding defaults to zero
          @padding = [0, 0, 0, 0]
        end

        # Sets the text color of the entire subtable.
        #
        def text_color=(color)
          @subtable.cells.text_color = color
        end

        # Proxied to subtable.
        #
        def natural_content_width
          @subtable.cells.width
        end

        # Proxied to subtable.
        #
        def min_width
          @subtable.cells.min_width
        end

        # Proxied to subtable.
        #
        def max_width
          @subtable.cells.max_width
        end

        # Proxied to subtable.
        #
        def natural_content_height
          @subtable.cells.height
        end

        # Draws the subtable.
        #
        def draw_content
          @subtable.draw
        end

      end
    end
  end
end
