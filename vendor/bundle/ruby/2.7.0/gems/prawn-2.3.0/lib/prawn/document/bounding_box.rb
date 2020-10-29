# frozen_string_literal: true

# bounding_box.rb : Implements a mechanism for shifting the coordinate space
#
# Copyright May 2008, Gregory Brown. All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.

module Prawn
  class Document
    # @group Stable API

    # :call-seq:
    #   bounding_box(point, options={}, &block)
    #
    # A bounding box serves two important purposes:
    # * Provide bounds for flowing text, starting at a given point
    # * Translate the origin (0,0) for graphics primitives
    #
    # A point and :width must be provided. :height is optional.
    # (See stretchyness below)
    #
    # ==Positioning
    #
    # Bounding boxes are positioned relative to their top left corner and
    # the width measurement is towards the right and height measurement is
    # downwards.
    #
    # Usage:
    #
    # * Bounding box 100pt x 100pt in the absolute bottom left of the
    #   containing box:
    #
    #   pdf.bounding_box([0,100], :width => 100, :height => 100)
    #     stroke_bounds
    #   end
    #
    # * Bounding box 200pt x 400pt high in the center of the page:
    #
    #   x_pos = ((bounds.width / 2) - 150)
    #   y_pos = ((bounds.height / 2) + 200)
    #   pdf.bounding_box([x_pos, y_pos], :width => 300, :height => 400) do
    #     stroke_bounds
    #   end
    #
    # ==Flowing Text
    #
    # When flowing text, the usage of a bounding box is simple. Text will
    # begin at the point specified, flowing the width of the bounding box.
    # After the block exits, the cursor position will be moved to
    # the bottom of the bounding box (y - height). If flowing text exceeds
    # the height of the bounding box, the text will be continued on the next
    # page, starting again at the top-left corner of the bounding box.
    #
    # Usage:
    #
    #   pdf.bounding_box([100,500], :width => 100, :height => 300) do
    #     pdf.text "This text will flow in a very narrow box starting" +
    #      "from [100,500]. The pointer will then be moved to [100,200]" +
    #      "and return to the margin_box"
    #   end
    #
    # Note, this is a low level tool and is designed primarily for building
    # other abstractions.  If you just need to flow text on the page, you
    # will want to look at span() and text_box() instead
    #
    # ==Translating Coordinates
    #
    # When translating coordinates, the idea is to allow the user to draw
    # relative to the origin, and then translate their drawing to a specified
    # area of the document, rather than adjust all their drawing coordinates
    # to match this new region.
    #
    # Take for example two triangles which share one point, drawn from the
    # origin:
    #
    #   pdf.polygon [0,250], [0,0], [150,100]
    #   pdf.polygon [100,0], [150,100], [200,0]
    #
    # It would be easy enough to translate these triangles to another point,
    # e.g [200,200]
    #
    #   pdf.polygon [200,450], [200,200], [350,300]
    #   pdf.polygon [300,200], [350,300], [400,200]
    #
    # However, each time you want to move the drawing, you'd need to alter
    # every point in the drawing calls, which as you might imagine, can become
    # tedious.
    #
    # If instead, we think of the drawing as being bounded by a box, we can
    # see that the image is 200 points wide by 250 points tall.
    #
    # To translate it to a new origin, we simply select a point at (x,y+height)
    #
    # Using the [200,200] example:
    #
    #   pdf.bounding_box([200,450], :width => 200, :height => 250) do
    #     pdf.stroke do
    #       pdf.polygon [0,250], [0,0], [150,100]
    #       pdf.polygon [100,0], [150,100], [200,0]
    #     end
    #   end
    #
    # Notice that the drawing is still relative to the origin. If we want to
    # move this drawing around the document, we simply need to recalculate the
    # top-left corner of the rectangular bounding-box, and all of our graphics
    # calls remain unmodified.
    #
    # ==Nesting Bounding Boxes
    #
    # At the top level, bounding boxes are specified relative to the document's
    # margin_box (which is itself a bounding box).  You can also nest bounding
    # boxes, allowing you to build components which are relative to each other
    #
    # Usage:
    #
    #  pdf.bounding_box([200,450], :width => 200, :height => 250) do
    #    pdf.stroke_bounds   # Show the containing bounding box
    #    pdf.bounding_box([50,200], :width => 50, :height => 50) do
    #      # a 50x50 bounding box that starts 50 pixels left and 50 pixels down
    #      # the parent bounding box.
    #      pdf.stroke_bounds
    #    end
    #  end
    #
    # ==Stretchyness
    #
    # If you do not specify a height to a bounding box, it will become stretchy
    # and its height will be calculated automatically as you stretch the box
    # downwards.
    #
    #  pdf.bounding_box([100,400], :width => 400) do
    #    pdf.text("The height of this box is #{pdf.bounds.height}")
    #    pdf.text('this is some text')
    #    pdf.text('this is some more text')
    #    pdf.text('and finally a bit more')
    #    pdf.text("Now the height of this box is #{pdf.bounds.height}")
    #  end
    #
    # ==Absolute Positioning
    #
    # If you wish to position the bounding boxes at absolute coordinates rather
    # than relative to the margins or other bounding boxes, you can use canvas()
    #
    #  pdf.bounding_box([50,500], :width => 200, :height => 300) do
    #    pdf.stroke_bounds
    #    pdf.canvas do
    #      Positioned outside the containing box at the 'real' (300,450)
    #      pdf.bounding_box([300,450], :width => 200, :height => 200) do
    #        pdf.stroke_bounds
    #      end
    #    end
    #  end
    #
    # Of course, if you use canvas, you will be responsible for ensuring that
    # you remain within the printable area of your document.
    #
    def bounding_box(point, *args, &block)
      init_bounding_box(block) do |parent_box|
        point = map_to_absolute(point)
        @bounding_box = BoundingBox.new(self, parent_box, point, *args)
      end
    end

    # A shortcut to produce a bounding box which is mapped to the document's
    # absolute coordinates, regardless of how things are nested or margin sizes.
    #
    #   pdf.canvas do
    #     pdf.line pdf.bounds.bottom_left, pdf.bounds.top_right
    #   end
    #
    def canvas(&block)
      init_bounding_box(block, hold_position: true) do |_|
        # Canvas bbox acts like margin_box in that its parent bounds are unset.
        @bounding_box = BoundingBox.new(
          self, nil, [0, page.dimensions[3]],
          width: page.dimensions[2],
          height: page.dimensions[3]
        )
      end
    end

    private

    def init_bounding_box(user_block, options = {})
      unless user_block
        raise ArgumentError,
          'bounding boxes require a block to be drawn within the box'
      end

      parent_box = @bounding_box

      original_ypos = y

      yield(parent_box)

      self.y = @bounding_box.absolute_top
      user_block.call

      # If the user actions did not modify the y position
      # restore the original y position before the bounding
      # box was created.

      if y == @bounding_box.absolute_top
        self.y = original_ypos
      end

      unless options[:hold_position] || @bounding_box.stretchy?
        self.y = @bounding_box.absolute_bottom
      end

      created_box = @bounding_box
      @bounding_box = parent_box

      created_box
    end

    # Low level layout helper that simplifies coordinate math.
    #
    # See Prawn::Document#bounding_box for a description of what this class
    # is used for.
    #
    class BoundingBox
      # @private
      def initialize(document, parent, point, options = {})
        unless options[:width]
          raise ArgumentError, 'BoundingBox needs the :width option to be set'
        end

        @document = document
        @parent = parent
        @x, @y = point
        @width = options[:width]
        @height = options[:height]
        @total_left_padding = 0
        @total_right_padding = 0
        @stretched_height = nil
      end

      # @private

      attr_reader :document, :parent

      # @private
      # The current indentation of the left side of the bounding box.
      attr_reader :total_left_padding

      # @private
      # The current indentation of the right side of the bounding box.
      attr_reader :total_right_padding

      # The translated origin (x,y-height) which describes the location
      # of the bottom left corner of the bounding box
      #
      # @private
      def anchor
        [@x, @y - height]
      end

      # Relative left x-coordinate of the bounding box. (Always 0)
      #
      # Example, position some text 3 pts from the left of the containing box:
      #
      #  draw_text('hello', :at => [(bounds.left + 3), 0])
      #
      def left
        0
      end

      # Temporarily adjust the @x coordinate to allow for left_padding
      #
      # Example:
      #
      #  indent 20 do
      #     text "20 points in"
      #     indent 30 do
      #       text "50 points in"
      #     end
      #   end
      #
      #  indent 20, 20 do
      #    text "indented on both sides"
      #  end
      #
      # @private
      def indent(left_padding, right_padding = 0)
        add_left_padding(left_padding)
        add_right_padding(right_padding)
        yield
      ensure
        @document.bounds.subtract_left_padding(left_padding)
        @document.bounds.subtract_right_padding(right_padding)
      end

      # Increase the left padding of the bounding box.
      # @private
      def add_left_padding(left_padding)
        @total_left_padding += left_padding
        @x += left_padding
        @width -= left_padding
      end

      # Decrease the left padding of the bounding box.
      # @private
      def subtract_left_padding(left_padding)
        @total_left_padding -= left_padding
        @x -= left_padding
        @width += left_padding
      end

      # Increase the right padding of the bounding box.
      # @private
      def add_right_padding(right_padding)
        @total_right_padding += right_padding
        @width -= right_padding
      end

      # Decrease the right padding of the bounding box.
      # @private
      def subtract_right_padding(right_padding)
        @total_right_padding -= right_padding
        @width += right_padding
      end

      # Relative right x-coordinate of the bounding box. (Equal to the box
      # width)
      #
      # Example, position some text 3 pts from the right of the containing box:
      #
      #  draw_text('hello', :at => [(bounds.right - 3), 0])
      #
      def right
        @width
      end

      # Relative top y-coordinate of the bounding box. (Equal to the box height)
      #
      # Example, position some text 3 pts from the top of the containing box:
      #
      #  draw_text('hello', :at => [0, (bounds.top - 3)])
      #
      def top
        height
      end

      # Relative bottom y-coordinate of the bounding box (Always 0)
      #
      # Example, position some text 3 pts from the bottom of the containing box:
      #
      #  draw_text('hello', :at => [0, (bounds.bottom + 3)])
      #
      def bottom
        0
      end

      # Relative top-left point of the bounding_box
      #
      # Example, draw a line from the top left of the box diagonally to the
      # bottom right:
      #
      #  stroke do
      #    line(bounds.top_left, bounds.bottom_right)
      #  end
      #
      def top_left
        [left, top]
      end

      # Relative top-right point of the bounding box
      #
      # Example, draw a line from the top_right of the box diagonally to the
      # bottom left:
      #
      #  stroke do
      #    line(bounds.top_right, bounds.bottom_left)
      #  end
      #
      def top_right
        [right, top]
      end

      # Relative bottom-right point of the bounding box
      #
      # Example, draw a line along the right hand side of the page:
      #
      #  stroke do
      #    line(bounds.bottom_right, bounds.top_right)
      #  end
      #
      def bottom_right
        [right, bottom]
      end

      # Relative bottom-left point of the bounding box
      #
      # Example, draw a line along the left hand side of the page:
      #
      #  stroke do
      #    line(bounds.bottom_left, bounds.top_left)
      #  end
      #
      def bottom_left
        [left, bottom]
      end

      # Absolute left x-coordinate of the bounding box
      #
      def absolute_left
        @x
      end

      # Absolute right x-coordinate of the bounding box
      #
      def absolute_right
        @x + width
      end

      # Absolute top y-coordinate of the bounding box
      #
      def absolute_top
        @y
      end

      # Absolute bottom y-coordinate of the bottom box
      #
      def absolute_bottom
        @y - height
      end

      # Absolute top-left point of the bounding box
      #
      def absolute_top_left
        [absolute_left, absolute_top]
      end

      # Absolute top-right point of the bounding box
      #
      def absolute_top_right
        [absolute_right, absolute_top]
      end

      # Absolute bottom-left point of the bounding box
      #
      def absolute_bottom_left
        [absolute_left, absolute_bottom]
      end

      # Absolute bottom-left point of the bounding box
      #
      def absolute_bottom_right
        [absolute_right, absolute_bottom]
      end

      # Width of the bounding box
      attr_reader :width

      # Height of the bounding box.  If the box is 'stretchy' (unspecified
      # height attribute), height is calculated as the distance from the top of
      # the box to the current drawing position.
      #
      def height
        return @height if @height

        @stretched_height = [
          (absolute_top - @document.y),
          @stretched_height.to_f
        ].max
      end

      # an alias for absolute_left
      # @private
      def left_side
        absolute_left
      end

      # an alias for absolute_right
      # @private
      def right_side
        absolute_right
      end

      # @group Extension API

      # Moves to the top of the next page of the document, starting a new page
      # if necessary.
      #
      def move_past_bottom
        if @document.page_number == @document.page_count
          @document.start_new_page
        else
          @document.go_to_page(@document.page_number + 1)
        end
      end

      # Returns +false+ when the box has a defined height, +true+ when the
      # height is being calculated on the fly based on the current vertical
      # position.
      #
      def stretchy?
        !@height
      end

      # Returns the innermost non-stretchy bounding box.
      #
      def reference_bounds
        if stretchy?
          raise "Can't find reference bounds: my parent is unset" unless @parent

          @parent.reference_bounds
        else
          self
        end
      end

      alias update_height height

      # Returns a deep copy of these bounds (including all parent bounds but
      # not copying the reference to the Document).
      #
      # @private
      def deep_copy
        copy = dup
        # Deep-copy the parent bounds
        copy.instance_variable_set(
          '@parent',
          if @parent.is_a?(BoundingBox)
            @parent.deep_copy
          end
        )
        copy.instance_variable_set('@document', nil)
        copy
      end

      # Restores a copy of the bounds taken by BoundingBox.deep_copy in the
      # context of the given +document+. Does *not* set the bounds of the
      # document to the resulting BoundingBox, only returns it.
      #
      # @private
      def self.restore_deep_copy(bounds, document)
        bounds.instance_variable_set('@document', document)
        bounds
      end
    end
  end
end
