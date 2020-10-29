# frozen_string_literal: true

require 'spec_helper'

describe Prawn::Text::Formatted::Fragment do
  let(:pdf) { create_pdf }

  describe 'Text::Formatted::Fragment' do
    let(:fragment) do
      format_state = {
        styles: %i[bold italic],
        color: nil,
        link: nil,
        anchor: nil,
        font: nil,
        size: nil
      }
      described_class.new(
        'hello world',
        format_state,
        pdf
      ).tap do |fragment|
        fragment.width = 100
        fragment.left = 50
        fragment.baseline = 200
        fragment.line_height = 27
        fragment.descender = 7
        fragment.ascender = 17
      end
    end

    describe '#width' do
      it 'returns the width' do
        expect(fragment.width).to eq(100)
      end
    end

    describe '#styles' do
      it 'returns the styles array' do
        expect(fragment.styles).to eq(%i[bold italic])
      end

      it 'nevers return nil' do
        format_state = {
          styles: nil,
          color: nil,
          link: nil,
          anchor: nil,
          font: nil,
          size: nil
        }
        fragment = described_class.new(
          'hello world',
          format_state,
          pdf
        )
        expect(fragment.styles).to eq([])
      end
    end

    describe '#line_height' do
      it 'returns the line_height' do
        expect(fragment.line_height).to eq(27)
      end
    end

    describe '#ascender' do
      it 'returns the ascender' do
        expect(fragment.ascender).to eq(17)
      end
    end

    describe '#descender' do
      it 'returns the descender' do
        expect(fragment.descender).to eq(7)
      end
    end

    describe '#y_offset' do
      it 'is zero' do
        expect(fragment.y_offset).to eq(0)
      end
    end

    describe '#bounding_box' do
      it 'returns the bounding box surrounding the fragment' do
        target_box = [50, 193, 150, 217]
        expect(fragment.bounding_box).to eq(target_box)
      end
    end

    describe '#absolute_bounding_box' do
      it 'returns the bounding box surrounding the fragment' \
        ' in absolute coordinates' do
        target_box = [50, 193, 150, 217]
        target_box[0] += pdf.bounds.absolute_left
        target_box[1] += pdf.bounds.absolute_bottom
        target_box[2] += pdf.bounds.absolute_left
        target_box[3] += pdf.bounds.absolute_bottom

        expect(fragment.absolute_bounding_box).to eq(target_box)
      end
    end

    describe '#underline_points' do
      it 'defines a line under the fragment' do
        y = 198.75
        target_points = [[50, y], [150, y]]
        expect(fragment.underline_points).to eq(target_points)
      end
    end

    describe '#strikethrough_points' do
      it 'defines a line through the fragment' do
        y = 200 + fragment.ascender * 0.3
        target_points = [[50, y], [150, y]]
        expect(fragment.strikethrough_points).to eq(target_points)
      end
    end
  end

  describe '#space_count' do
    it 'returns the number of spaces in the fragment' do
      format_state = {}
      fragment = described_class.new(
        'hello world ',
        format_state,
        pdf
      )
      expect(fragment.space_count).to eq(2)
    end

    it 'excludes trailing spaces from the count when ' \
      ':exclude_trailing_white_space => true' do
      format_state = { exclude_trailing_white_space: true }
      fragment = described_class.new(
        'hello world ',
        format_state,
        pdf
      )
      expect(fragment.space_count).to eq(1)
    end
  end

  describe '#include_trailing_white_space!' do
    it 'makes the fragment include trailing white space' do
      format_state = { exclude_trailing_white_space: true }
      fragment = described_class.new(
        'hello world ',
        format_state,
        pdf
      )
      expect(fragment.space_count).to eq(1)
      fragment.include_trailing_white_space!
      expect(fragment.space_count).to eq(2)
    end
  end

  describe '#text' do
    it 'returns the fragment text' do
      format_state = {}
      fragment = described_class.new(
        'hello world ',
        format_state,
        pdf
      )
      expect(fragment.text).to eq('hello world ')
    end

    it 'returns the fragment text without trailing spaces when ' \
      ':exclude_trailing_white_space => true' do
      format_state = { exclude_trailing_white_space: true }
      fragment = described_class.new(
        'hello world ',
        format_state,
        pdf
      )
      expect(fragment.text).to eq('hello world')
    end
  end

  describe '#word_spacing=' do
    let(:fragment) do
      format_state = {
        styles: %i[bold italic],
        color: nil,
        link: nil,
        anchor: nil,
        font: nil,
        size: nil
      }
      described_class.new(
        'hello world',
        format_state,
        pdf
      ).tap do |fragment|
        fragment.width = 100
        fragment.left = 50
        fragment.baseline = 200
        fragment.line_height = 27
        fragment.descender = 7
        fragment.ascender = 17
        fragment.word_spacing = 10
      end
    end

    it 'accounts for word_spacing in #width' do
      expect(fragment.width).to eq(110)
    end

    it 'accounts for word_spacing in #bounding_box' do
      target_box = [50, 193, 160, 217]
      expect(fragment.bounding_box).to eq(target_box)
    end

    it 'accounts for word_spacing in #absolute_bounding_box' do
      target_box = [50, 193, 160, 217]
      target_box[0] += pdf.bounds.absolute_left
      target_box[1] += pdf.bounds.absolute_bottom
      target_box[2] += pdf.bounds.absolute_left
      target_box[3] += pdf.bounds.absolute_bottom
      expect(fragment.absolute_bounding_box).to eq(target_box)
    end

    it 'accounts for word_spacing in #underline_points' do
      y = 198.75
      target_points = [[50, y], [160, y]]
      expect(fragment.underline_points).to eq(target_points)
    end

    it 'accounts for word_spacing in #strikethrough_points' do
      y = 200 + fragment.ascender * 0.3
      target_points = [[50, y], [160, y]]
      expect(fragment.strikethrough_points).to eq(target_points)
    end
  end

  describe 'subscript' do
    let(:fragment) do
      format_state = {
        styles: [:subscript],
        color: nil,
        link: nil,
        anchor: nil,
        font: nil,
        size: nil
      }
      described_class.new(
        'hello world',
        format_state,
        pdf
      ).tap do |fragment|
        fragment.line_height = 27
        fragment.descender = 7
        fragment.ascender = 17
      end
    end

    describe '#subscript?' do
      it 'be_trues' do
        expect(fragment).to be_subscript
      end
    end

    describe '#y_offset' do
      it 'returns a negative value' do
        expect(fragment.y_offset).to be < 0
      end
    end
  end

  describe 'superscript' do
    let(:fragment) do
      format_state = {
        styles: [:superscript],
        color: nil,
        link: nil,
        anchor: nil,
        font: nil,
        size: nil
      }
      described_class.new(
        'hello world',
        format_state,
        pdf
      ).tap do |fragment|
        fragment.line_height = 27
        fragment.descender = 7
        fragment.ascender = 17
      end
    end

    describe '#superscript?' do
      it 'be_trues' do
        expect(fragment).to be_superscript
      end
    end

    describe '#y_offset' do
      it 'returns a positive value' do
        expect(fragment.y_offset).to be > 0
      end
    end
  end

  context 'with :direction => :rtl' do
    it '#text should be reversed' do
      format_state = { direction: :rtl }
      fragment = described_class.new(
        'hello world',
        format_state,
        pdf
      )
      expect(fragment.text).to eq('dlrow olleh')
    end
  end

  describe '#default_direction=' do
    it 'sets the direction if there is no fragment level direction ' \
      'specification' do
      format_state = {}
      fragment = described_class.new(
        'hello world',
        format_state,
        pdf
      )
      fragment.default_direction = :rtl
      expect(fragment.direction).to eq(:rtl)
    end

    it 'does not set the direction if there is a fragment level direction ' \
      'specification' do
      format_state = { direction: :rtl }
      fragment = described_class.new(
        'hello world',
        format_state,
        pdf
      )
      fragment.default_direction = :ltr
      expect(fragment.direction).to eq(:rtl)
    end
  end
end
