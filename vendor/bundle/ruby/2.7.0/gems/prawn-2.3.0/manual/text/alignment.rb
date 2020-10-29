# frozen_string_literal: true

# Horizontal text alignment can be achieved by supplying the <code>:align</code>
# option to the text methods. Available options are <code>:left</code>
# (default), <code>:right</code>, <code>:center</code>, and
# <code>:justify</code>.
#
# Vertical text alignment can be achieved using the <code>:valign</code> option
# with the text methods. Available options are <code>:top</code> (default),
# <code>:center</code>, and <code>:bottom</code>.
#
# Both forms of alignment will be evaluated in the context of the current
# bounding_box.

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  text 'This text should be left aligned'
  text 'This text should be centered',      align: :center
  text 'This text should be right aligned', align: :right

  bounding_box([0, 220], width: 250, height: 220) do
    text 'This text is flowing from the left. ' * 4

    move_down 15
    text 'This text is flowing from the center. ' * 3, align: :center

    move_down 15
    text 'This text is flowing from the right. ' * 4, align: :right

    move_down 15
    text 'This text is justified. ' * 6, align: :justify
    transparent(0.5) { stroke_bounds }
  end

  bounding_box([300, 220], width: 250, height: 220) do
    text 'This text should be vertically top aligned'
    text 'This text should be vertically centered',       valign: :center
    text 'This text should be vertically bottom aligned', valign: :bottom
    transparent(0.5) { stroke_bounds }
  end
end
