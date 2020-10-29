# frozen_string_literal: true

require 'spec_helper'

describe Prawn::Document do
  describe 'A Reference object' do
    describe 'generated via Prawn::Document' do
      it 'returns a proper reference on ref!' do
        pdf = described_class.new
        expect(pdf.ref!({}).is_a?(PDF::Core::Reference)).to eq(true)
      end

      it 'returns an identifier on ref' do
        pdf = described_class.new
        r = pdf.ref({})
        expect(r.is_a?(Integer)).to eq(true)
      end

      it 'has :Length of stream if it has one when compression disabled' do
        pdf = described_class.new compress: false
        ref = pdf.ref!({})
        ref << 'Hello'
        expect(ref.stream.data[:Length]).to eq(5)
      end
    end
  end
end
