# frozen_string_literal: true

# blend_mode.rb : Implements blend modes
#
# Contributed by John Ford. October, 2015
#
# This is free software. Please see the LICENSE and COPYING files for details.
#

module Prawn
  module Graphics
    # The Prawn::BlendMode module is used to change the way
    # two layers are blended together.
    #
    # Passing an array of blend modes is allowed. PDF viewers should
    # blend layers based on the first recognized blend mode.
    #
    # Valid blend modes in v1.4 of the PDF spec include :Normal, :Multiply,
    # :Screen, :Overlay, :Darken, :Lighten, :ColorDodge, :ColorBurn, :HardLight,
    # :SoftLight, :Difference, :Exclusion, :Hue, :Saturation, :Color, and
    # :Luminosity.
    #
    # Example:
    #   pdf.fill_color('0000ff')
    #   pdf.fill_rectangle([x, y+25], 50, 50)
    #   pdf.blend_mode(:Multiply) do
    #     pdf.fill_color('ff0000')
    #     pdf.fill_circle([x, y], 25)
    #   end
    #
    module BlendMode
      # @group Stable API

      def blend_mode(blend_mode = :Normal)
        renderer.min_version(1.4)

        save_graphics_state if block_given?
        renderer.add_content "/#{blend_mode_dictionary_name(blend_mode)} gs"
        if block_given?
          yield
          restore_graphics_state
        end
      end

      private

      def blend_mode_dictionary_registry
        @blend_mode_dictionary_registry ||= {}
      end

      def blend_mode_dictionary_name(blend_mode)
        key = Array(blend_mode).join('')
        dictionary_name = "BM#{key}"

        dictionary = blend_mode_dictionary_registry[dictionary_name] ||= ref!(
          Type: :ExtGState,
          BM: blend_mode
        )

        page.ext_gstates[dictionary_name] = dictionary
        dictionary_name
      end
    end
  end
end
