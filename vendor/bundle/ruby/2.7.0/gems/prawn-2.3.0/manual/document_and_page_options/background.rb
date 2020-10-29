# frozen_string_literal: true

# Pass an image path to the <code>:background</code> option and it will be used
# as the background for all pages.
# This option can only be used on document creation.

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')

img = "#{Prawn::DATADIR}/images/letterhead.jpg"

Prawn::Document.generate(filename, background: img, margin: 100) do
  text 'My report caption', size: 18, align: :right

  move_down font.height * 2

  text 'Here is my text explaning this report. ' * 20,
    size: 12, align: :left, leading: 2

  move_down font.height

  text "I'm using a soft background. " * 40,
    size: 12, align: :left, leading: 2
end
