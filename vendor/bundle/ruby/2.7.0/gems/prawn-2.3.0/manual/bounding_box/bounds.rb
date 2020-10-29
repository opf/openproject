# frozen_string_literal: true

# The <code>bounds</code> method returns the current bounding box. This is
# useful because the <code>Prawn::BoundingBox</code> exposes some nice boundary
# helpers.
#
# <code>top</code>, <code>bottom</code>, <code>left</code> and
# <code>right</code> methods return the bounding box boundaries relative to its
# translated origin. <code>top_left</code>, <code>top_right</code>,
# <code>bottom_left</code> and <code>bottom_right</code> return those boundaries
# pairs inside arrays.
#
# All these methods have an "absolute" version like <code>absolute_right</code>.
# The absolute version returns the same boundary relative to the page absolute
# coordinates.
#
# The following snippet shows the boundaries for the margin box side by side
# with the boundaries for a custom bounding box.

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  def print_coordinates
    text "top: #{bounds.top}"
    text "bottom: #{bounds.bottom}"
    text "left: #{bounds.left}"
    text "right: #{bounds.right}"

    move_down 10

    text "absolute top: #{bounds.absolute_top.to_f.round(2)}"
    text "absolute bottom: #{bounds.absolute_bottom.to_f.round(2)}"
    text "absolute left: #{bounds.absolute_left.to_f.round(2)}"
    text "absolute right: #{bounds.absolute_right.to_f.round(2)}"
  end

  text 'Margin box bounds:'
  move_down 5
  print_coordinates

  bounding_box([250, cursor + 140], width: 200, height: 150) do
    text 'This bounding box bounds:'
    move_down 5
    print_coordinates
    transparent(0.5) { stroke_bounds }
  end
end
