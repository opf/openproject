# frozen_string_literal: true

require 'spec_helper'
require 'pathname'

describe Prawn::Font do
  let(:pdf) { create_pdf }

  describe 'Font behavior' do
    it 'defaults to Helvetica if no font is specified' do
      pdf = Prawn::Document.new
      expect(pdf.font.name).to eq('Helvetica')
    end
  end

  describe 'Font objects' do
    it 'is equal' do
      font1 = Prawn::Document.new.font
      font2 = Prawn::Document.new.font

      expect(font1).to eql(font2)
    end

    it 'alwayses be the same key' do
      font1 = Prawn::Document.new.font
      font2 = Prawn::Document.new.font

      hash = {}

      hash[font1] = 'Original'
      hash[font2] = 'Overwritten'

      expect(hash.size).to eq(1)

      expect(hash[font1]).to eq('Overwritten')
      expect(hash[font2]).to eq('Overwritten')
    end
  end

  describe '#width_of' do
    it 'takes character spacing into account' do
      original_width = pdf.width_of('hello world')
      pdf.character_spacing(7) do
        expect(pdf.width_of('hello world')).to eq(original_width + 10 * 7)
      end
    end

    it 'excludes newlines' do
      # Use a TTF font that has a non-zero width for \n
      pdf.font("#{Prawn::DATADIR}/fonts/gkai00mp.ttf")

      expect(pdf.width_of("\nhello world\n")).to eq(
        pdf.width_of('hello world')
      )
    end

    it 'takes formatting into account' do
      normal_hello = pdf.width_of('hello')
      inline_bold_hello = pdf.width_of('<b>hello</b>', inline_format: true)
      expect(inline_bold_hello).to be > normal_hello

      pdf.font('Helvetica', style: :bold) do
        expect(inline_bold_hello).to eq(pdf.width_of('hello'))
      end
    end

    it 'accepts :style as an argument' do
      styled_bold_hello = pdf.width_of('hello', style: :bold)
      pdf.font('Helvetica', style: :bold) do
        expect(styled_bold_hello).to eq(pdf.width_of('hello'))
      end
    end

    it 'reports missing font with style' do
      expect do
        pdf.font('Nada', style: :bold) do
          pdf.width_of('hello')
        end
      end.to raise_error(Prawn::Errors::UnknownFont, /Nada \(bold\)/)
    end

    it 'calculates styled widths correctly using TTFs' do
      pdf.font_families.update(
        'DejaVu Sans' => {
          normal: "#{Prawn::DATADIR}/fonts/DejaVuSans.ttf",
          bold: "#{Prawn::DATADIR}/fonts/DejaVuSans-Bold.ttf"
        }
      )
      styled_bold_hello = nil
      bold_hello = nil
      plain_hello = nil

      pdf.font('DejaVu Sans') do
        styled_bold_hello = pdf.width_of('hello', style: :bold)
      end
      pdf.font('DejaVu Sans', style: :bold) do
        bold_hello = pdf.width_of('hello')
      end

      pdf.font('DejaVu Sans') do
        plain_hello = pdf.width_of('hello')
      end

      expect(plain_hello).to_not eq(bold_hello)

      expect(styled_bold_hello).to eq(bold_hello)
    end

    it 'does not treat minus as if it were a hyphen', issue: 578 do
      expect(pdf.width_of('-0.75')).to be < pdf.width_of('25.00')
    end
  end

  describe '#font_size' do
    it 'allows setting font size in DSL style' do
      pdf.font_size 20
      expect(pdf.font_size).to eq(20)
    end
  end

  describe 'font style support' do
    it 'complains if there is no @current_page' do
      pdf_without_page = Prawn::Document.new(skip_page_creation: true)

      expect { pdf_without_page.font 'Helvetica' }
        .to raise_error(Prawn::Errors::NotOnPage)
    end

    it 'allows specifying font style by style name and font family' do
      pdf.font 'Courier', style: :bold
      pdf.text 'In Courier bold'

      pdf.font 'Courier', style: :bold_italic
      pdf.text 'In Courier bold-italic'

      pdf.font 'Courier', style: :italic
      pdf.text 'In Courier italic'

      pdf.font 'Courier', style: :normal
      pdf.text 'In Normal Courier'

      pdf.font 'Helvetica'
      pdf.text 'In Normal Helvetica'

      text = PDF::Inspector::Text.analyze(pdf.render)
      expect(text.font_settings.map { |e| e[:name] }).to eq(
        %i[
          Courier-Bold Courier-BoldOblique Courier-Oblique
          Courier Helvetica
        ]
      )
    end

    it 'allows font familes to be defined in a single dfont' do
      file = "#{Prawn::DATADIR}/fonts/Panic+Sans.dfont"
      pdf.font_families['Panic Sans'] = {
        normal: { file: file, font: 'PanicSans' },
        italic: { file: file, font: 'PanicSans-Italic' },
        bold: { file: file, font: 'PanicSans-Bold' },
        bold_italic: { file: file, font: 'PanicSans-BoldItalic' }
      }

      pdf.font 'Panic Sans', style: :italic
      pdf.text 'In PanicSans-Italic'

      text = PDF::Inspector::Text.analyze(pdf.render)
      name = text.font_settings.map { |e| e[:name] }.first.to_s
      name = name.sub(/\w+\+/, 'subset+')
      expect(name).to eq('subset+PanicSans-Italic')
    end

    it 'allows font familes to be defined in a single ttc' do
      file = "#{Prawn::DATADIR}/fonts/DejaVuSans.ttc"
      pdf.font_families['DejaVu Sans'] = {
        normal: { file: file, font: 0 },
        bold: { file: file, font: 1 }
      }

      pdf.font 'DejaVu Sans', style: :bold
      pdf.text 'In PanicSans-Bold'

      text = PDF::Inspector::Text.analyze(pdf.render)
      name = text.font_settings.map { |e| e[:name] }.first.to_s
      name = name.sub(/\w+\+/, 'subset+')
      expect(name).to eq('subset+DejaVuSans-Bold')
    end

    it 'allows fonts to be indexed by name in a ttc file' do
      file = "#{Prawn::DATADIR}/fonts/DejaVuSans.ttc"
      pdf.font_families['DejaVu Sans'] = {
        normal: { file: file, font: 'DejaVu Sans' },
        bold: { file: file, font: 'DejaVu Sans Bold' }
      }

      pdf.font 'DejaVu Sans', style: :bold
      pdf.text 'In PanicSans-Bold'

      text = PDF::Inspector::Text.analyze(pdf.render)
      name = text.font_settings.map { |e| e[:name] }.first.to_s
      name = name.sub(/\w+\+/, 'subset+')
      expect(name).to eq('subset+DejaVuSans-Bold')
    end

    it 'accepts Pathname objects for font files' do
      file = Pathname.new("#{Prawn::DATADIR}/fonts/DejaVuSans.ttf")
      pdf.font_families['DejaVu Sans'] = {
        normal: file
      }

      pdf.font 'DejaVu Sans'
      pdf.text 'In DejaVu Sans'

      text = PDF::Inspector::Text.analyze(pdf.render)
      name = text.font_settings.map { |e| e[:name] }.first.to_s
      name = name.sub(/\w+\+/, 'subset+')
      expect(name).to eq('subset+DejaVuSans')
    end

    it 'accepts IO objects for font files' do
      io = File.open "#{Prawn::DATADIR}/fonts/DejaVuSans.ttf"
      pdf.font_families['DejaVu Sans'] = {
        normal: described_class.load(pdf, io)
      }

      pdf.font 'DejaVu Sans'
      pdf.text 'In DejaVu Sans'

      text = PDF::Inspector::Text.analyze(pdf.render)
      name = text.font_settings.map { |e| e[:name] }.first.to_s
      name = name.sub(/\w+\+/, 'subset+')
      expect(name).to eq('subset+DejaVuSans')
    end
  end

  describe 'Transactional font handling' do
    it 'allows setting of size directly when font is created' do
      pdf.font 'Courier', size: 16
      expect(pdf.font_size).to eq(16)
    end

    it 'allows temporary setting of a new font using a transaction' do
      pdf.font 'Helvetica', size: 12

      pdf.font 'Courier', size: 16 do
        expect(pdf.font.name).to eq('Courier')
        expect(pdf.font_size).to eq(16)
      end

      expect(pdf.font.name).to eq('Helvetica')
      expect(pdf.font_size).to eq(12)
    end

    it 'masks font size when using a transacation' do
      pdf.font 'Courier', size: 16 do
        expect(pdf.font_size).to eq(16)
      end

      pdf.font 'Times-Roman'
      pdf.font 'Courier'

      expect(pdf.font_size).to eq(12)
    end
  end

  describe 'Document#page_fonts' do
    it 'registers fonts properly by page' do
      pdf.font 'Courier'
      pdf.text('hello')

      pdf.font 'Helvetica'
      pdf.text('hello')

      pdf.font 'Times-Roman'
      pdf.text('hello')

      %w[Courier Helvetica Times-Roman].each do |f|
        page_should_include_font(f)
      end

      pdf.start_new_page

      pdf.font 'Helvetica'
      pdf.text('hello')

      page_should_include_font('Helvetica')
      page_should_not_include_font('Courier')
      page_should_not_include_font('Times-Roman')
    end

    def page_includes_font?(font)
      pdf.page.fonts.values.map { |e| e.data[:BaseFont] }.include?(font.to_sym)
    end

    def page_should_include_font(font)
      expect(page_includes_font?(font)).to eq true
    end

    def page_should_not_include_font(font)
      expect(page_includes_font?(font)).to eq false
    end
  end

  describe 'AFM fonts' do
    let(:times) { pdf.find_font 'Times-Roman' }

    it 'calculates string width taking into account accented characters' do
      input = win1252_string("\xE9") # é in win-1252
      expect(times.compute_width_of(input, size: 12))
        .to eq(times.compute_width_of('e', size: 12))
    end

    it 'calculates string width taking into account kerning pairs' do
      expect(times.compute_width_of(win1252_string('To'), size: 12))
        .to eq(13.332)
      expect(times.compute_width_of(
        win1252_string('To'),
        size: 12, kerning: true
      )).to eq(12.372)

      input = win1252_string("T\xF6") # Tö in win-1252
      expect(times.compute_width_of(input, size: 12, kerning: true))
        .to eq(12.372)
    end

    it 'encodes text without kerning by default' do
      expect(times.encode_text(win1252_string('To'))).to eq([[0, 'To']])
      input = win1252_string("T\xE9l\xE9") # Télé in win-1252
      expect(times.encode_text(input)).to eq([[0, input]])
      expect(times.encode_text(win1252_string('Technology')))
        .to eq([[0, 'Technology']])
      expect(times.encode_text(win1252_string('Technology...')))
        .to eq([[0, 'Technology...']])
    end

    it 'encodes text with kerning if requested' do
      expect(times.encode_text(win1252_string('To'), kerning: true))
        .to eq([[0, ['T', 80, 'o']]])
      input = win1252_string("T\xE9l\xE9") # Télé in win-1252
      output = win1252_string("\xE9l\xE9") # élé  in win-1252
      expect(times.encode_text(input, kerning: true))
        .to eq([[0, ['T', 70, output]]])
      expect(times.encode_text(win1252_string('Technology'), kerning: true))
        .to eq([[0, ['T', 70, 'echnology']]])
      expect(times.encode_text(win1252_string('Technology...'), kerning: true))
        .to eq([[0, ['T', 70, 'echnology', 65, '...']]])
    end

    describe 'when normalizing encoding' do
      it 'does not modify the original string when normalize_encoding() '\
        'is used' do
        original = 'Foo'
        normalized = times.normalize_encoding(original)
        expect(original.equal?(normalized)).to eq false
      end
    end

    it 'omits /Encoding for symbolic fonts' do
      zapf = pdf.find_font 'ZapfDingbats'
      font_dict = zapf.send(:register, nil)
      expect(font_dict.data[:Encoding]).to be_nil
    end
  end

  describe '#glyph_present' do
    it 'returns true when present in an AFM font' do
      font = pdf.find_font('Helvetica')
      expect(font.glyph_present?('H')).to eq true
    end

    it 'returns false when absent in an AFM font' do
      font = pdf.find_font('Helvetica')
      expect(font.glyph_present?('再')).to eq false
    end

    it 'returns true when present in a TTF font' do
      font = pdf.find_font("#{Prawn::DATADIR}/fonts/DejaVuSans.ttf")
      expect(font.glyph_present?('H')).to eq true
    end

    it 'returns false when absent in a TTF font' do
      font = pdf.find_font("#{Prawn::DATADIR}/fonts/DejaVuSans.ttf")
      expect(font.glyph_present?('再')).to eq false

      font = pdf.find_font("#{Prawn::DATADIR}/fonts/gkai00mp.ttf")
      expect(font.glyph_present?('€')).to eq false
    end
  end

  describe 'TTF fonts' do
    let(:font) { pdf.find_font "#{Prawn::DATADIR}/fonts/DejaVuSans.ttf" }

    it 'calculates string width taking into account accented characters' do
      expect(font.compute_width_of('é', size: 12)).to eq(
        font.compute_width_of('e', size: 12)
      )
    end

    it 'calculates string width taking into account kerning pairs' do
      expect(font.compute_width_of('To', size: 12)).to be_within(0.01).of(14.65)
      expect(font.compute_width_of('To', size: 12, kerning: true))
        .to be_within(0.01).of(12.61)
    end

    it 'encodes text without kerning by default' do
      expect(font.encode_text('To')).to eq([[0, 'To']])

      tele = "T\216l\216"
      result = font.encode_text('Télé')
      expect(result.length).to eq(1)
      expect(result[0][0]).to eq(0)
      expect(result[0][1].bytes.to_a).to eq(tele.bytes.to_a)

      expect(font.encode_text('Technology')).to eq([[0, 'Technology']])
      expect(font.encode_text('Technology...')).to eq([[0, 'Technology...']])
      expect(font.encode_text('Teχnology...')).to eq([
        [0, 'Te'],
        [1, '!'], [0, 'nology...']
      ])
    end

    it 'encodes text with kerning if requested' do
      expect(font.encode_text('To', kerning: true)).to eq([
        [0, ['T', 169.921875, 'o']]
      ])
      expect(font.encode_text('Technology', kerning: true)).to eq([
        [0, ['T', 169.921875, 'echnology']]
      ])
      expect(font.encode_text('Technology...', kerning: true)).to eq([
        [0, ['T', 169.921875, 'echnology', 142.578125, '...']]
      ])
      expect(font.encode_text('Teχnology...', kerning: true)).to eq([
        [0, ['T', 169.921875, 'e']],
        [1, '!'],
        [0, ['nology', 142.578125, '...']]
      ])
    end

    it 'uses the ascender, descender, and cap height from the TTF verbatim' do
      # These metrics are relative to the font's own bbox. They should not be
      # scaled with font size.
      ref = pdf.ref!({})
      font.send :embed, ref, 0

      # Pull out the embedded font descriptor
      descriptor = ref.data[:FontDescriptor].data
      expect(descriptor[:Ascent]).to eq(759)
      expect(descriptor[:Descent]).to eq(-240)
      expect(descriptor[:CapHeight]).to eq(759)
    end

    describe 'when normalizing encoding' do
      it 'does not modify the original string with normalize_encoding()' do
        original = 'Foo'
        normalized = font.normalize_encoding(original)
        expect(original.equal?(normalized)).to eq false
      end
    end
  end

  describe 'OTF fonts' do
    let(:font) { pdf.find_font "#{Prawn::DATADIR}/fonts/Bodoni-Book.otf" }

    it 'calculates string width taking into account accented characters' do
      expect(font.compute_width_of('é', size: 12)).to eq(
        font.compute_width_of('e', size: 12)
      )
    end

    it 'uses the ascender, descender, and cap height from the OTF verbatim' do
      # These metrics are relative to the font's own bbox. They should not be
      # scaled with font size.
      ref = pdf.ref!({})
      font.send :embed, ref, 0

      # Pull out the embedded font descriptor
      descriptor = ref.data[:FontDescriptor].data
      expect(descriptor[:Ascent]).to eq(1023)
      expect(descriptor[:Descent]).to eq(-200)
      expect(descriptor[:CapHeight]).to eq(3072)
    end

    describe 'when normalizing encoding' do
      it 'does not modify the original string with normalize_encoding()' do
        original = 'Foo'
        normalized = font.normalize_encoding(original)
        expect(original).to_not be_equal(normalized)
      end
    end
  end

  describe 'DFont fonts' do
    let(:file) { "#{Prawn::DATADIR}/fonts/Panic+Sans.dfont" }

    it 'lists all named fonts' do
      list = Prawn::Fonts::DFont.named_fonts(file)
      expect(list).to match_array(%w[
        PanicSans PanicSans-Bold PanicSans-BoldItalic PanicSans-Italic
      ])
    end

    it 'counts the number of fonts in the file' do
      expect(Prawn::Fonts::DFont.font_count(file)).to eq(4)
    end

    it 'defaults selected font to the first one if not specified' do
      font = pdf.find_font(file)
      expect(font.basename).to eq('PanicSans')
    end

    it 'allows font to be selected by index' do
      font = pdf.find_font(file, font: 2)
      expect(font.basename).to eq('PanicSans-Italic')
    end

    it 'allows font to be selected by name' do
      font = pdf.find_font(file, font: 'PanicSans-BoldItalic')
      expect(font.basename).to eq('PanicSans-BoldItalic')
    end

    it 'caches font object based on selected font' do
      f1 = pdf.find_font(file, font: 'PanicSans')
      f2 = pdf.find_font(file, font: 'PanicSans-Bold')
      expect(f2.object_id).to_not eq(f1.object_id)
      expect(pdf.find_font(file, font: 'PanicSans').object_id)
        .to eq(f1.object_id)
      expect(pdf.find_font(file, font: 'PanicSans-Bold').object_id)
        .to eq(f2.object_id)
    end
  end

  describe '#character_count(text)' do
    it 'works on TTF fonts' do
      pdf.font("#{Prawn::DATADIR}/fonts/gkai00mp.ttf")
      expect(pdf.font.character_count('こんにちは世界')).to eq(7)
      expect(pdf.font.character_count('Hello, world!')).to eq(13)
    end

    it 'works on AFM fonts' do
      expect(pdf.font.character_count('Hello, world!')).to eq(13)
    end
  end
end
