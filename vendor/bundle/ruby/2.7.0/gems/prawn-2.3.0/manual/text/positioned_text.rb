# frozen_string_literal: true

# Sometimes we want the text on a specific position on the page. The
# <code>text</code> method just won't help us.
#
# There are two other methods for this task: <code>draw_text</code> and
# <code>text_box</code>.
#
# <code>draw_text</code> is very simple. It will render text starting at the
# position provided to the <code>:at</code> option. It won't flow to a new line
# even if it hits the document boundaries so it is best suited for short text.
#
# <code>text_box</code> gives us much more control over the output. Just provide
# <code>:width</code> and <code>:height</code> options and the text will flow
# accordingly. Even if you don't provide a <code>:width</code> option the text
# will flow to a new line if it reaches the right border.
#
# Given that, <code>text_box</code> is the better option available.

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  draw_text "This draw_text line is absolute positioned. However don't " \
    'expect it to flow even if it hits the document border',
    at: [200, 300]

  text_box 'This is a text box, you can control where it will flow by ' \
    'specifying the :height and :width options',
    at: [100, 250],
    height: 100,
    width: 100

  text_box 'Another text box with no :width option passed, so it will ' \
    'flow to a new line whenever it reaches the right margin. ',
    at: [200, 100]
end
