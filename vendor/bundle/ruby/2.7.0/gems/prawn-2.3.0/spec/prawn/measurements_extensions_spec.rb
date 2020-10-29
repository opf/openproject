# frozen_string_literal: true

require 'spec_helper'
require 'prawn/measurement_extensions'

describe Prawn::Measurements do
  describe 'Numeric extensions' do
    it 'converts units to PostScriptPoints' do
      expect(1.mm).to be_within(0.000000001).of(2.834645669)
      expect(1.mm).to eq(72 / 25.4)
      expect(2.mm).to eq(2 * 72 / 25.4)
      expect(3.mm).to eq(3 * 72 / 25.4)
      expect(-3.mm).to eq(-3 * 72 / 25.4)
      expect(1.cm).to eq(10 * 72 / 25.4)
      expect(1.dm).to eq(100 * 72 / 25.4)
      expect(1.m).to eq(1000 * 72 / 25.4)

      expect(1.in).to eq(72)
      expect(1.ft).to eq(72 * 12)
      expect(1.yd).to eq(72 * 12 * 3)
      expect(1.pt).to eq(1)
    end
  end
end
