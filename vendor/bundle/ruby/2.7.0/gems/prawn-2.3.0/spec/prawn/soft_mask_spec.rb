# frozen_string_literal: true

require 'spec_helper'

describe Prawn::SoftMask do
  let(:pdf) { create_pdf }

  def make_soft_mask
    pdf.save_graphics_state do
      pdf.soft_mask do
        if block_given?
          yield
        else
          pdf.fill_color '808080'
          pdf.fill_rectangle [100, 100], 200, 200
        end
      end

      pdf.fill_color '000000'
      pdf.fill_rectangle [0, 0], 200, 200
    end
  end

  it 'has PDF version at least 1.4' do
    make_soft_mask
    str = pdf.render
    expect(str[0, 8]).to eq('%PDF-1.4')
  end

  it 'creates a new extended graphics state for each unique soft mask' do
    make_soft_mask do
      pdf.fill_color '808080'
      pdf.fill_rectangle [100, 100], 200, 200
    end

    make_soft_mask do
      pdf.fill_color '808080'
      pdf.fill_rectangle [10, 10], 200, 200
    end

    extgstates = PDF::Inspector::ExtGState.analyze(pdf.render).extgstates
    expect(extgstates.length).to eq(2)
  end

  it 'a new extended graphics state contains soft mask with drawing '\
    'instructions' do
    make_soft_mask do
      pdf.fill_color '808080'
      pdf.fill_rectangle [100, 100], 200, 200
    end

    extgstate = PDF::Inspector::ExtGState.analyze(pdf.render).extgstates.first
    expect(extgstate[:soft_mask][:G].data).to eq(
      "q\n/DeviceRGB cs\n0.0 0.0 0.0 scn\n/DeviceRGB CS\n0.0 0.0 0.0 SCN\n"\
      "1 w\n0 J\n0 j\n[] 0 d\n/DeviceRGB cs\n0.502 0.502 0.502 scn\n"\
      "100.0 -100.0 200.0 200.0 re\nf\nQ\n"
    )
  end

  it 'does not create duplicate extended graphics states' do
    make_soft_mask do
      pdf.fill_color '808080'
      pdf.fill_rectangle [100, 100], 200, 200
    end

    make_soft_mask do
      pdf.fill_color '808080'
      pdf.fill_rectangle [100, 100], 200, 200
    end

    extgstates = PDF::Inspector::ExtGState.analyze(pdf.render).extgstates
    expect(extgstates.length).to eq(1)
  end
end
