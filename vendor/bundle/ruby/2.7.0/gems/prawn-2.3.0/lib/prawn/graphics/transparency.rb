# frozen_string_literal: true

# transparency.rb : Implements transparency
#
# Copyright October 2009, Daniel Nelson. All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.
#

module Prawn
  module Graphics
    # The Prawn::Transparency module is used to place transparent
    # content on the page. It has the capacity for separate
    # transparency values for stroked content and all other content.
    #
    # Example:
    #   # both the fill and stroke will be at 50% opacity
    #   pdf.transparent(0.5) do
    #     pdf.text("hello world")
    #     pdf.fill_and_stroke_circle([x, y], 25)
    #   end
    #
    #   # the fill will be at 50% opacity, but the stroke will
    #   # be at 75% opacity
    #   pdf.transparent(0.5, 0.75) do
    #     pdf.text("hello world")
    #     pdf.fill_and_stroke_circle([x, y], 25)
    #   end
    #
    module Transparency
      # @group Stable API

      # Sets the <tt>opacity</tt> and <tt>stroke_opacity</tt> for all
      # the content within the <tt>block</tt>
      # If <tt>stroke_opacity</tt> is not provided, then it takes on
      # the same value as <tt>opacity</tt>
      #
      # Valid ranges for both paramters are 0.0 to 1.0
      #
      # Example:
      #   # both the fill and stroke will be at 50% opacity
      #   pdf.transparent(0.5) do
      #     pdf.text("hello world")
      #     pdf.fill_and_stroke_circle([x, y], 25)
      #   end
      #
      #   # the fill will be at 50% opacity, but the stroke will
      #   # be at 75% opacity
      #   pdf.transparent(0.5, 0.75) do
      #     pdf.text("hello world")
      #     pdf.fill_and_stroke_circle([x, y], 25)
      #   end
      #
      def transparent(opacity, stroke_opacity = opacity)
        renderer.min_version(1.4)

        opacity = [[opacity, 0.0].max, 1.0].min
        stroke_opacity = [[stroke_opacity, 0.0].max, 1.0].min

        save_graphics_state
        renderer.add_content(
          "/#{opacity_dictionary_name(opacity, stroke_opacity)} gs"
        )
        yield
        restore_graphics_state
      end

      private

      def opacity_dictionary_registry
        @opacity_dictionary_registry ||= {}
      end

      def next_opacity_dictionary_id
        opacity_dictionary_registry.length + 1
      end

      def opacity_dictionary_name(opacity, stroke_opacity)
        key = "#{opacity}_#{stroke_opacity}"

        if opacity_dictionary_registry[key]
          dictionary = opacity_dictionary_registry[key][:obj]
          dictionary_name = opacity_dictionary_registry[key][:name]
        else
          dictionary = ref!(
            Type: :ExtGState,
            CA: stroke_opacity,
            ca: opacity
          )

          dictionary_name = "Tr#{next_opacity_dictionary_id}"
          opacity_dictionary_registry[key] = {
            name: dictionary_name,
            obj: dictionary
          }
        end

        page.ext_gstates[dictionary_name] = dictionary
        dictionary_name
      end
    end
  end
end
