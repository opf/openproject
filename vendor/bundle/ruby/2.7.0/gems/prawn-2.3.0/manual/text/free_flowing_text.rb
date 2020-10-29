# frozen_string_literal: true

# Text rendering can be as simple or as complex as you want.
#
# This example covers the most basic method: <code>text</code>. It is meant for
# free flowing text. The provided string will flow according to the current
# bounding box width and height. It will also flow onto the next page if the
# bottom of the bounding box is reached.
#
# The text will start being rendered on the current cursor position. When it
# finishes rendering, the cursor is left directly below the text.
#
# This example also shows text flowing across pages following the margin box and
# other bounding boxes.

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  move_cursor_to 50
  text 'This text will flow to the next page. ' * 20

  y_position = cursor - 50
  bounding_box([0, y_position], width: 200, height: 150) do
    transparent(0.5) { stroke_bounds }
    text 'This text will flow along this bounding box we created for it. ' * 5
  end

  bounding_box([300, y_position], width: 200, height: 150) do
    transparent(0.5) { stroke_bounds }  # This will stroke on one page

    text 'Now look what happens when the free flowing text reaches the end ' \
      'of a bounding box that is narrower than the margin box.' +
      ' . ' * 200 +
      'It continues on the next page as if the previous bounding box ' \
      'was cloned. If we want it to have the same border as the one on ' \
      'the previous page we will need to stroke the boundaries again.'

    transparent(0.5) { stroke_bounds }  # And this will stroke on the next
  end

  move_cursor_to 200
  span(350, position: :center) do
    text 'Span is a different kind of bounding box as it lets the text ' \
      "flow gracefully onto the next page. It doesn't matter if the text " \
      'started on the middle of the previous page, when it flows to the ' \
      'next page it will start at the beginning.' + ' _ ' * 500 +
      'I told you it would start on the beginning of this page.'
  end
end
