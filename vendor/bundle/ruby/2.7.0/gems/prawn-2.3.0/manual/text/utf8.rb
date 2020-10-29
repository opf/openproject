# frozen_string_literal: true

# Multilingualization isn't much of a problem on Prawn as its default encoding
# is UTF-8. The only thing you need to worry about is if the font support the
# glyphs of your language.

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  text 'Take this example, a simple Euro sign:'
  text '€', size: 32
  move_down 20

  text 'This works, because €  is one of the few ' \
    'non-ASCII glyphs supported in PDF built-in fonts.'

  move_down 20

  text 'For full internationalized text support, we need to use external fonts:'
  move_down 20

  font("#{Prawn::DATADIR}/fonts/DejaVuSans.ttf") do
    text 'ὕαλον ϕαγεῖν δύναμαι· τοῦτο οὔ με βλάπτει.'
    text 'There you go.'
  end
end
