# frozen_string_literal: true

# The <code>line_width=</code> method sets the stroke width for subsequent
# stroke calls.
#
# Since Ruby assumes that an unknown variable on the left hand side of an
# assignment is a local temporary, rather than a setter method, if you are using
# the block call to <code>Prawn::Document.generate</code> without passing params
# you will need to call <code>line_width</code> on self.

# rubocop: disable Lint/UselessAssignment
require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  stroke_axis

  y = 250

  3.times do |i|
    case i
    when 0 then line_width = 10 # This call will have no effect
    when 1 then self.line_width = 10
    when 2 then self.line_width = 25
    end

    stroke do
      horizontal_line 50, 150, at: y
      rectangle [275, y + 25], 50, 50
      circle [500, y], 25
    end

    y -= 100
  end
end
# rubocop: enable Lint/UselessAssignment
