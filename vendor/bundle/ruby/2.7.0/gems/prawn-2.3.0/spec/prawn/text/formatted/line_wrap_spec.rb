# frozen_string_literal: true

require 'spec_helper'

describe Prawn::Text::Formatted::LineWrap do
  let(:pdf) { create_pdf }
  let(:arranger) do
    Prawn::Text::Formatted::Arranger.new(pdf).tap do |a|
      a.format_array = [
        { text: "hello\nworld\n\n\nhow are you?" },
        { text: "\n" },
        { text: "\n" },
        { text: '' },
        { text: 'fine, thanks. ' * 4 },
        { text: '' },
        { text: "\n" },
        { text: '' }
      ]
    end
  end
  let(:line_wrap) { described_class.new }

  it 'only returns an empty string if nothing fit or there' \
     'was nothing to wrap' do
    8.times do
      line = line_wrap.wrap_line(
        arranger: arranger,
        width: 200,
        document: pdf
      )
      expect(line).to_not be_empty
    end
    line = line_wrap.wrap_line(
      arranger: arranger,
      width: 200,
      document: pdf
    )
    expect(line).to be_empty
  end

  it 'tokenizes a string using the scan_pattern' do
    tokens = line_wrap.tokenize('one two three')
    expect(tokens.length).to eq(5)
  end

  describe 'Core::Text::Formatted::LineWrap#wrap_line' do
    let(:arranger) { Prawn::Text::Formatted::Arranger.new(pdf) }
    let(:one_word_width) { 50 }

    it 'strips leading and trailing spaces' do
      array = [
        { text: ' hello world, ' },
        { text: 'goodbye  ', style: [:bold] }
      ]
      arranger.format_array = array
      string = line_wrap.wrap_line(
        arranger: arranger,
        width: 300,
        document: pdf
      )
      expect(string).to eq('hello world, goodbye')
    end

    it 'strips trailing spaces when a white-space-only fragment was' \
      ' successfully pushed onto the end of a line but no other non-white' \
      ' space fragment fits after it' do
      array = [
        { text: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa ' },
        { text: '  ', style: [:bold] },
        { text: ' bbbbbbbbbbbbbbbbbbbbbbbbbbbb' }
      ]
      arranger.format_array = array
      string = line_wrap.wrap_line(
        arranger: arranger,
        width: 300,
        document: pdf
      )
      expect(string).to eq('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa')
    end

    it 'raise_errors CannotFit if a too-small width is given' do
      array = [
        { text: ' hello world, ' },
        { text: 'goodbye  ', style: [:bold] }
      ]
      arranger.format_array = array
      expect do
        line_wrap.wrap_line(
          arranger: arranger,
          width: 1,
          document: pdf
        )
      end.to raise_error(Prawn::Errors::CannotFit)
    end

    it 'breaks on space' do
      array = [{ text: 'hello world' }]
      arranger.format_array = array
      string = line_wrap.wrap_line(
        arranger: arranger,
        width: one_word_width,
        document: pdf
      )
      expect(string).to eq('hello')
    end

    it 'breaks on zero-width space' do
      pdf.font("#{Prawn::DATADIR}/fonts/DejaVuSans.ttf")
      array = [{ text: "hello#{Prawn::Text::ZWSP}world" }]
      arranger.format_array = array
      string = line_wrap.wrap_line(
        arranger: arranger,
        width: one_word_width,
        document: pdf
      )
      expect(string).to eq('hello')
    end

    it 'does not display zero-width space' do
      pdf.font("#{Prawn::DATADIR}/fonts/DejaVuSans.ttf")
      array = [{ text: "hello#{Prawn::Text::ZWSP}world" }]
      arranger.format_array = array
      string = line_wrap.wrap_line(
        arranger: arranger,
        width: 300,
        document: pdf
      )
      expect(string).to eq('helloworld')
    end

    it 'does not raise CannotFit if first fragment is a zero-width space' do
      pdf.font("#{Prawn::DATADIR}/fonts/DejaVuSans.ttf")
      array = [{ text: Prawn::Text::ZWSP }, { text: 'stringofchars' }]
      arranger.format_array = array
      string = line_wrap.wrap_line(
        arranger: arranger,
        width: 50,
        document: pdf
      )
      expect(string).to eq('stringof')
    end

    it 'breaks on tab' do
      array = [{ text: "hello\tworld" }]
      arranger.format_array = array
      string = line_wrap.wrap_line(
        arranger: arranger,
        width: one_word_width,
        document: pdf
      )
      expect(string).to eq('hello')
    end

    it 'does not break on NBSP' do
      array = [{ text: "hello#{Prawn::Text::NBSP}world" }]
      arranger.format_array = array
      string = line_wrap.wrap_line(
        arranger: arranger,
        width: one_word_width,
        document: pdf
      )
      expect(string).to eq("hello#{Prawn::Text::NBSP}wor")
    end

    it 'does not break on NBSP in a Win-1252 encoded string' do
      array = [{
        text: "hello#{Prawn::Text::NBSP}world".encode(Encoding::Windows_1252)
      }]
      arranger.format_array = array
      string = line_wrap.wrap_line(
        arranger: arranger,
        width: one_word_width,
        document: pdf
      )
      expect(string).to eq("hello#{Prawn::Text::NBSP}wor")
    end

    it 'breaks on hyphens' do
      array = [{ text: 'hello-world' }]
      arranger.format_array = array
      string = line_wrap.wrap_line(
        arranger: arranger,
        width: one_word_width,
        document: pdf
      )
      expect(string).to eq('hello-')
    end

    it 'does not break after a hyphen that follows white space and' \
      'precedes a word' do
      array = [{ text: 'hello -' }]
      arranger.format_array = array
      string = line_wrap.wrap_line(
        arranger: arranger,
        width: one_word_width,
        document: pdf
      )
      expect(string).to eq('hello -')

      array = [{ text: 'hello -world' }]
      arranger.format_array = array
      string = line_wrap.wrap_line(
        arranger: arranger,
        width: one_word_width,
        document: pdf
      )
      expect(string).to eq('hello')
    end

    it 'breaks on a soft hyphen' do
      string = pdf.font.normalize_encoding("hello#{Prawn::Text::SHY}world")
      array = [{ text: string }]
      arranger.format_array = array
      string = line_wrap.wrap_line(
        arranger: arranger,
        width: one_word_width,
        document: pdf
      )
      expect(string).to eq("hello#{Prawn::Text::SHY}")

      pdf.font("#{Prawn::DATADIR}/fonts/DejaVuSans.ttf")
      line_wrap = described_class.new

      string = "hello#{Prawn::Text::SHY}world"
      array = [{ text: string }]
      arranger.format_array = array
      string = line_wrap.wrap_line(
        arranger: arranger,
        width: one_word_width,
        document: pdf
      )
      expect(string).to eq("hello#{Prawn::Text::SHY}")
    end

    it 'ignores width of a soft-hyphen during adding fragments to line',
      issue: 775 do
      hyphen_string = "Hy#{Prawn::Text::SHY}phe#{Prawn::Text::SHY}nat"\
        "#{Prawn::Text::SHY}ions "
      string1 = pdf.font.normalize_encoding(hyphen_string * 5)
      string2 = pdf.font.normalize_encoding('Hyphenations ' * 3 + hyphen_string)

      array1 = [{ text: string1 }]
      array2 = [{ text: string2 }]

      arranger.format_array = array1

      res1 = line_wrap.wrap_line(
        arranger: arranger,
        width: 300,
        document: pdf
      )

      line_wrap = described_class.new

      arranger.format_array = array2

      res2 = line_wrap.wrap_line(
        arranger: arranger,
        width: 300,
        document: pdf
      )
      expect(res1).to eq(res2)
    end

    it 'does not display soft hyphens except at the end of a line ' \
      'for more than one element in format_array', issue: 347 do
      pdf.font("#{Prawn::DATADIR}/fonts/DejaVuSans.ttf")
      line_wrap = described_class.new

      string1 = pdf.font.normalize_encoding("hello#{Prawn::Text::SHY}world ")
      string2 = pdf.font.normalize_encoding("hi#{Prawn::Text::SHY}earth")
      array = [{ text: string1 }, { text: string2 }]
      arranger.format_array = array
      string = line_wrap.wrap_line(
        arranger: arranger,
        width: 300,
        document: pdf
      )
      expect(string).to eq('helloworld hiearth')
    end

    it 'does not break before a hard hyphen that follows a word' do
      enough_width_for_hello_world = 60

      array = [{ text: 'hello world' }]
      arranger.format_array = array
      string = line_wrap.wrap_line(
        arranger: arranger,
        width: enough_width_for_hello_world,
        document: pdf
      )
      expect(string).to eq('hello world')

      array = [{ text: 'hello world-' }]
      arranger.format_array = array
      string = line_wrap.wrap_line(
        arranger: arranger,
        width: enough_width_for_hello_world,
        document: pdf
      )
      expect(string).to eq('hello')

      pdf.font("#{Prawn::DATADIR}/fonts/DejaVuSans.ttf")
      line_wrap = described_class.new
      enough_width_for_hello_world = 68

      array = [{ text: 'hello world' }]
      arranger.format_array = array
      string = line_wrap.wrap_line(
        arranger: arranger,
        width: enough_width_for_hello_world,
        document: pdf
      )
      expect(string).to eq('hello world')

      array = [{ text: 'hello world-' }]
      arranger.format_array = array
      string = line_wrap.wrap_line(
        arranger: arranger,
        width: enough_width_for_hello_world,
        document: pdf
      )
      expect(string).to eq('hello')
    end

    it 'does not break after a hard hyphen that follows a soft hyphen and' \
      'precedes a word' do
      string = pdf.font.normalize_encoding("hello#{Prawn::Text::SHY}-")
      array = [{ text: string }]
      arranger.format_array = array
      string = line_wrap.wrap_line(
        arranger: arranger,
        width: one_word_width,
        document: pdf
      )
      expect(string).to eq('hello-')

      string = pdf.font.normalize_encoding("hello#{Prawn::Text::SHY}-world")
      array = [{ text: string }]
      arranger.format_array = array
      string = line_wrap.wrap_line(
        arranger: arranger,
        width: one_word_width,
        document: pdf
      )
      expect(string).to eq("hello#{Prawn::Text::SHY}")

      pdf.font("#{Prawn::DATADIR}/fonts/DejaVuSans.ttf")
      line_wrap = described_class.new

      string = "hello#{Prawn::Text::SHY}-"
      array = [{ text: string }]
      arranger.format_array = array
      string = line_wrap.wrap_line(
        arranger: arranger,
        width: one_word_width,
        document: pdf
      )
      expect(string).to eq('hello-')

      string = "hello#{Prawn::Text::SHY}-world"
      array = [{ text: string }]
      arranger.format_array = array
      string = line_wrap.wrap_line(
        arranger: arranger,
        width: one_word_width,
        document: pdf
      )
      expect(string).to eq("hello#{Prawn::Text::SHY}")
    end

    it 'does not process UTF-8 chars with default font', issue: 693 do
      array = [{ text: 'Ｔｅｓｔ' }]
      arranger.format_array = array

      expect do
        line_wrap.wrap_line(
          arranger: arranger,
          width: 300,
          document: pdf
        )
      end.to raise_exception(Prawn::Errors::IncompatibleStringEncoding)
    end

    it 'processes UTF-8 chars with UTF-8 font', issue: 693 do
      array = [{ text: 'Ｔｅｓｔ' }]
      arranger.format_array = array

      pdf.font Pathname.new("#{Prawn::DATADIR}/fonts/DejaVuSans.ttf")
      string = line_wrap.wrap_line(
        arranger: arranger,
        width: 300,
        document: pdf
      )

      expect(string).to eq('Ｔｅｓｔ')
    end
  end

  describe '#space_count' do
    let(:arranger) { Prawn::Text::Formatted::Arranger.new(pdf) }

    it 'returns the number of spaces in the last wrapped line' do
      array = [
        { text: 'hello world, ' },
        { text: 'goodbye', style: [:bold] }
      ]
      arranger.format_array = array
      line_wrap.wrap_line(
        arranger: arranger,
        width: 300,
        document: pdf
      )
      expect(line_wrap.space_count).to eq(2)
    end

    it 'excludes preceding and trailing spaces from the count' do
      array = [
        { text: ' hello world, ' },
        { text: 'goodbye  ', style: [:bold] }
      ]
      arranger.format_array = array
      line_wrap.wrap_line(
        arranger: arranger,
        width: 300,
        document: pdf
      )
      expect(line_wrap.space_count).to eq(2)
    end
  end

  describe '#paragraph_finished?' do
    let(:arranger) { Prawn::Text::Formatted::Arranger.new(pdf) }
    let(:line_wrap) { described_class.new }
    let(:one_word_width) { 50 }

    it 'is false when the last printed line is not the end of the paragraph' do
      array = [{ text: 'hello world' }]
      arranger.format_array = array
      line_wrap.wrap_line(
        arranger: arranger,
        width: one_word_width,
        document: pdf
      )

      expect(line_wrap.paragraph_finished?).to eq(false)
    end

    it 'is true when the last printed line is the last fragment to print' do
      array = [{ text: 'hello world' }]
      arranger.format_array = array
      line_wrap.wrap_line(
        arranger: arranger,
        width: one_word_width,
        document: pdf
      )
      line_wrap.wrap_line(
        arranger: arranger,
        width: one_word_width,
        document: pdf
      )

      expect(line_wrap.paragraph_finished?).to eq(true)
    end

    it 'be_trues when a newline exists on the current line' do
      array = [{ text: "hello\n world" }]
      arranger.format_array = array
      line_wrap.wrap_line(
        arranger: arranger,
        width: one_word_width,
        document: pdf
      )

      expect(line_wrap.paragraph_finished?).to eq(true)
    end

    it 'be_trues when a newline exists in the next fragment' do
      array = [
        { text: 'hello ' },
        { text: " \n" },
        { text: 'world' }
      ]
      arranger.format_array = array
      line_wrap.wrap_line(
        arranger: arranger,
        width: one_word_width,
        document: pdf
      )

      expect(line_wrap.paragraph_finished?).to eq(true)
    end
  end
end
