# frozen_string_literal: true

require 'spec_helper'

describe Prawn::Graphics do
  let(:pdf) { create_pdf }

  describe 'When stroking with default settings' do
    it 'cap_style should be :butt' do
      expect(pdf.cap_style).to eq(:butt)
    end

    it 'join_style should be :miter' do
      expect(pdf.join_style).to eq(:miter)
    end

    it 'dashed? should be_false' do
      expect(pdf).to_not be_dashed
    end
  end

  describe 'Cap styles' do
    it 'is able to use assignment operator' do
      pdf.cap_style = :round
      expect(pdf.cap_style).to eq(:round)
    end

    describe '#cap_style(:butt)' do
      it 'rendered PDF should include butt style cap' do
        pdf.cap_style(:butt)
        cap_style = PDF::Inspector::Graphics::CapStyle.analyze(pdf.render)
          .cap_style
        expect(cap_style).to eq(0)
      end
    end

    describe '#cap_style(:round)' do
      it 'rendered PDF should include round style cap' do
        pdf.cap_style(:round)
        cap_style = PDF::Inspector::Graphics::CapStyle.analyze(pdf.render)
          .cap_style
        expect(cap_style).to eq(1)
      end
    end

    describe '#cap_style(:projecting_square)' do
      it 'rendered PDF should include projecting_square style cap' do
        pdf.cap_style(:projecting_square)
        cap_style = PDF::Inspector::Graphics::CapStyle.analyze(pdf.render)
          .cap_style
        expect(cap_style).to eq(2)
      end
    end

    it 'carries the current cap style settings over to new pages' do
      pdf.cap_style(:round)
      pdf.start_new_page
      cap_styles = PDF::Inspector::Graphics::CapStyle.analyze(pdf.render)
      expect(cap_styles.cap_style_count).to eq(2)
      expect(cap_styles.cap_style).to eq(1)
    end
  end

  describe 'Join styles' do
    it 'is able to use assignment operator' do
      pdf.join_style = :round
      expect(pdf.join_style).to eq(:round)
    end

    describe '#join_style(:miter)' do
      it 'rendered PDF should include miter style join' do
        pdf.join_style(:miter)
        join_style = PDF::Inspector::Graphics::JoinStyle.analyze(pdf.render)
          .join_style
        expect(join_style).to eq(0)
      end
    end

    describe '#join_style(:round)' do
      it 'rendered PDF should include round style join' do
        pdf.join_style(:round)
        join_style = PDF::Inspector::Graphics::JoinStyle.analyze(pdf.render)
          .join_style
        expect(join_style).to eq(1)
      end
    end

    describe '#join_style(:bevel)' do
      it 'rendered PDF should include bevel style join' do
        pdf.join_style(:bevel)
        join_style = PDF::Inspector::Graphics::JoinStyle.analyze(pdf.render)
          .join_style
        expect(join_style).to eq(2)
      end
    end

    it 'carries the current join style settings over to new pages' do
      pdf.join_style(:round)
      pdf.start_new_page
      join_styles = PDF::Inspector::Graphics::JoinStyle.analyze(pdf.render)
      expect(join_styles.join_style_count).to eq(2)
      expect(join_styles.join_style).to eq(1)
    end

    context 'with invalid arguments' do
      it 'raises an exception' do
        expect { pdf.join_style(:mitre) }
          .to raise_error(Prawn::Errors::InvalidJoinStyle)
      end
    end
  end

  describe 'Dashes' do
    it 'is able to use assignment operator' do
      pdf.dash = 2
      expect(pdf).to be_dashed
    end

    describe 'setting a dash' do
      it 'dashed? should be_true' do
        pdf.dash(2)
        expect(pdf).to be_dashed
      end

      it 'rendered PDF should include a stroked dash' do
        pdf.dash(2)
        dashes = PDF::Inspector::Graphics::Dash.analyze(pdf.render)
        expect(dashes.stroke_dash).to eq([[2, 2], 0])
      end
    end

    describe 'setting a dash by passing a single argument' do
      it 'space between dashes should be the same length as the dash in the '\
        'rendered PDF' do
        pdf.dash(2)
        dashes = PDF::Inspector::Graphics::Dash.analyze(pdf.render)
        expect(dashes.stroke_dash).to eq([[2, 2], 0])
      end
    end

    describe 'with a space option that differs from the first argument' do
      it 'space between dashes in the rendered PDF should be different length '\
        'than the length of the dash' do
        pdf.dash(2, space: 3)
        dashes = PDF::Inspector::Graphics::Dash.analyze(pdf.render)
        expect(dashes.stroke_dash).to eq([[2, 3], 0])
      end
    end

    describe 'with a non-zero phase option' do
      it 'rendered PDF should include a non-zero phase' do
        pdf.dash(2, phase: 1)
        dashes = PDF::Inspector::Graphics::Dash.analyze(pdf.render)
        expect(dashes.stroke_dash).to eq([[2, 2], 1])
      end
    end

    describe 'setting a dash by using an array' do
      it 'dash and spaces should be set from the array' do
        pdf.dash([1, 2, 3, 4])
        dashes = PDF::Inspector::Graphics::Dash.analyze(pdf.render)
        expect(dashes.stroke_dash).to eq([[1, 2, 3, 4], 0])
      end

      it 'at least one number in the array must not be zero' do
        pdf.dash([1, 0])
        dashes = PDF::Inspector::Graphics::Dash.analyze(pdf.render)
        expect(dashes.stroke_dash).to eq([[1, 0], 0])
      end

      it 'space options has to be ignored' do
        pdf.dash([1, 2, 3, 4], space: 3)
        dashes = PDF::Inspector::Graphics::Dash.analyze(pdf.render)
        expect(dashes.stroke_dash).to eq([[1, 2, 3, 4], 0])
      end

      it 'phase options should be correctly used' do
        pdf.dash([1, 2, 3, 4], phase: 3)
        dashes = PDF::Inspector::Graphics::Dash.analyze(pdf.render)
        expect(dashes.stroke_dash).to eq([[1, 2, 3, 4], 3])
      end
    end

    describe 'clearing stroke dash' do
      it 'restores solid line' do
        pdf.dash(2)
        pdf.undash
        dashes = PDF::Inspector::Graphics::Dash.analyze(pdf.render)
        expect(dashes.stroke_dash).to eq([[], 0])
      end
    end

    it 'carries the current dash settings over to new pages' do
      pdf.dash(2)
      pdf.start_new_page
      dashes = PDF::Inspector::Graphics::Dash.analyze(pdf.render)
      expect(dashes.stroke_dash_count).to eq(2)
      expect(dashes.stroke_dash).to eq([[2, 2], 0])
    end

    describe '#dashed?' do
      it 'an initial document should not be dashed' do
        expect(pdf.dashed?).to eq(false)
      end

      it 'returns true if any of the currently active settings are dashed' do
        pdf.dash(2)
        pdf.save_graphics_state
        expect(pdf.dashed?).to eq(true)
      end

      it 'returns false if the document was most recently undashed' do
        pdf.dash(2)
        pdf.save_graphics_state
        pdf.undash
        pdf.save_graphics_state
        expect(pdf.dashed?).to eq(false)
      end

      it 'returns true when restoring to a state that was dashed' do
        pdf.dash(2)
        pdf.save_graphics_state
        pdf.undash
        pdf.restore_graphics_state
        expect(pdf.dashed?).to eq(true)
      end
    end
  end
end
