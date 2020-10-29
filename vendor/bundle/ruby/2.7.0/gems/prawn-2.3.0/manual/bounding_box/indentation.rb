# frozen_string_literal: true

# Sometimes you just need to indent a portion of the contents of a bounding box,
# and using a nested bounding box is pure overkill. The <code>indent</code>
# method is what you might need.
#
# Just provide a number for it to indent all content generated inside the
# block.

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  text 'No indentation on the margin box.'
  indent(20) do
    text 'Some indentation inside an indent block.'
  end
  move_down 20

  bounding_box([50, cursor], width: 400, height: cursor) do
    transparent(0.5) { stroke_bounds }

    move_down 10
    text 'No indentation inside this bounding box.'
    indent(40) do
      text 'Inside an indent block. And so is this horizontal line:'

      stroke_horizontal_rule
    end
    move_down 10
    text 'No indentation'

    move_down 20
    indent(60) do
      text 'Another indent block.'

      bounding_box([0, cursor], width: 200) do
        text 'Note that this bounding box coordinates are relative to the ' \
          'indent block'

        transparent(0.5) { stroke_bounds }
      end
    end
  end
end
