# frozen_string_literal: true

require 'spec_helper'

describe Prawn::Text do
  describe '#draw_text' do
    let(:pdf) { create_pdf }

    it 'raise_errors ArgumentError if :at option omitted' do
      expect { pdf.draw_text('hai', {}) }.to raise_error(ArgumentError)
    end

    it 'raise_errors ArgumentError if :align option included' do
      expect do
        pdf.draw_text('hai', at: [0, 0], align: :center)
      end.to raise_error(ArgumentError)
    end

    it 'allows drawing empty strings to the page' do
      pdf.draw_text(' ', at: [100, 100])
      text = PDF::Inspector::Text.analyze(pdf.render)
      expect(text.strings.first).to eq(' ')
    end

    it 'defaults to 12 point helvetica' do
      pdf.draw_text('Blah', at: [100, 100])
      text = PDF::Inspector::Text.analyze(pdf.render)
      expect(text.font_settings[0][:name]).to eq(:Helvetica)
      expect(text.font_settings[0][:size]).to eq(12)
      expect(text.strings.first).to eq('Blah')
    end

    it 'allows setting font size' do
      pdf.draw_text('Blah', at: [100, 100], size: 16)
      text = PDF::Inspector::Text.analyze(pdf.render)
      expect(text.font_settings[0][:size]).to eq(16)
    end

    it 'allows setting a default font size' do
      pdf.font_size = 16
      pdf.draw_text('Blah', at: [0, 0])

      text = PDF::Inspector::Text.analyze(pdf.render)
      expect(text.font_settings[0][:size]).to eq(16)
    end

    # rubocop: disable Naming/AccessorMethodName
    rotated_text_inspector = Class.new(PDF::Inspector) do
      attr_reader :tm_operator_used

      def initialize
        @tm_operator_used = false
      end

      def set_text_matrix_and_text_line_matrix(*_arguments)
        @tm_operator_used = true
      end
    end
    # rubocop: enable Naming/AccessorMethodName

    it 'allows rotation' do
      pdf.draw_text('Test', at: [100, 100], rotate: 90)

      text = rotated_text_inspector.analyze(pdf.render)

      expect(text.tm_operator_used).to eq true
    end

    it 'does not use rotation matrix by default' do
      pdf.draw_text('Test', at: [100, 100])

      text = rotated_text_inspector.analyze(pdf.render)

      expect(text.tm_operator_used).to eq false
    end

    it 'allows overriding default font for a single instance' do
      pdf.font_size = 16

      pdf.draw_text('Blah', size: 11, at: [0, 0])
      pdf.draw_text('Blaz', at: [0, 0])
      text = PDF::Inspector::Text.analyze(pdf.render)
      expect(text.font_settings[0][:size]).to eq(11)
      expect(text.font_settings[1][:size]).to eq(16)
    end

    it 'allows setting a font size transaction with a block' do
      pdf.font_size 16 do
        pdf.draw_text('Blah', at: [0, 0])
      end

      pdf.draw_text('blah', at: [0, 0])

      text = PDF::Inspector::Text.analyze(pdf.render)
      expect(text.font_settings[0][:size]).to eq(16)
      expect(text.font_settings[1][:size]).to eq(12)
    end

    it 'allows manual setting the font size when in a font size block' do
      pdf.font_size(16) do
        pdf.draw_text('Foo', at: [0, 0])
        pdf.draw_text('Blah', size: 11, at: [0, 0])
        pdf.draw_text('Blaz', at: [0, 0])
      end
      text = PDF::Inspector::Text.analyze(pdf.render)
      expect(text.font_settings[0][:size]).to eq(16)
      expect(text.font_settings[1][:size]).to eq(11)
      expect(text.font_settings[2][:size]).to eq(16)
    end

    it 'allows registering of built-in font_settings on the fly' do
      pdf.font 'Times-Roman'
      pdf.draw_text('Blah', at: [100, 100])
      pdf.font 'Courier'
      pdf.draw_text('Blaz', at: [150, 150])
      text = PDF::Inspector::Text.analyze(pdf.render)
      expect(text.font_settings[0][:name]).to eq(:"Times-Roman")
      expect(text.font_settings[1][:name]).to eq(:Courier)
    end

    it 'raise_errors an exception when an unknown font is used' do
      expect { pdf.font 'Pao bu' }.to raise_error(Prawn::Errors::UnknownFont)
    end

    it 'correctlies render a utf-8 string when using a built-in font' do
      str = '©' # copyright symbol
      pdf.draw_text(str, at: [0, 0])

      # grab the text from the rendered PDF and ensure it matches
      text = PDF::Inspector::Text.analyze(pdf.render)
      expect(text.strings.first).to eq(str)
    end

    it 'raises an exception when a utf-8 incompatible string is rendered' do
      str = "Blah \xDD"
      expect { pdf.draw_text(str, at: [0, 0]) }.to raise_error(
        Prawn::Errors::IncompatibleStringEncoding
      )
    end

    it 'does not raise an exception when a shift-jis string is rendered' do
      datafile = "#{Prawn::DATADIR}/shift_jis_text.txt"
      sjis_str = File.open(datafile, 'r:shift_jis', &:gets)
      pdf.font("#{Prawn::DATADIR}/fonts/gkai00mp.ttf")

      pdf.draw_text(sjis_str, at: [0, 0])
    end
  end
end
