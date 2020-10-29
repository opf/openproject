# frozen_string_literal: true

# Spec'ing the PNG class. Not complete yet - still needs to check the
# contents of palette and transparency to ensure they're correct.
# Need to find files that have these sections first.

require 'spec_helper'

describe Prawn::Images::JPG do
  let(:img_data) { File.binread("#{Prawn::DATADIR}/images/pigs.jpg") }

  it 'reads the basic attributes correctly' do
    jpg = described_class.new(img_data)

    expect(jpg.width).to eq(604)
    expect(jpg.height).to eq(453)
    expect(jpg.bits).to eq(8)
    expect(jpg.channels).to eq(3)
  end
end
