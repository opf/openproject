# frozen_string_literal: true

# transformation.rb: Implements rotate, translate, skew, scale and a generic
#                     transformation_matrix
#
# Copyright January 2010, Michael Witrant. All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.

module Prawn
  module Graphics
    module Transformation
      # @group Stable API

      # Rotate the user space.  If a block is not provided, then you must save
      # and restore the graphics state yourself.
      #
      # == Options
      # <tt>:origin</tt>:: <tt>[number, number]</tt>. The point around which to
      #                    rotate. A block must be provided if using the :origin
      #
      # raises <tt>Prawn::Errors::BlockRequired</tt> if an :origin option is
      # provided, but no block is given
      #
      # Example without a block:
      #
      #   save_graphics_state
      #   rotate 30
      #   text "rotated text"
      #   restore_graphics_state
      #
      # Example with a block: rotating a rectangle around its upper-left corner
      #
      #   x = 300
      #   y = 300
      #   width = 150
      #   height = 200
      #   angle = 30
      #   pdf.rotate(angle, :origin => [x, y]) do
      #     pdf.stroke_rectangle([x, y], width, height)
      #   end
      #
      def rotate(angle, options = {}, &block)
        Prawn.verify_options(:origin, options)
        rad = degree_to_rad(angle)
        cos = Math.cos(rad)
        sin = Math.sin(rad)
        if options[:origin].nil?
          transformation_matrix(cos, sin, -sin, cos, 0, 0, &block)
        else
          raise Prawn::Errors::BlockRequired unless block_given?

          x = options[:origin][0] + bounds.absolute_left
          y = options[:origin][1] + bounds.absolute_bottom
          x_prime = x * cos - y * sin
          y_prime = x * sin + y * cos
          translate(x - x_prime, y - y_prime) do
            transformation_matrix(cos, sin, -sin, cos, 0, 0, &block)
          end
        end
      end

      # Translate the user space.  If a block is not provided, then you must
      # save and restore the graphics state yourself.
      #
      # Example without a block: move the text up and over 10
      #
      #   save_graphics_state
      #   translate(10, 10)
      #   text "scaled text"
      #   restore_graphics_state
      #
      # Example with a block: draw a rectangle with its upper-left corner at
      #                       x + 10, y + 10
      #
      #   x = 300
      #   y = 300
      #   width = 150
      #   height = 200
      #   pdf.translate(10, 10) do
      #     pdf.stroke_rectangle([x, y], width, height)
      #   end
      #
      def translate(x, y, &block)
        transformation_matrix(1, 0, 0, 1, x, y, &block)
      end

      # Scale the user space.  If a block is not provided, then you must save
      # and restore the graphics state yourself.
      #
      # == Options
      # <tt>:origin</tt>:: <tt>[number, number]</tt>. The point from which to
      #                    scale. A block must be provided if using the :origin
      #
      # raises <tt>Prawn::Errors::BlockRequired</tt> if an :origin option is
      # provided, but no block is given
      #
      # Example without a block:
      #
      #   save_graphics_state
      #   scale 1.5
      #   text "scaled text"
      #   restore_graphics_state
      #
      # Example with a block: scale a rectangle from its upper-left corner
      #
      #   x = 300
      #   y = 300
      #   width = 150
      #   height = 200
      #   factor = 1.5
      #   pdf.scale(angle, :origin => [x, y]) do
      #     pdf.stroke_rectangle([x, y], width, height)
      #   end
      #
      def scale(factor, options = {}, &block)
        Prawn.verify_options(:origin, options)
        if options[:origin].nil?
          transformation_matrix(factor, 0, 0, factor, 0, 0, &block)
        else
          raise Prawn::Errors::BlockRequired unless block_given?

          x = options[:origin][0] + bounds.absolute_left
          y = options[:origin][1] + bounds.absolute_bottom
          x_prime = factor * x
          y_prime = factor * y
          translate(x - x_prime, y - y_prime) do
            transformation_matrix(factor, 0, 0, factor, 0, 0, &block)
          end
        end
      end

      # The following definition of skew would only work in a clearly
      # predicatable manner when if the document had no margin. don't provide
      # this shortcut until it behaves in a clearly understood manner
      #
      # def skew(a, b, &block)
      #   transformation_matrix(1,
      #                         Math.tan(degree_to_rad(a)),
      #                         Math.tan(degree_to_rad(b)),
      #                         1, 0, 0, &block)
      # end

      # Transform the user space (see notes for rotate regarding graphics state)
      # Generally, one would use the rotate, scale, translate, and skew
      # convenience methods instead of calling transformation_matrix directly
      def transformation_matrix(*matrix)
        if matrix.length != 6
          raise ArgumentError,
            'Transformation matrix must have exacty 6 elements'
        end
        values = matrix.map { |x| x.to_f.round(5) }.join(' ')
        save_graphics_state if block_given?

        add_to_transformation_stack(*matrix)

        renderer.add_content "#{values} cm"
        if block_given?
          yield
          restore_graphics_state
        end
      end
    end
  end
end
