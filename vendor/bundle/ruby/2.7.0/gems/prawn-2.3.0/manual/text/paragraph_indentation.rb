# frozen_string_literal: true

# Prawn strips all whitespace from the beginning and the end of strings so there
# are two ways to indent paragraphs:
#
# One is to use non-breaking spaces which Prawn won't strip. One shortcut to
# using them is the <code>Prawn::Text::NBSP</code>.
#
# The other is to use the <code>:indent_paragraphs</code> option with the text
# methods. Just pass a number with the space to indent the first line in each
# paragraph.

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  # Using non-breaking spaces
  text ' ' * 10 + "This paragraph won't be indented. " * 10 +
    "\n#{Prawn::Text::NBSP * 10}" + 'This one will with NBSP. ' * 10

  move_down 20
  text 'This paragraph will be indented. ' * 10 +
    "\n" + 'This one will too. ' * 10,
    indent_paragraphs: 60

  move_down 20

  text 'FROM RIGHT TO LEFT:'
  text 'This paragraph will be indented. ' * 10 +
    "\n" + 'This one will too. ' * 10,
    indent_paragraphs: 60, direction: :rtl
end
