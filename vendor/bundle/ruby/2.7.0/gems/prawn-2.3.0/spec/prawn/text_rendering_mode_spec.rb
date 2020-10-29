# frozen_string_literal: true

require 'spec_helper'

describe Prawn::Text do
  let(:pdf) { create_pdf }

  describe '#text_rendering_mode' do
    it 'draws the text rendering mode to the document' do
      pdf.text_rendering_mode(:stroke) do
        pdf.text('hello world')
      end
      contents = PDF::Inspector::Text.analyze(pdf.render)
      expect(contents.text_rendering_mode.first).to eq(1)
    end

    it 'does not draw the text rendering mode to the document' \
      ' when the new mode matches the old' do
      pdf.text_rendering_mode(:fill) do
        pdf.text('hello world')
      end
      contents = PDF::Inspector::Text.analyze(pdf.render)
      expect(contents.text_rendering_mode).to be_empty
    end

    it 'restores character spacing to 0' do
      pdf.text_rendering_mode(:stroke) do
        pdf.text('hello world')
      end
      contents = PDF::Inspector::Text.analyze(pdf.render)
      expect(contents.text_rendering_mode).to eq([1, 0])
    end

    it 'functions as an accessor when no parameter given' do
      pdf.text_rendering_mode(:fill_stroke) do
        pdf.text('hello world')
        expect(pdf.text_rendering_mode).to eq(:fill_stroke)
      end
      expect(pdf.text_rendering_mode).to eq(:fill)
    end

    it 'raise_errors an exception when passed an invalid mode' do
      expect { pdf.text_rendering_mode(-1) }.to raise_error(ArgumentError)
      expect { pdf.text_rendering_mode(8) }.to raise_error(ArgumentError)
      expect { pdf.text_rendering_mode(:flil) }.to raise_error(ArgumentError)
    end
  end
end
