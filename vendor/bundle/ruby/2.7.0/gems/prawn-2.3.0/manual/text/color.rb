# frozen_string_literal: true

# The <code>:color</code> attribute can give a block of text a default color,
# in RGB hex format or 4-value CMYK.

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  text 'Default color is black'
  move_down 25

  text 'Changed to red', color: 'FF0000'
  move_down 25

  text 'CMYK color', color: [22, 55, 79, 30]
  move_down 25

  text(
    "Also works with <color rgb='ff0000'>inline</color> formatting",
    color: '0000FF',
    inline_format: true
  )
end
