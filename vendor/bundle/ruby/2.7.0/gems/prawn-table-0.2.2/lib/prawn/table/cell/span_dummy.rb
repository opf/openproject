# encoding: utf-8

# span_dummy.rb: Placeholder for non-master spanned cells.
#
# Copyright December 2011, Brad Ediger. All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.
module Prawn
  class Table
    class Cell

      # A Cell object used to represent all but the topmost cell in a span
      # group.
      #
      # @private
      class SpanDummy < Cell
        def initialize(pdf, master_cell)
          super(pdf, [0, pdf.cursor])
          @master_cell = master_cell
          @padding = [0, 0, 0, 0]
        end

        # By default, a span dummy will never increase the height demand.
        #
        def natural_content_height
          0
        end

        # By default, a span dummy will never increase the width demand.
        #
        def natural_content_width
          0
        end

        def avg_spanned_min_width
          @master_cell.avg_spanned_min_width
        end

        # Dummy cells have nothing to draw.
        #
        def draw_borders(pt)
        end

        # Dummy cells have nothing to draw.
        #
        def draw_bounded_content(pt)
        end

        def padding_right=(val)
          @master_cell.padding_right = val if rightmost?
        end

        def padding_bottom=(val)
          @master_cell.padding_bottom = val if bottommost?
        end

        def border_right_color=(val)
          @master_cell.border_right_color = val if rightmost?
        end

        def border_bottom_color=(val)
          @master_cell.border_bottom_color = val if bottommost?
        end

        def border_right_width=(val)
          @master_cell.border_right_width = val if rightmost?
        end

        def border_bottom_width=(val)
          @master_cell.border_bottom_width = val if bottommost?
        end

        def background_color
          @master_cell.background_color
        end

        private

        # Are we on the right border of the span?
        #
        def rightmost?
          @column == @master_cell.column + @master_cell.colspan - 1
        end

        # Are we on the bottom border of the span?
        #
        def bottommost?
          @row == @master_cell.row + @master_cell.rowspan - 1
        end
      end
    end
  end
end
