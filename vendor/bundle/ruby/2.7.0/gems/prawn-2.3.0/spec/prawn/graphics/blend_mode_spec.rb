# frozen_string_literal: true

require 'spec_helper'

describe Prawn::Graphics::BlendMode do
  def make_blend_mode(blend_mode)
    pdf.blend_mode(blend_mode) do
      yield if block_given?
    end
  end

  let(:pdf) { create_pdf }

  it 'the PDF version should be at least 1.4' do
    make_blend_mode(:Multiply)
    str = pdf.render
    expect(str[0, 8]).to eq('%PDF-1.4')
  end

  it 'a new extended graphics state should be created for ' \
     'each unique blend mode setting' do
    make_blend_mode(:Multiply) do
      make_blend_mode(:Screen)
    end
    extgstates = PDF::Inspector::ExtGState.analyze(pdf.render).extgstates
    expect(extgstates.length).to eq(2)
  end

  it 'a new extended graphics state should not be created for ' \
     'each duplicate blend mode setting' do
    make_blend_mode(:Multiply) do
      make_blend_mode(:Multiply)
    end
    extgstates = PDF::Inspector::ExtGState.analyze(pdf.render).extgstates
    expect(extgstates.length).to eq(1)
  end

  it 'setting the blend mode with only one parameter sets a single '\
    'blend mode value' do
    make_blend_mode(:Multiply)
    extgstate = PDF::Inspector::ExtGState.analyze(pdf.render).extgstates.first
    expect(extgstate[:blend_mode]).to eq(:Multiply)
  end

  it 'setting the blend mode with multiple parameters sets an array of '\
    'blend modes' do
    make_blend_mode(%i[Multiply Screen Overlay])
    extgstate = PDF::Inspector::ExtGState.analyze(pdf.render).extgstates.first
    expect(extgstate[:blend_mode]).to eq(%i[Multiply Screen Overlay])
  end

  describe 'with more than one page' do
    it 'the extended graphic state resource should be added to both pages' do
      make_blend_mode(:Multiply)
      pdf.start_new_page
      make_blend_mode(:Multiply)
      extgstates = PDF::Inspector::ExtGState.analyze(pdf.render).extgstates
      extgstate = extgstates[0]
      expect(extgstates.length).to eq(2)
      expect(extgstate[:blend_mode]).to eq(:Multiply)
    end
  end
end
