# frozen_string_literal: true

# We've already seen one way of using text boxes with the <code>text_box</code>
# method. Turns out this method is just a convenience for using the
# <code>Prawn::Text::Box</code> class as it creates a new object and call
# <code>render</code> on it.
#
# Knowing that any extensions we add to <code>Prawn::Text::Box</code> will take
# effect when we use the <code>text_box</code> method. To add an extension all
# we need to do is append the <code>Prawn::Text::Box.extensions</code> array
# with a module.

require '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  module TriangleBox
    def available_width
      height + 25
    end
  end

  y_position = cursor - 10
  width = 100
  height = 100

  Prawn::Text::Box.extensions << TriangleBox
  stroke_rectangle([0, y_position], width, height)
  text_box(
    'A' * 100,
    at: [0, y_position],
    width: width,
    height: height
  )

  Prawn::Text::Formatted::Box.extensions << TriangleBox
  stroke_rectangle([200, y_position], width, height)
  formatted_text_box(
    [text: 'A' * 100, color: '009900'],
    at: [200, y_position],
    width: width,
    height: height
  )

  # Here we clear the extensions array
  Prawn::Text::Box.extensions.clear
  Prawn::Text::Formatted::Box.extensions.clear
end
