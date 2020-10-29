# frozen_string_literal: true

# The PDF format has some built-in font support. If you want to use other fonts
# in Prawn you need to embed the font file.
#
# Doing this for a single font is extremely simple. Remember the Styling font
# example? Another use of the <code>font</code> method is to provide a font file
# path and the font will be embedded in the document and set as the current
# font.
#
# This is reasonable if a font is used only once, but, if a font used several
# times, providing the path each time it is used becomes cumbersome. The example
# on the next page shows a better way to deal with fonts which are used several
# times in a document.

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  # Using a TTF font file
  font("#{Prawn::DATADIR}/fonts/DejaVuSans.ttf") do
    text 'Written with the DejaVu Sans TTF font.'
  end
  move_down 20

  text 'Written with the default font.'
  move_down 20

  # Using an DFONT font file
  font("#{Prawn::DATADIR}/fonts/Panic+Sans.dfont") do
    text 'Written with the Panic Sans DFONT font'
  end
  move_down 20

  text 'Written with the default font once more.'
end
