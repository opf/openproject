# frozen_string_literal: true

# Kerning is the process of adjusting the spacing between characters in a
# proportional font. It is usually done with specific letter pairs. We can
# switch it on and off if it is available with the current font. Just pass a
# boolean value to the <code>:kerning</code> option of the text methods.
#
# Character Spacing is the space between characters. It can be increased or
# decreased and will have effect on the whole text. Just pass a number to the
# <code>:character_spacing</code> option from the text methods.

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  font_size(30) do
    text_box 'With kerning:',    kerning: true,  at: [0, y - 40]
    text_box 'Without kerning:', kerning: false, at: [0, y - 80]

    text_box 'Tomato', kerning: true,  at: [250, y - 40]
    text_box 'Tomato', kerning: false, at: [250, y - 80]

    text_box 'WAR', kerning: true,  at: [400, y - 40]
    text_box 'WAR', kerning: false, at: [400, y - 80]

    text_box 'F.', kerning: true,  at: [500, y - 40]
    text_box 'F.', kerning: false, at: [500, y - 80]
  end

  move_down 80

  string = 'What have you done to the space between the characters?'
  [-2, -1, 0, 0.5, 1, 2].each do |spacing|
    move_down 20
    text "#{string} (character_spacing: #{spacing})",
      character_spacing: spacing
  end
end
