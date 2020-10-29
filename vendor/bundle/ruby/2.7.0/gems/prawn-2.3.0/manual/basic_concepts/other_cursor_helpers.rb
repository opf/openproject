# frozen_string_literal: true

# Another group of helpers for changing the cursor position are the pad methods.
# They accept a numeric value and a block. <code>pad</code> will use the numeric
# value to move the cursor down both before and after the block content.
# <code>pad_top</code> will only move the cursor before the block while
# <code>pad_bottom</code> will only move after.
#
# <code>float</code> is a method for not changing the cursor. Pass it a block
# and the cursor will remain on the same place when the block returns.

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  stroke_horizontal_rule
  pad(20) { text 'Text padded both before and after.' }

  stroke_horizontal_rule
  pad_top(20) { text 'Text padded on the top.' }

  stroke_horizontal_rule
  pad_bottom(20) { text 'Text padded on the bottom.' }

  stroke_horizontal_rule
  move_down 30

  text 'Text written before the float block.'

  float do
    move_down 30
    bounding_box([0, cursor], width: 200) do
      text 'Text written inside the float block.'
      stroke_bounds
    end
  end

  text 'Text written after the float block.'
end
