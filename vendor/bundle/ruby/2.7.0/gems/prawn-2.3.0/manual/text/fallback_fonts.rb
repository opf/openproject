# frozen_string_literal: true

# Prawn enables the declaration of fallback fonts for those glyphs that may not
# be present in the desired font. Use the <code>:fallback_fonts</code> option
# with any of the text or text box methods, or set fallback_fonts document-wide.

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  file = "#{Prawn::DATADIR}/fonts/gkai00mp.ttf"
  font_families['Kai'] = {
    normal: { file: file, font: 'Kai' }
  }

  file = "#{Prawn::DATADIR}/fonts/Panic+Sans.dfont"
  font_families['Panic Sans'] = {
    normal: { file: file, font: 'PanicSans' }
  }

  font('Panic Sans') do
    text(
      'When fallback fonts are included, each glyph will be rendered ' \
      'using the first font that includes the glyph, starting with the ' \
      'current font and then moving through the fallback fonts from left ' \
      'to right.' \
      "\n\n" \
      "hello ƒ 你好\n再见 ƒ goodbye",
      fallback_fonts: %w[Times-Roman Kai]
    )
  end
  move_down 20

  formatted_text(
    [
      { text: 'Fallback fonts can even override' },
      { text: 'fragment fonts (你好)', font: 'Times-Roman' }
    ],
    fallback_fonts: %w[Times-Roman Kai]
  )
end
