# frozen_string_literal: true

require 'digest/sha1'

# patterns.rb : Implements axial & radial gradients
#
# Originally implemented by Wojciech Piekutowski. November, 2009
# Copyright September 2012, Alexander Mankuta. All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.
#
module Prawn
  module Graphics
    module Patterns
      GradientStop = Struct.new(:position, :color)
      Gradient = Struct.new(
        :type, :apply_transformations, :stops, :from, :to, :r1, :r2
      )

      # @group Stable API

      # Sets the fill gradient.
      # old arguments:
      #   from, to, color1, color2
      #   or
      #   from, r1, to, r2, color1, color2
      # new arguments:
      #    from: [x, y]
      #    to: [x, y]
      #    r1: radius
      #    r2: radius
      #    stops: [color, color, ...] or
      #           { position => color, position => color, ... }
      #    apply_transformations: true
      #
      # Examples:
      #
      #     # draws a horizontal axial gradient that starts at red on the left
      #     # and ends at blue on the right
      #     fill_gradient from: [0, 0], to: [100, 0], stops: ['red', 'blue']
      #
      #     # draws a horizontal radial gradient that starts at red, is green
      #     # 80% of the way through, and finishes blue
      #     fill_gradient from: [0, 0], r1: 0, to: [100, 0], r2: 180,
      #       stops: { 0 => 'red', 0.8 => 'green', 1 => 'blue' }
      #
      # <tt>from</tt> and <tt>to</tt> specify the axis of where the gradient
      # should be painted.
      #
      # <tt>r1</tt> and <tt>r2</tt>, if specified, make a radial gradient with
      # the starting circle of radius <tt>r1</tt> centered at <tt>from</tt>
      # and ending at a circle of radius <tt>r2</tt> centered at <tt>to</tt>.
      # If <tt>r1</tt> is not specified, a axial gradient will be drawn.
      #
      # <tt>stops</tt> is an array or hash of stops.  Each stop is either just a
      # string indicating the color, in which case the stops will be evenly
      # distributed across the gradient, or a hash where the key is
      # a position between 0 and 1 indicating what distance through the
      # gradient the color should change, and the value is a color string.
      #
      # Option <tt>apply_transformations</tt>, if set true, will transform the
      # gradient's co-ordinate space so it matches the current co-ordinate
      # space of the document.  This option will be the default from Prawn v3,
      # and is default true if you use the new arguments format.
      # The default for the old arguments format, false, will mean if you
      # (for example) scale your document by 2 and put a gradient inside, you
      # will have to manually multiply your co-ordinates by 2 so the gradient
      # is correctly positioned.
      def fill_gradient(*args, **kwargs)
        set_gradient(:fill, *args, **kwargs)
      end

      # Sets the stroke gradient.
      # See fill_gradient for a description of the arguments to this method.
      def stroke_gradient(*args, **kwargs)
        set_gradient(:stroke, *args, **kwargs)
      end

      private

      def set_gradient(type, *grad, **kwargs)
        gradient = parse_gradient_arguments(*grad, **kwargs)

        patterns = page.resources[:Pattern] ||= {}

        registry_key = gradient_registry_key gradient

        unless patterns.key? "SP#{registry_key}"
          shading = gradient_registry[registry_key]
          unless shading
            shading = create_gradient_pattern(gradient)
            gradient_registry[registry_key] = shading
          end

          patterns["SP#{registry_key}"] = shading
        end

        operator = case type
                   when :fill
                     'scn'
                   when :stroke
                     'SCN'
                   else
                     raise ArgumentError, "unknown type '#{type}'"
                   end

        set_color_space type, :Pattern
        renderer.add_content "/SP#{registry_key} #{operator}"
      end

      # rubocop: disable Metrics/ParameterLists
      def parse_gradient_arguments(
        *arguments, from: nil, to: nil, r1: nil, r2: nil, stops: nil,
        apply_transformations: nil
      )
        case arguments.length
        when 0
          apply_transformations = true if apply_transformations.nil?
        when 4
          from, to, *stops = arguments
        when 6
          from, r1, to, r2, *stops = arguments
        else
          raise ArgumentError, "Unknown type of gradient: #{arguments.inspect}"
        end

        if stops.length < 2
          raise ArgumentError, 'At least two stops must be specified'
        end

        stops = stops.map.with_index do |stop, index|
          case stop
          when Array, Hash
            position, color = stop
          else
            position = index / (stops.length.to_f - 1)
            color = stop
          end

          unless (0..1).cover?(position)
            raise ArgumentError, 'position must be between 0 and 1'
          end

          GradientStop.new(position, normalize_color(color))
        end

        if stops.first.position != 0
          raise ArgumentError, 'The first stop must have a position of 0'
        end
        if stops.last.position != 1
          raise ArgumentError, 'The last stop must have a position of 1'
        end

        if stops.map { |stop| color_type(stop.color) }.uniq.length > 1
          raise ArgumentError, 'All colors must be of the same color space'
        end

        Gradient.new(
          r1 ? :radial : :axial,
          apply_transformations,
          stops,
          from, to,
          r1, r2
        )
      end
      # rubocop: enable Metrics/ParameterLists

      def gradient_registry_key(gradient)
        _x1, _y1, x2, y2, transformation = gradient_coordinates(gradient)

        key = [
          gradient.type.to_s,
          transformation,
          x2, y2,
          gradient.r1 || -1, gradient.r2 || -1,
          gradient.stops.length,
          gradient.stops.map { |s| [s.position, s.color] }
        ].flatten
        Digest::SHA1.hexdigest(key.join(','))
      end

      def gradient_registry
        @gradient_registry ||= {}
      end

      def create_gradient_pattern(gradient)
        if gradient.apply_transformations.nil? &&
            current_transformation_matrix_with_translation(0, 0) !=
                [1, 0, 0, 1, 0, 0]
          warn 'Gradients in Prawn 2.x and lower are not correctly positioned '\
            'when a transformation has been made to the document. ' \
            "Pass 'apply_transformations: true' to correctly transform the " \
            'gradient, or see ' \
            'https://github.com/prawnpdf/prawn/wiki/Gradient-Transformations ' \
            'for more information.'
        end

        shader_stops = gradient.stops.each_cons(2).map do |first, second|
          ref!(
            FunctionType: 2,
            Domain: [0.0, 1.0],
            C0: first.color,
            C1: second.color,
            N: 1.0
          )
        end

        # If there's only two stops, we can use the single shader.
        # Otherwise we stitch the multiple shaders together.
        shader = if shader_stops.length == 1
                   shader_stops.first
                 else
                   ref!(
                     FunctionType: 3, # stitching function
                     Domain: [0.0, 1.0],
                     Functions: shader_stops,
                     Bounds: gradient.stops[1..-2].map(&:position),
                     Encode: [0.0, 1.0] * shader_stops.length
                   )
                 end

        x1, y1, x2, y2, transformation = gradient_coordinates(gradient)

        coords = if gradient.type == :axial
                   [0, 0, x2 - x1, y2 - y1]
                 else
                   [0, 0, gradient.r1, x2 - x1, y2 - y1, gradient.r2]
                 end

        shading = ref!(
          ShadingType: gradient.type == :axial ? 2 : 3,
          ColorSpace: color_space(gradient.stops.first.color),
          Coords: coords,
          Function: shader,
          Extend: [true, true]
        )

        ref!(
          PatternType: 2, # shading pattern
          Shading: shading,
          Matrix: transformation
        )
      end

      def gradient_coordinates(gradient)
        x1, y1 = map_to_absolute(gradient.from)
        x2, y2 = map_to_absolute(gradient.to)

        transformation =
          if gradient.apply_transformations
            current_transformation_matrix_with_translation(x1, y1)
          else
            [1, 0, 0, 1, x1, y1]
          end

        [x1, y1, x2, y2, transformation]
      end
    end
  end
end
