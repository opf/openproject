# frozen_string_literal: true

# The <code>font</code> method can be used in three different ways.
#
# If we don't pass it any arguments it will return the current font being used
# to render text.
#
# If we just pass it a font name it will use that font for rendering text
# through the rest of the document.
#
# It can also be used by passing a font name and a block. In this case the
# specified font will only be used to render text inside the block.
#
# The default font is Helvetica.

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  text "Let's see which font we are using: #{font.inspect}"

  move_down 20
  font 'Times-Roman'
  text 'Written in Times.'

  move_down 20
  font('Courier') do
    text 'Written in Courier because we are inside the block.'
  end

  move_down 20
  text 'Written in Times again as we left the previous block.'

  move_down 20
  text "Let's see which font we are using again: #{font.inspect}"

  move_down 20
  font 'Helvetica'
  text 'Back to normal.'
end
