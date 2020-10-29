# frozen_string_literal: true

# To set the vertical position of an image use the <code>:vposition</code>
# option.
#
# It may be <code>:top</code>, <code>:center</code>, <code>:bottom</code> or a
# number representing the y-offset from the top boundary.

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  bounding_box([0, cursor], width: 500, height: 450) do
    stroke_bounds

    %i[top center bottom].each do |vposition|
      text "Image vertically aligned to the #{vposition}.", valign: vposition
      image "#{Prawn::DATADIR}/images/stef.jpg",
        position: 250, vposition: vposition
    end

    text_box 'The next image has a 100 point offset from the top boundary',
      at: [bounds.width - 110, bounds.top - 10], width: 100
    image "#{Prawn::DATADIR}/images/stef.jpg",
      position: :right, vposition: 100
  end
end
