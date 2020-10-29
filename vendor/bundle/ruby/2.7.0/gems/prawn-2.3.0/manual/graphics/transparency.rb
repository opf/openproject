# frozen_string_literal: true

# Although the name of the method is <code>transparency</code>, what we are
# actually setting is the opacity for fill and stroke. So <code>0</code> means
# completely transparent and <code>1.0</code> means completely opaque
#
# You may call it providing one or two values. The first value sets fill opacity
# and the second value sets stroke opacity. If the second value is omitted fill
# and stroke will have the same opacity.

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  stroke_axis

  self.line_width = 5
  fill_color 'ff0000'
  fill_rectangle [0, 100], 500, 100

  fill_color '000000'
  stroke_color 'ffffff'

  base_x = 100
  [[0.5, 1], 0.5, [1, 0.5]].each do |args|
    transparent(*args) do
      fill_circle [base_x, 100], 50
      stroke_rectangle [base_x - 20, 100], 40, 80
    end

    base_x += 150
  end
end
