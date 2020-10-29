# frozen_string_literal: true

require 'spec_helper'

describe Prawn::Document do
  let(:pdf) { create_pdf }

  it 'onlies accept :position as option in debug mode' do
    Prawn.debug = true
    expect { pdf.span(350, x: 3) {} }
      .to raise_error(Prawn::Errors::UnknownOption)
  end

  it 'has raise an error if :position is invalid' do
    expect { pdf.span(350, position: :x) {} }.to raise_error(ArgumentError)
  end

  it 'restores the margin box when bounding box exits' do
    margin_box = pdf.bounds

    pdf.span(350, position: :center) do
      pdf.text "Here's some centered text in a 350 point column. " * 100
    end

    expect(pdf.bounds).to eq(margin_box)
  end

  it 'does create a margin box' do
    margin_box = pdf.span(350, position: :center) do
      pdf.text "Here's some centered text in a 350 point column. " * 100
    end

    expect(margin_box.top).to eq(792.0)
    expect(margin_box.bottom).to eq(0)
  end
end
