# frozen_string_literal: true

require 'spec_helper'

describe Prawn::Text::Formatted::Box do
  let(:pdf) { create_pdf }

  describe 'wrapping' do
    it 'does not wrap between two fragments' do
      texts = [
        { text: 'Hello ' },
        { text: 'World' },
        { text: '2', styles: [:superscript] }
      ]
      text_box = described_class.new(
        texts,
        document: pdf,
        width: pdf.width_of('Hello World')
      )
      text_box.render
      expect(text_box.text).to eq("Hello\nWorld2")
    end

    it 'does not raise an Encoding::CompatibilityError when keeping a TTF and '\
      'an AFM font together' do
      file = "#{Prawn::DATADIR}/fonts/gkai00mp.ttf"

      pdf.font_families['Kai'] = {
        normal: { file: file, font: 'Kai' }
      }

      texts = [
        { text: 'Hello ' },
        { text: '再见', font: 'Kai' },
        { text: 'World' }
      ]
      text_box = described_class.new(
        texts,
        document: pdf,
        width: pdf.width_of('Hello World')
      )

      text_box.render
    end

    it 'wraps between two fragments when the preceding fragment ends with '\
      'a white space' do
      texts = [
        { text: 'Hello ' },
        { text: 'World ' },
        { text: '2', styles: [:superscript] }
      ]
      text_box = described_class.new(
        texts,
        document: pdf,
        width: pdf.width_of('Hello World')
      )
      text_box.render
      expect(text_box.text).to eq("Hello World\n2")

      texts = [
        { text: 'Hello ' },
        { text: "World\n" },
        { text: '2', styles: [:superscript] }
      ]
      text_box = described_class.new(
        texts,
        document: pdf,
        width: pdf.width_of('Hello World')
      )
      text_box.render
      expect(text_box.text).to eq("Hello World\n2")
    end

    it 'wraps between two fragments when the final fragment begins with '\
      'a white space' do
      texts = [
        { text: 'Hello ' },
        { text: 'World' },
        { text: ' 2', styles: [:superscript] }
      ]
      text_box = described_class.new(
        texts,
        document: pdf,
        width: pdf.width_of('Hello World')
      )
      text_box.render
      expect(text_box.text).to eq("Hello World\n2")

      texts = [
        { text: 'Hello ' },
        { text: 'World' },
        { text: "\n2", styles: [:superscript] }
      ]
      text_box = described_class.new(
        texts,
        document: pdf,
        width: pdf.width_of('Hello World')
      )
      text_box.render
      expect(text_box.text).to eq("Hello World\n2")
    end

    it 'properlies handle empty slices using default encoding' do
      texts = [{
        text: 'Noua Delineatio Geographica generalis | Apostolicarum ' \
          'peregrinationum | S FRANCISCI XAUERII | Indiarum & Iaponiæ Apostoli',
        font: 'Courier', size: 10
      }]
      text_box = described_class.new(
        texts,
        document: pdf,
        width: pdf.width_of('Noua Delineatio Geographica gen')
      )
      expect do
        text_box.render
      end.to_not raise_error
      expect(text_box.text).to eq(
        "Noua Delineatio Geographica\ngeneralis | Apostolicarum\n" \
        "peregrinationum | S FRANCISCI\nXAUERII | Indiarum & Iaponi\346\n" \
        'Apostoli'
      )
    end
  end

  describe 'Text::Formatted::Box with :fallback_fonts option that includes' \
    'a Chinese font and set of Chinese glyphs not in the current font' do
    it 'changes the font to the Chinese font for the Chinese glyphs' do
      file = "#{Prawn::DATADIR}/fonts/gkai00mp.ttf"
      pdf.font_families['Kai'] = {
        normal: { file: file, font: 'Kai' }
      }
      formatted_text = [
        { text: 'hello你好' },
        { text: '再见goodbye' }
      ]
      pdf.formatted_text_box(formatted_text, fallback_fonts: ['Kai'])

      text = PDF::Inspector::Text.analyze(pdf.render)

      fonts_used = text.font_settings.map { |e| e[:name] }
      expect(fonts_used.length).to eq(4)
      expect(fonts_used[0]).to eq(:Helvetica)
      expect(fonts_used[1].to_s).to match(/GBZenKai-Medium/)
      expect(fonts_used[2].to_s).to match(/GBZenKai-Medium/)
      expect(fonts_used[3]).to eq(:Helvetica)

      expect(text.strings[0]).to eq('hello')
      expect(text.strings[1]).to eq('你好')
      expect(text.strings[2]).to eq('再见')
      expect(text.strings[3]).to eq('goodbye')
    end
  end

  describe 'Text::Formatted::Box with :fallback_fonts option that includes' \
    'an AFM font and Win-Ansi glyph not in the current Chinese font' do
    it 'changes the font to the AFM font for the Win-Ansi glyph' do
      file = "#{Prawn::DATADIR}/fonts/gkai00mp.ttf"
      pdf.font_families['Kai'] = {
        normal: { file: file, font: 'Kai' }
      }
      pdf.font('Kai')
      formatted_text = [
        { text: 'hello你好' },
        { text: '再见€' }
      ]
      pdf.formatted_text_box(formatted_text, fallback_fonts: ['Helvetica'])

      text = PDF::Inspector::Text.analyze(pdf.render)

      fonts_used = text.font_settings.map { |e| e[:name] }
      expect(fonts_used.length).to eq(4)
      expect(fonts_used[0].to_s).to match(/GBZenKai-Medium/)
      expect(fonts_used[1].to_s).to match(/GBZenKai-Medium/)
      expect(fonts_used[2].to_s).to match(/GBZenKai-Medium/)
      expect(fonts_used[3]).to eq(:Helvetica)

      expect(text.strings[0]).to eq('hello')
      expect(text.strings[1]).to eq('你好')
      expect(text.strings[2]).to eq('再见')
      expect(text.strings[3]).to eq('€')
    end
  end

  describe 'Text::Formatted::Box with :fallback_fonts option and fragment ' \
    'level font' do
    it 'uses the fragment level font except for glyphs not in that font' do
      file = "#{Prawn::DATADIR}/fonts/gkai00mp.ttf"
      pdf.font_families['Kai'] = {
        normal: { file: file, font: 'Kai' }
      }

      file = "#{Prawn::DATADIR}/fonts/DejaVuSans.ttf"
      pdf.font_families['DejaVu Sans'] = {
        normal: { file: file }
      }

      formatted_text = [
        { text: 'hello你好' },
        { text: '再见goodbye', font: 'Times-Roman' }
      ]
      pdf.formatted_text_box(formatted_text, fallback_fonts: ['Kai'])

      text = PDF::Inspector::Text.analyze(pdf.render)

      fonts_used = text.font_settings.map { |e| e[:name] }
      expect(fonts_used.length).to eq(4)
      expect(fonts_used[0]).to eq(:Helvetica)
      expect(fonts_used[1].to_s).to match(/GBZenKai-Medium/)
      expect(fonts_used[2].to_s).to match(/GBZenKai-Medium/)
      expect(fonts_used[3]).to eq(:"Times-Roman")

      expect(text.strings[0]).to eq('hello')
      expect(text.strings[1]).to eq('你好')
      expect(text.strings[2]).to eq('再见')
      expect(text.strings[3]).to eq('goodbye')
    end
  end

  describe 'Text::Formatted::Box' do
    let(:formatted_text) { [{ text: 'hello你好' }] }

    before do
      file = "#{Prawn::DATADIR}/fonts/gkai00mp.ttf"
      pdf.font_families['Kai'] = {
        normal: { file: file, font: 'Kai' }
      }

      file = "#{Prawn::DATADIR}/fonts/DejaVuSans.ttf"
      pdf.font_families['DejaVu Sans'] = {
        normal: { file: file }
      }

      pdf.fallback_fonts(['Kai'])
      pdf.fallback_fonts = ['Kai']
    end

    it '#fallback_fonts should return the document-wide fallback fonts' do
      expect(pdf.fallback_fonts).to eq(['Kai'])
    end

    it 'is able to set text fallback_fonts document-wide' do
      pdf.formatted_text_box(formatted_text)

      text = PDF::Inspector::Text.analyze(pdf.render)

      fonts_used = text.font_settings.map { |e| e[:name] }
      expect(fonts_used.length).to eq(2)
      expect(fonts_used[0]).to eq(:Helvetica)
      expect(fonts_used[1].to_s).to match(/GBZenKai-Medium/)
    end

    it 'is able to override document-wide fallback_fonts' do
      pdf.fallback_fonts = ['DejaVu Sans']
      pdf.formatted_text_box(formatted_text, fallback_fonts: ['Kai'])

      text = PDF::Inspector::Text.analyze(pdf.render)

      fonts_used = text.font_settings.map { |e| e[:name] }
      expect(fonts_used.length).to eq(2)
      expect(fonts_used[0]).to eq(:Helvetica)
      expect(fonts_used[1]).to match(/Kai/)
    end

    it 'omits the fallback fonts overhead when passing an empty array ' \
      'as the :fallback_fonts' do
      pdf.font('Kai')

      box = described_class.new(
        formatted_text,
        document: pdf,
        fallback_fonts: []
      )

      allow(box).to receive(:process_fallback_fonts)
      box.render
      expect(box).to_not have_received(:process_fallback_fonts)
    end

    it 'is able to clear document-wide fallback_fonts' do
      pdf.fallback_fonts([])
      box = described_class.new(formatted_text, document: pdf)

      pdf.font('Kai')

      allow(box).to receive(:process_fallback_fonts)
      box.render
      expect(box).to_not have_received(:process_fallback_fonts)
    end
  end

  describe 'Text::Formatted::Box with :fallback_fonts option ' \
    'with glyphs not in the primary or the fallback fonts' do
    it 'raises an exception' do
      formatted_text = [{ text: 'hello world. 世界你好。' }]

      expect do
        pdf.formatted_text_box(formatted_text, fallback_fonts: ['Courier'])
      end.to raise_error(Prawn::Errors::IncompatibleStringEncoding)
    end
  end

  describe 'Text::Formatted::Box#extensions' do
    let(:formatted_wrap_override) do
      Module.new do
        # rubocop: disable RSpec/InstanceVariable
        def wrap(_array)
          initialize_wrap([{ text: 'all your base are belong to us' }])
          @line_wrap.wrap_line(
            document: @document,
            kerning: @kerning,
            width: 10_000,
            arranger: @arranger
          )
          fragment = @arranger.retrieve_fragment
          format_and_draw_fragment(fragment, 0, @line_wrap.width, 0)

          []
        end
        # rubocop: enable RSpec/InstanceVariable
      end
    end

    it 'is able to override default line wrapping' do
      described_class.extensions << formatted_wrap_override
      pdf.formatted_text_box([{ text: 'hello world' }], {})
      described_class.extensions.delete(formatted_wrap_override)
      text = PDF::Inspector::Text.analyze(pdf.render)
      expect(text.strings[0]).to eq('all your base are belong to us')
    end

    it 'overrides Text::Formatted::Box line wrapping does not affect ' \
      'Text::Box wrapping' do
      described_class.extensions << formatted_wrap_override
      pdf.text_box('hello world', {})
      described_class.extensions.delete(formatted_wrap_override)
      text = PDF::Inspector::Text.analyze(pdf.render)
      expect(text.strings[0]).to eq('hello world')
    end

    it "overring Text::Box line wrapping doesn't override Text::Box wrapping" do
      Prawn::Text::Box.extensions << formatted_wrap_override
      pdf.text_box('hello world', {})
      Prawn::Text::Box.extensions.delete(formatted_wrap_override)
      text = PDF::Inspector::Text.analyze(pdf.render)
      expect(text.strings[0]).to eq('all your base are belong to us')
    end
  end

  describe 'Text::Formatted::Box#render' do
    let(:fragment_callback_class) do
      Class.new do
        def initialize(_string, _number, _options); end

        def render_behind(fragment); end

        def render_in_front(fragment); end
      end
    end

    it 'handles newlines' do
      array = [{ text: "hello\nworld" }]
      options = { document: pdf }
      text_box = described_class.new(array, options)
      text_box.render
      expect(text_box.text).to eq("hello\nworld")
    end

    it 'omits spaces from the beginning of the line' do
      array = [{ text: " hello\n world" }]
      options = { document: pdf }
      text_box = described_class.new(array, options)
      text_box.render
      expect(text_box.text).to eq("hello\nworld")
    end

    it 'is okay printing a line of whitespace' do
      array = [{ text: "hello\n    \nworld" }]
      options = { document: pdf }
      text_box = described_class.new(array, options)
      text_box.render
      expect(text_box.text).to eq("hello\n\nworld")

      array = [
        { text: 'hello' + ' ' * 500 },
        { text: ' ' * 500 },
        { text: ' ' * 500 + "\n" },
        { text: 'world' }
      ]
      options = { document: pdf }
      text_box = described_class.new(array, options)
      text_box.render
      expect(text_box.text).to eq("hello\n\nworld")
    end

    it 'enables fragment level direction setting' do
      number_of_hellos = 18
      array = [
        { text: 'hello ' * number_of_hellos },
        { text: 'world', direction: :ltr },
        { text: ', how are you?' }
      ]
      options = { document: pdf, direction: :rtl }
      text_box = described_class.new(array, options)
      text_box.render
      text = PDF::Inspector::Text.analyze(pdf.render)
      expect(text.strings[0]).to eq('era woh ,')
      expect(text.strings[1]).to eq('world')
      expect(text.strings[2]).to eq(' olleh' * number_of_hellos)
      expect(text.strings[3]).to eq('?uoy')
    end

    it 'is able to perform fragment callbacks' do
      callback_object =
        fragment_callback_class.new('something', 7, document: pdf)
      allow(callback_object).to receive(:render_behind)
      allow(callback_object).to receive(:render_in_front)
      array = [
        { text: 'hello world ' },
        { text: 'callback now', callback: callback_object }
      ]
      text_box = described_class.new(array, document: pdf)
      text_box.render

      expect(callback_object).to have_received(:render_behind).with(
        kind_of(Prawn::Text::Formatted::Fragment)
      )
      expect(callback_object).to have_received(:render_in_front).with(
        kind_of(Prawn::Text::Formatted::Fragment)
      )
    end

    it 'is able to perform fragment callbacks on multiple objects' do
      callback_object =
        fragment_callback_class.new('something', 7, document: pdf)
      allow(callback_object).to receive(:render_behind)
      allow(callback_object).to receive(:render_in_front)

      callback_object2 = fragment_callback_class.new(
        'something else', 14, document: pdf
      )
      allow(callback_object2).to receive(:render_behind)
      allow(callback_object2).to receive(:render_in_front)

      array = [
        { text: 'hello world ' },
        { text: 'callback now', callback: [callback_object, callback_object2] }
      ]
      text_box = described_class.new(array, document: pdf)
      text_box.render

      expect(callback_object).to have_received(:render_behind).with(
        kind_of(Prawn::Text::Formatted::Fragment)
      )
      expect(callback_object).to have_received(:render_in_front).with(
        kind_of(Prawn::Text::Formatted::Fragment)
      )
      expect(callback_object2).to have_received(:render_behind).with(
        kind_of(Prawn::Text::Formatted::Fragment)
      )
      expect(callback_object2).to have_received(:render_in_front).with(
        kind_of(Prawn::Text::Formatted::Fragment)
      )
    end

    it 'fragment callbacks is able to define only the callback they need' do
      behind = (
        Class.new do
          def initialize(_string, _number, _options); end

          def render_behind(fragment); end
        end
      ).new(
        'something', 7,
        document: pdf
      )
      in_front = (
        Class.new do
          def initialize(_string, _number, _options); end

          def render_in_front(fragment); end
        end
      ).new(
        'something', 7,
        document: pdf
      )
      array = [
        { text: 'hello world ' },
        { text: 'callback now', callback: [behind, in_front] }
      ]
      text_box = described_class.new(array, document: pdf)

      text_box.render # trigger callbacks
    end

    it 'is able to set the font' do
      array = [
        { text: 'this contains ' },
        {
          text: 'Times-Bold',
          styles: [:bold],
          font: 'Times-Roman'
        },
        { text: ' text' }
      ]
      text_box = described_class.new(array, document: pdf)
      text_box.render
      contents = PDF::Inspector::Text.analyze(pdf.render)
      fonts = contents.font_settings.map { |e| e[:name] }
      expect(fonts).to eq(%i[Helvetica Times-Bold Helvetica])
      expect(contents.strings[0]).to eq('this contains ')
      expect(contents.strings[1]).to eq('Times-Bold')
      expect(contents.strings[2]).to eq(' text')
    end

    it 'is able to set bold' do
      array = [
        { text: 'this contains ' },
        { text: 'bold', styles: [:bold] },
        { text: ' text' }
      ]
      text_box = described_class.new(array, document: pdf)
      text_box.render
      contents = PDF::Inspector::Text.analyze(pdf.render)
      fonts = contents.font_settings.map { |e| e[:name] }
      expect(fonts).to eq(%i[Helvetica Helvetica-Bold Helvetica])
      expect(contents.strings[0]).to eq('this contains ')
      expect(contents.strings[1]).to eq('bold')
      expect(contents.strings[2]).to eq(' text')
    end

    it 'is able to set italics' do
      array = [
        { text: 'this contains ' },
        { text: 'italic', styles: [:italic] },
        { text: ' text' }
      ]
      text_box = described_class.new(array, document: pdf)
      text_box.render
      contents = PDF::Inspector::Text.analyze(pdf.render)
      fonts = contents.font_settings.map { |e| e[:name] }
      expect(fonts).to eq(%i[Helvetica Helvetica-Oblique Helvetica])
    end

    it 'is able to set subscript' do
      array = [
        { text: 'this contains ' },
        { text: 'subscript', size: 18, styles: [:subscript] },
        { text: ' text' }
      ]
      text_box = described_class.new(array, document: pdf)
      text_box.render
      contents = PDF::Inspector::Text.analyze(pdf.render)
      expect(contents.font_settings[0][:size]).to eq(12)
      expect(contents.font_settings[1][:size])
        .to be_within(0.0001).of(18 * 0.583)
    end

    it 'is able to set superscript' do
      array = [
        { text: 'this contains ' },
        { text: 'superscript', size: 18, styles: [:superscript] },
        { text: ' text' }
      ]
      text_box = described_class.new(array, document: pdf)
      text_box.render
      contents = PDF::Inspector::Text.analyze(pdf.render)
      expect(contents.font_settings[0][:size]).to eq(12)
      expect(contents.font_settings[1][:size])
        .to be_within(0.0001).of(18 * 0.583)
    end

    it 'is able to set compound bold and italic text' do
      array = [
        { text: 'this contains ' },
        { text: 'bold italic', styles: %i[bold italic] },
        { text: ' text' }
      ]
      text_box = described_class.new(array, document: pdf)
      text_box.render
      contents = PDF::Inspector::Text.analyze(pdf.render)
      fonts = contents.font_settings.map { |e| e[:name] }
      expect(fonts).to eq(%i[Helvetica Helvetica-BoldOblique Helvetica])
    end

    it 'is able to underline' do
      array = [
        { text: 'this contains ' },
        { text: 'underlined', styles: [:underline] },
        { text: ' text' }
      ]
      text_box = described_class.new(array, document: pdf)
      text_box.render
      line_drawing = PDF::Inspector::Graphics::Line.analyze(pdf.render)
      expect(line_drawing.points.length).to eq(2)
    end

    it 'is able to strikethrough' do
      array = [
        { text: 'this contains ' },
        { text: 'struckthrough', styles: [:strikethrough] },
        { text: ' text' }
      ]
      text_box = described_class.new(array, document: pdf)
      text_box.render
      line_drawing = PDF::Inspector::Graphics::Line.analyze(pdf.render)
      expect(line_drawing.points.length).to eq(2)
    end

    it 'is able to add URL links' do
      allow(pdf).to receive(:link_annotation)
      array = [
        { text: 'click ' },
        { text: 'here', link: 'http://example.com' },
        { text: ' to visit' }
      ]
      text_box = described_class.new(array, document: pdf)
      text_box.render

      expect(pdf).to have_received(:link_annotation).with(
        kind_of(Array),
        Border: [0, 0, 0],
        A: {
          Type: :Action,
          S: :URI,
          URI: 'http://example.com'
        }
      )
    end

    it 'is able to add destination links' do
      allow(pdf).to receive(:link_annotation)
      array = [
        { text: 'Go to the ' },
        { text: 'Table of Contents', anchor: 'ToC' }
      ]
      text_box = described_class.new(array, document: pdf)
      text_box.render

      expect(pdf).to have_received(:link_annotation).with(
        kind_of(Array),
        Border: [0, 0, 0],
        Dest: 'ToC'
      )
    end

    it 'is able to add local actions' do
      allow(pdf).to receive(:link_annotation)
      array = [
        { text: 'click ' },
        { text: 'here', local: '../example.pdf' },
        { text: ' to open a local file' }
      ]
      text_box = described_class.new(array, document: pdf)
      text_box.render

      expect(pdf).to have_received(:link_annotation).with(
        kind_of(Array),
        Border: [0, 0, 0],
        A: {
          Type: :Action,
          S: :Launch,
          F: '../example.pdf',
          NewWindow: true
        }
      )
    end

    it 'is able to set font size' do
      array = [
        { text: 'this contains ' },
        { text: 'sized', size: 24 },
        { text: ' text' }
      ]
      text_box = described_class.new(array, document: pdf)
      text_box.render
      contents = PDF::Inspector::Text.analyze(pdf.render)
      expect(contents.font_settings[0][:size]).to eq(12)
      expect(contents.font_settings[1][:size]).to eq(24)
    end

    it 'sets the baseline based on the tallest fragment on a given line' do
      array = [
        { text: 'this contains ' },
        { text: 'sized', size: 24 },
        { text: ' text' }
      ]
      text_box = described_class.new(array, document: pdf)
      text_box.render
      pdf.font_size(24) do
        expect(text_box.height).to be_within(0.001)
          .of(pdf.font.ascender + pdf.font.descender)
      end
    end

    it 'is able to set color via an rgb hex string' do
      array = [{
        text: 'rgb',
        color: 'ff0000'
      }]
      text_box = described_class.new(array, document: pdf)
      text_box.render
      colors = PDF::Inspector::Graphics::Color.analyze(pdf.render)
      expect(colors.fill_color_count).to eq(2)
      expect(colors.stroke_color_count).to eq(2)
    end

    it 'is able to set color using a cmyk array' do
      array = [{
        text: 'cmyk',
        color: [100, 0, 0, 0]
      }]
      text_box = described_class.new(array, document: pdf)
      text_box.render
      colors = PDF::Inspector::Graphics::Color.analyze(pdf.render)
      expect(colors.fill_color_count).to eq(2)
      expect(colors.stroke_color_count).to eq(2)
    end
  end

  describe 'Text::Formatted::Box#render(:dry_run => true)' do
    it 'does not change the graphics state of the document' do
      state_before = PDF::Inspector::Graphics::Color.analyze(pdf.render)
      fill_color_count = state_before.fill_color_count
      stroke_color_count = state_before.stroke_color_count
      stroke_color_space_count = state_before.stroke_color_space_count

      array = [{
        text: 'Foo',
        color: [0, 0, 0, 100]
      }]
      options = { document: pdf }
      text_box = described_class.new(array, options)
      text_box.render(dry_run: true)

      state_after = PDF::Inspector::Graphics::Color.analyze(pdf.render)
      expect(state_after.fill_color_count).to eq(fill_color_count)
      expect(state_after.stroke_color_count).to eq(stroke_color_count)
      expect(state_after.stroke_color_space_count)
        .to eq(stroke_color_space_count)
    end
  end

  describe 'Text::Formatted::Box#render with fragment level '\
    ':character_spacing option' do
    it 'draws the character spacing to the document' do
      array = [{
        text: 'hello world',
        character_spacing: 7
      }]
      options = { document: pdf }
      text_box = described_class.new(array, options)
      text_box.render
      contents = PDF::Inspector::Text.analyze(pdf.render)
      expect(contents.character_spacing[0]).to eq(7)
    end

    it 'lays out text properly' do
      array = [{
        text: 'hello world',
        font: 'Courier',
        character_spacing: 10
      }]
      options = {
        document: pdf,
        width: 100,
        overflow: :expand
      }
      text_box = described_class.new(array, options)
      text_box.render
      expect(text_box.text).to eq("hello\nworld")
    end
  end

  describe 'Text::Formatted::Box#render with :align => :justify' do
    it 'does not justify the last line of a paragraph' do
      array = [
        { text: 'hello world ' },
        { text: "\n" },
        { text: 'goodbye' }
      ]
      options = { document: pdf, align: :justify }
      text_box = described_class.new(array, options)
      text_box.render
      contents = PDF::Inspector::Text.analyze(pdf.render)
      expect(contents.word_spacing).to be_empty
    end

    it 'raise an exception when align value is not a symbol' do
      array = [
        { text: 'hello world ' },
        { text: "\n" },
        { text: 'goodbye' }
      ]
      options = { document: pdf, align: 'justify' }
      text_box = described_class.new(array, options)
      expect { text_box.render }.to raise_error(
        ArgumentError,
        'align must be one of :left, :right, :center or :justify symbols'
      )
    end
  end

  describe 'Text::Formatted::Box#render with :valign => :center' do
    it 'has a bottom gap equal to baseline and bottom of box' do
      box_height = 100
      y = 450
      array = [{ text: 'Vertical Align' }]
      options = {
        document: pdf,
        valign: :center,
        at: [0, y],
        width: 100,
        height: box_height,
        size: 16
      }
      text_box = described_class.new(array, options)
      text_box.render
      line_padding = (box_height - text_box.height + text_box.descender) * 0.5
      baseline = y - line_padding

      expect(text_box.at[1]).to be_within(0.01).of(baseline)
    end
  end

  describe 'Text::Formatted::Box#render with :valign => :bottom' do
    it 'does not render a gap between the text and bottom of box' do
      box_height = 100
      y = 450
      array = [{ text: 'Vertical Align' }]
      options = {
        document: pdf,
        valign: :bottom,
        at: [0, y],
        width: 100,
        height: box_height,
        size: 16
      }
      text_box = described_class.new(array, options)
      text_box.render
      top_padding = y - (box_height - text_box.height)

      expect(text_box.at[1]).to be_within(0.01).of(top_padding)
    end
  end
end
