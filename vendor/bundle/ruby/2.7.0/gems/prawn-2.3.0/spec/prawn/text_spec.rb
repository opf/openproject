# frozen_string_literal: true

require 'spec_helper'

describe Prawn::Text do
  describe 'NBSP' do
    it 'is defined' do
      expect(Prawn::Text::NBSP).to eq("\u00a0")
    end
  end

  describe '#height_of' do
    let(:pdf) { create_pdf }

    it 'returns the height that would be required to print a' \
      'particular string of text' do
      original_y = pdf.y
      pdf.text('Foo')
      new_y = pdf.y
      expect(pdf.height_of('Foo')).to be_within(0.0001).of(original_y - new_y)
    end

    it 'omits the gap below the last descender if :final_gap => false ' \
      'is given' do
      original_y = pdf.y
      pdf.text('Foo', final_gap: false)
      new_y = pdf.y
      expect(pdf.height_of('Foo', final_gap: false))
        .to be_within(0.0001).of(original_y - new_y)
    end

    it 'raise_errors CannotFit if a too-small width is given' do
      expect do
        pdf.height_of('text', width: 1)
      end.to raise_error(Prawn::Errors::CannotFit)
    end

    it 'raises NotImplementedError if :indent_paragraphs option is provided' do
      expect do
        pdf.height_of(
          'hai',
          width: 300,
          indent_paragraphs: 60
        )
      end.to raise_error(NotImplementedError)
    end

    it 'does not raise Prawn::Errors::UnknownOption if :final_gap option '\
      'is provided' do
      expect do
        pdf.height_of('hai', width: 300, final_gap: true)
      end.to_not raise_error
    end
  end

  describe '#text' do
    let(:pdf) { create_pdf }

    it 'does not fail when @output is nil when '\
      'PDF::Core::Text::LineWrap#finalize_line is called' do
      # need a document with margins for these particulars to produce the
      # condition that was throwing the error
      pdf = Prawn::Document.new
      pdf.text 'transparency ' * 150, size: 18
    end

    it 'allows drawing empty strings to the page' do
      pdf.text ' '
      text = PDF::Inspector::Text.analyze(pdf.render)
      # If anything is rendered to the page, it should be whitespace.
      expect(text.strings).to all(match(/\A\s*\z/))
    end

    it 'ignores call when string is nil' do
      expect(pdf.text(nil)).to eq false
    end

    it 'correctlies render empty paragraphs' do
      pdf.text "text\n\ntext"
      text = PDF::Inspector::Text.analyze(pdf.render)
      expect(pdf.page_count).to eq(1)
      expect(text.strings.reject(&:empty?)).to eq(%w[text text])
    end

    it 'correctlies render empty paragraphs with :indent_paragraphs' do
      pdf.text "text\n\ntext", indent_paragraphs: 5
      text = PDF::Inspector::Text.analyze(pdf.render)
      expect(pdf.page_count).to eq(1)
      expect(text.strings.reject(&:empty?)).to eq(%w[text text])
    end

    it 'correctly renders strings ending with empty paragraphs and ' \
      ':inline_format and :indent_paragraphs' do
      pdf.text "text\n\n", inline_format: true, indent_paragraphs: 5
      text = PDF::Inspector::Text.analyze(pdf.render)
      expect(pdf.page_count).to eq(1)
      expect(text.strings).to eq(['text'])
    end

    it 'defaults to use kerning information' do
      pdf.text 'hello world'
      text = PDF::Inspector::Text.analyze(pdf.render)
      expect(text.kerned[0]).to eq true
    end

    it 'is able to disable kerning with an option' do
      pdf.text 'hello world', kerning: false
      text = PDF::Inspector::Text.analyze(pdf.render)
      expect(text.kerned[0]).to eq false
    end

    it 'is able to disable kerning document-wide' do
      pdf.default_kerning(false)
      pdf.default_kerning = false
      pdf.text 'hello world'
      text = PDF::Inspector::Text.analyze(pdf.render)
      expect(text.kerned[0]).to eq false
    end

    it 'option should be able to override document-wide kerning disabling' do
      pdf.default_kerning = false
      pdf.text 'hello world', kerning: true
      text = PDF::Inspector::Text.analyze(pdf.render)
      expect(text.kerned[0]).to eq true
    end

    it 'raise_errors ArgumentError if :at option included' do
      expect { pdf.text('hai', at: [0, 0]) }.to raise_error(ArgumentError)
    end

    it 'advances down the document based on font_height' do
      position = pdf.y
      pdf.text 'Foo'

      expect(pdf.y).to be_within(0.0001).of(position - pdf.font.height)

      position = pdf.y
      pdf.text "Foo\nBar\nBaz"
      expect(pdf.y).to be_within(0.0001).of(position - 3 * pdf.font.height)
    end

    it 'advances down the document based on font_height with size option' do
      position = pdf.y
      pdf.text 'Foo', size: 15

      pdf.font_size = 15
      expect(pdf.y).to be_within(0.0001).of(position - pdf.font.height)

      position = pdf.y
      pdf.text "Foo\nBar\nBaz"
      expect(pdf.y).to be_within(0.0001).of(position - 3 * pdf.font.height)
    end

    it 'advances down the document based on font_height with leading option' do
      position = pdf.y
      leading = 2
      pdf.text 'Foo', leading: leading

      expect(pdf.y).to be_within(0.0001)
        .of(position - pdf.font.height - leading)

      position = pdf.y
      pdf.text "Foo\nBar\nBaz"
      expect(pdf.y).to be_within(0.0001).of(position - 3 * pdf.font.height)
    end

    it 'advances only to the bottom of the final descender if final_gap '\
      'is false' do
      position = pdf.y
      pdf.text 'Foo', final_gap: false

      expect(pdf.y).to be_within(0.0001)
        .of(position - pdf.font.ascender - pdf.font.descender)

      position = pdf.y
      pdf.text "Foo\nBar\nBaz", final_gap: false
      expect(pdf.y).to be_within(0.0001)
        .of(
          position - 2 * pdf.font.height - pdf.font.ascender -
          pdf.font.descender
        )
    end

    it 'is able to print text starting at the last line of a page' do
      pdf.move_cursor_to(pdf.font.height)
      pdf.text('hello world')
      pages = PDF::Inspector::Page.analyze(pdf.render).pages
      expect(pages.size).to eq(1)
    end

    it 'defaults to 12 point helvetica' do
      pdf.text 'Blah'
      text = PDF::Inspector::Text.analyze(pdf.render)
      expect(text.font_settings[0][:name]).to eq(:Helvetica)
      expect(text.font_settings[0][:size]).to eq(12)
      expect(text.strings.first).to eq('Blah')
    end

    it 'allows setting font size' do
      pdf.text 'Blah', size: 16
      text = PDF::Inspector::Text.analyze(pdf.render)
      expect(text.font_settings[0][:size]).to eq(16)
    end

    it 'allows setting a default font size' do
      pdf.font_size = 16
      pdf.text 'Blah'
      text = PDF::Inspector::Text.analyze(pdf.render)
      expect(text.font_settings[0][:size]).to eq(16)
    end

    it 'allows overriding default font for a single instance' do
      pdf.font_size = 16

      pdf.text 'Blah', size: 11
      pdf.text 'Blaz'
      text = PDF::Inspector::Text.analyze(pdf.render)
      expect(text.font_settings[0][:size]).to eq(11)
      expect(text.font_settings[1][:size]).to eq(16)
    end

    it 'allows setting a font size transaction with a block' do
      pdf.font_size 16 do
        pdf.text 'Blah'
      end

      pdf.text 'blah'

      text = PDF::Inspector::Text.analyze(pdf.render)
      expect(text.font_settings[0][:size]).to eq(16)
      expect(text.font_settings[1][:size]).to eq(12)
    end

    it 'allows manual setting the font size when in a font size block' do
      pdf.font_size(16) do
        pdf.text 'Foo'
        pdf.text 'Blah', size: 11
        pdf.text 'Blaz'
      end
      text = PDF::Inspector::Text.analyze(pdf.render)
      expect(text.font_settings[0][:size]).to eq(16)
      expect(text.font_settings[1][:size]).to eq(11)
      expect(text.font_settings[2][:size]).to eq(16)
    end

    it 'allows registering of built-in font_settings on the fly' do
      pdf.font 'Times-Roman'
      pdf.text 'Blah'
      pdf.font 'Courier'
      pdf.text 'Blaz'
      text = PDF::Inspector::Text.analyze(pdf.render)
      expect(text.font_settings[0][:name]).to eq(:"Times-Roman")
      expect(text.font_settings[1][:name]).to eq(:Courier)
    end

    it 'utilises the same default font across multiple pages' do
      pdf.text 'Blah'
      pdf.start_new_page
      pdf.text 'Blaz'
      text = PDF::Inspector::Text.analyze(pdf.render)

      expect(text.font_settings.size).to eq(2)
      expect(text.font_settings[0][:name]).to eq(:Helvetica)
      expect(text.font_settings[1][:name]).to eq(:Helvetica)
    end

    it 'raise_errors an exception when an unknown font is used' do
      expect { pdf.font 'Pao bu' }.to raise_error(Prawn::Errors::UnknownFont)
    end

    it 'does not raise an exception when providing Pathname instance as font' do
      pdf.font Pathname.new("#{Prawn::DATADIR}/fonts/DejaVuSans.ttf")
    end

    it 'correctlies render a utf-8 string when using a built-in font' do
      str = '©' # copyright symbol
      pdf.text str

      # grab the text from the rendered PDF and ensure it matches
      text = PDF::Inspector::Text.analyze(pdf.render)
      expect(text.strings.first).to eq(str)
    end

    it 'correctlies render a utf-8 string when using a TTF font' do
      str = '©' # copyright symbol
      pdf.font "#{Prawn::DATADIR}/fonts/DejaVuSans.ttf"
      pdf.text str

      # grab the text from the rendered PDF and ensure it matches
      text = PDF::Inspector::Text.analyze(pdf.render)
      expect(text.strings.first).to eq(str)
    end

    it 'subsets mixed low-ASCII and non-ASCII characters when they can '\
      'be subsetted together' do
      str = 'It’s super effective!'
      pdf.font "#{Prawn::DATADIR}/fonts/DejaVuSans.ttf"
      pdf.text str

      text = PDF::Inspector::Text.analyze(pdf.render)
      expect(text.strings.first).to eq(str)
    end

    it 'correctly renders a string with higher bit characters across a page '\
      'break when using a built-in font' do
      str = '©'
      pdf.move_cursor_to(pdf.font.height)
      pdf.text(str + "\n" + str)

      pages = PDF::Inspector::Page.analyze(pdf.render).pages
      expect(pages.size).to eq(2)
      expect(pages[0][:strings]).to eq([str])
      expect(pages[1][:strings]).to eq([str])
    end

    it 'correctly renders a string with higher bit characters across ' \
      'a page break when using a built-in font and :indent_paragraphs option' do
      str = '©'
      pdf.move_cursor_to(pdf.font.height)
      pdf.text(str + "\n" + str, indent_paragraphs: 20)

      pages = PDF::Inspector::Page.analyze(pdf.render).pages
      expect(pages.size).to eq(2)
      expect(pages[0][:strings]).to eq([str])
      expect(pages[1][:strings]).to eq([str])
    end

    it 'raises an exception when a utf-8 incompatible string is rendered' do
      str = "Blah \xDD"
      expect { pdf.text str }.to raise_error(
        Prawn::Errors::IncompatibleStringEncoding
      )
    end

    it 'does not raise an exception when a shift-jis string is rendered' do
      datafile = "#{Prawn::DATADIR}/shift_jis_text.txt"
      sjis_str = File.open(datafile, 'r:shift_jis', &:gets)
      pdf.font("#{Prawn::DATADIR}/fonts/gkai00mp.ttf")

      # Expect that the call to text will not raise an encoding error
      pdf.text(sjis_str)
    end

    it 'calls move_past_bottom when printing more text than can fit' \
      ' between the current document.y and bounds.bottom' do
      pdf.y = pdf.font.height
      pdf.text 'Hello'
      pdf.text 'World'
      pages = PDF::Inspector::Page.analyze(pdf.render).pages
      expect(pages.size).to eq(2)
      expect(pages[0][:strings]).to eq(['Hello'])
      expect(pages[1][:strings]).to eq(['World'])
    end

    describe 'with :indent_paragraphs option' do
      it 'indents the paragraphs' do
        hello = 'hello ' * 50
        hello2 = 'hello ' * 50
        pdf.text(hello + "\n" + hello2, indent_paragraphs: 60)
        text = PDF::Inspector::Text.analyze(pdf.render)
        expect(text.strings[0]).to eq(('hello ' * 19).strip)
        expect(text.strings[1]).to eq(('hello ' * 21).strip)
        expect(text.strings[3]).to eq(('hello ' * 19).strip)
        expect(text.strings[4]).to eq(('hello ' * 21).strip)
      end

      it 'indents from right side when using :rtl direction' do
        para1 = 'The rain in spain falls mainly on the plains ' * 3
        para2 = 'The rain in spain falls mainly on the plains ' * 3

        pdf.text(para1 + "\n" + para2, indent_paragraphs: 60, direction: :rtl)

        text = PDF::Inspector::Text.analyze(pdf.render)

        lines = text.strings
        x_positions = text.positions.map { |e| e[0] }

        # NOTE: The code below reflects Prawn's current kerning behavior for RTL
        # text, which isn't necessarily correct. If we change that behavior,
        # this test will need to be updated.

        expect(x_positions[0]).to(
          be_within(0.001).of(pdf.bounds.absolute_right - 60 -
                              pdf.width_of(lines[0].reverse, kerning: true))
        )

        expect(x_positions[1]).to(
          be_within(0.001).of(pdf.bounds.absolute_right -
                              pdf.width_of(lines[1].reverse, kerning: true))
        )

        expect(x_positions[2]).to(
          be_within(0.001).of(pdf.bounds.absolute_right - 60 -
                              pdf.width_of(lines[2].reverse, kerning: true))
        )

        expect(x_positions[3]).to(
          be_within(0.001).of(pdf.bounds.absolute_right -
                              pdf.width_of(lines[3].reverse, kerning: true))
        )
      end

      it 'indents from right side when document has :rtl direction' do
        para1 = 'The rain in spain falls mainly on the plains ' * 3
        para2 = 'The rain in spain falls mainly on the plains ' * 3

        pdf.text_direction = :rtl
        pdf.text(para1 + "\n" + para2, indent_paragraphs: 60)

        text = PDF::Inspector::Text.analyze(pdf.render)

        lines = text.strings
        x_positions = text.positions.map { |e| e[0] }

        # NOTE: The code below reflects Prawn's current kerning behavior for RTL
        # text, which isn't necessarily correct. If we change that behavior,
        # this test will need to be updated.

        expect(x_positions[0]).to(
          be_within(0.001).of(pdf.bounds.absolute_right - 60 -
                              pdf.width_of(lines[0].reverse, kerning: true))
        )

        expect(x_positions[1]).to(
          be_within(0.001).of(pdf.bounds.absolute_right -
                              pdf.width_of(lines[1].reverse, kerning: true))
        )

        expect(x_positions[2]).to(
          be_within(0.001).of(pdf.bounds.absolute_right - 60 -
                              pdf.width_of(lines[2].reverse, kerning: true))
        )

        expect(x_positions[3]).to(
          be_within(0.001).of(pdf.bounds.absolute_right -
                              pdf.width_of(lines[3].reverse, kerning: true))
        )
      end

      it 'indents from left side when using :ltr direction' do
        para1 = 'The rain in spain falls mainly on the plains ' * 3
        para2 = 'The rain in spain falls mainly on the plains ' * 3

        pdf.text(para1 + "\n" + para2, indent_paragraphs: 60, direction: :ltr)

        text = PDF::Inspector::Text.analyze(pdf.render)

        x_positions = text.positions.map { |e| e[0] }

        expect(x_positions[0]).to eq(60)
        expect(x_positions[1]).to eq(0)

        expect(x_positions[2]).to eq(60)
        expect(x_positions[3]).to eq(0)
      end

      it 'indents from left side when document has :ltr direction' do
        para1 = 'The rain in spain falls mainly on the plains ' * 3
        para2 = 'The rain in spain falls mainly on the plains ' * 3

        pdf.text_direction = :ltr
        pdf.text(para1 + "\n" + para2, indent_paragraphs: 60)

        text = PDF::Inspector::Text.analyze(pdf.render)

        x_positions = text.positions.map { |e| e[0] }

        expect(x_positions[0]).to eq(60)
        expect(x_positions[1]).to eq(0)

        expect(x_positions[2]).to eq(60)
        expect(x_positions[3]).to eq(0)
      end

      describe 'when paragraph has only one line, it should not add ' \
        'additional leading' do
        let(:leading) { 100 }

        it 'adds leading only once' do
          original_y = pdf.y
          pdf.text('hello', indent_paragraphs: 10, leading: leading)
          expect(original_y - pdf.y).to be < leading * 2
        end
      end

      describe 'when wrap to new page, and first line of new page' \
              ' is not the start of a new paragraph, that line should' \
              ' not be indented' do
        it 'indents the paragraphs' do
          hello = 'hello ' * 50
          hello2 = 'hello ' * 50
          pdf.move_cursor_to(pdf.font.height)
          pdf.text(hello + "\n" + hello2, indent_paragraphs: 60)
          text = PDF::Inspector::Text.analyze(pdf.render)
          expect(text.strings[0]).to eq(('hello ' * 19).strip)
          expect(text.strings[1]).to eq(('hello ' * 21).strip)
          expect(text.strings[3]).to eq(('hello ' * 19).strip)
          expect(text.strings[4]).to eq(('hello ' * 21).strip)
        end
      end

      describe 'when wrap to new page, and first line of new page' \
              ' is the start of a new paragraph, that line should' \
              ' be indented' do
        it 'indents the paragraphs' do
          hello = 'hello ' * 50
          hello2 = 'hello ' * 50
          pdf.move_cursor_to(pdf.font.height * 3)
          pdf.text(hello + "\n" + hello2, indent_paragraphs: 60)
          text = PDF::Inspector::Text.analyze(pdf.render)
          expect(text.strings[0]).to eq(('hello ' * 19).strip)
          expect(text.strings[1]).to eq(('hello ' * 21).strip)
          expect(text.strings[3]).to eq(('hello ' * 19).strip)
          expect(text.strings[4]).to eq(('hello ' * 21).strip)
        end
      end
    end

    describe 'kerning' do
      it 'respects text kerning setting (document default)' do
        allow(pdf.font).to receive(:compute_width_of)
          .with('VAT', hash_including(kerning: true))
          .and_return(10)

        pdf.text 'VAT'

        expect(pdf.font).to have_received(:compute_width_of)
          .with('VAT', hash_including(kerning: true))
      end

      it 'respects text kerning setting (kerning=true)' do
        allow(pdf.font).to receive(:compute_width_of)
          .with('VAT', hash_including(kerning: true))
          .at_least(:once)
          .and_return(10)
        pdf.text 'VAT', kerning: true

        expect(pdf.font).to have_received(:compute_width_of)
          .with('VAT', hash_including(kerning: true))
          .at_least(:once)
      end

      it 'respects text kerning setting (kerning=false)' do
        allow(pdf.font).to receive(:compute_width_of)
          .with('VAT', hash_including(kerning: false))
          .at_least(:once)
          .and_return(10)
        pdf.text 'VAT', kerning: false

        expect(pdf.font).to have_received(:compute_width_of)
          .with('VAT', hash_including(kerning: false))
          .at_least(:once)
      end
    end

    describe '#shrink_to_fit with special utf-8 text' do
      it 'does not throw an exception', :unresolved, issue: 603 do
        expect do
          Prawn::Document.new(page_size: 'A4', margin: [2, 2, 2, 2]) do |pdf|
            add_unicode_fonts(pdf)
            pdf.bounding_box([1, 1], width: 90, height: 50) do
              pdf.text(
                "Sample Text\nSAMPLE SAMPLE SAMPLEoddělení ZMĚN\nSAMPLE",
                overflow: :shrink_to_fit
              )
            end
          end
        end.to_not raise_error
      end
    end

    def add_unicode_fonts(pdf)
      dejavu = "#{::Prawn::BASEDIR}/data/fonts/DejaVuSans.ttf"
      pdf.font_families.update(
        'dejavu' => {
          normal: dejavu,
          italic: dejavu,
          bold: dejavu,
          bold_italic: dejavu
        }
      )
      pdf.fallback_fonts = ['dejavu']
    end

    describe 'fallback_fonts' do
      it 'preserves font style' do
        create_pdf

        pdf.fallback_fonts ['Helvetica']
        pdf.font 'Times-Roman', style: :italic do
          pdf.text 'hello'
        end

        text = PDF::Inspector::Text.analyze(pdf.render)
        fonts_used = text.font_settings.map { |e| e[:name] }

        expect(fonts_used.length).to eq(1)
        expect(fonts_used[0]).to eq(:"Times-Italic")
        expect(text.strings[0]).to eq('hello')
      end
    end
  end
end
