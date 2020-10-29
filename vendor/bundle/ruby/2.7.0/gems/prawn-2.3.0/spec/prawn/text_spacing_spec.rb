# frozen_string_literal: true

require 'spec_helper'

describe Prawn::Text do
  let(:pdf) { create_pdf }

  describe '#character_spacing' do
    it 'draws the character spacing to the document' do
      pdf.character_spacing(10.555555) do
        pdf.text('hello world')
      end
      contents = PDF::Inspector::Text.analyze(pdf.render)
      expect(contents.character_spacing.first).to eq(10.5556)
    end

    it 'does not draw the character spacing to the document' \
      ' when the new character spacing matches the old' do
      pdf.character_spacing(0) do
        pdf.text('hello world')
      end
      contents = PDF::Inspector::Text.analyze(pdf.render)
      expect(contents.character_spacing).to be_empty
    end

    it 'restores character spacing to 0' do
      pdf.character_spacing(10.555555) do
        pdf.text('hello world')
      end
      contents = PDF::Inspector::Text.analyze(pdf.render)
      expect(contents.character_spacing.last).to eq(0)
    end

    it 'functions as an accessor when no parameter given' do
      pdf.character_spacing(10.555555) do
        pdf.text('hello world')
        expect(pdf.character_spacing).to eq(10.555555)
      end
      expect(pdf.character_spacing).to eq(0)
    end

    # ensure that we properly internationalize by using the number of characters
    # in a string, not the number of bytes, to insert character spaces
    #
    it 'calculates character spacing widths by characters, not bytes' do
      pdf.font("#{Prawn::DATADIR}/fonts/gkai00mp.ttf")

      str = 'こんにちは世界'
      raw_width = nil
      pdf.character_spacing(0) do
        raw_width = pdf.width_of(str)
      end

      pdf.character_spacing(10) do
        # the new width should include six 10-pt character spaces.
        expect(pdf.width_of(str)).to be_within(0.001).of(raw_width + (10 * 6))
      end
    end
  end

  describe '#word_spacing' do
    it 'draws the word spacing to the document' do
      pdf.word_spacing(10.555555) do
        pdf.text('hello world')
      end
      contents = PDF::Inspector::Text.analyze(pdf.render)
      expect(contents.word_spacing.first).to eq(10.5556)
    end

    it 'draws the word spacing to the document' \
      ' when the new word spacing matches the old' do
      pdf.word_spacing(0) do
        pdf.text('hello world')
      end
      contents = PDF::Inspector::Text.analyze(pdf.render)
      expect(contents.word_spacing).to be_empty
    end

    it 'restores word spacing to 0' do
      pdf.word_spacing(10.555555) do
        pdf.text('hello world')
      end
      contents = PDF::Inspector::Text.analyze(pdf.render)
      expect(contents.word_spacing.last).to eq(0)
    end

    it 'functions as an accessor when no parameter given' do
      pdf.word_spacing(10.555555) do
        pdf.text('hello world')
        expect(pdf.word_spacing).to eq(10.555555)
      end
      expect(pdf.word_spacing).to eq(0)
    end
  end
end
