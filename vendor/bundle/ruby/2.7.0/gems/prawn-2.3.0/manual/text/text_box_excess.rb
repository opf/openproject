# frozen_string_literal: true

# Whenever the <code>text_box</code> method truncates text, this truncated bit
# is not lost, it is the method return value and we can take advantage of that.
#
# We just need to take some precautions.
#
# This example renders as much of the text as will fit in a larger font inside
# one text_box and then proceeds to render the remaining text in the default
# size in a second text_box.

require '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  string = 'This is the beginning of the text. It will be cut somewhere and ' \
    'the rest of the text will procede to be rendered this time by ' \
    'calling another method.' + ' . ' * 50

  y_position = cursor - 20
  excess_text = text_box(
    string,
    width: 300,
    height: 50,
    overflow: :truncate,
    at: [100, y_position],
    size: 18
  )

  text_box(
    excess_text,
    width: 300,
    at: [100, y_position - 100]
  )
end
