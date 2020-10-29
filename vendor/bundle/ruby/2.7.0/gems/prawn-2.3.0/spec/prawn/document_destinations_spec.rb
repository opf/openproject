# frozen_string_literal: true

require 'spec_helper'

describe Prawn::Document do
  describe 'When creating destinations' do
    let(:pdf) { create_pdf }

    it 'adds entry to Dests name tree' do
      expect(pdf.dests.data.empty?).to eq(true)
      pdf.add_dest 'candy', 'chocolate'
      expect(pdf.dests.data.size).to eq(1)
    end
  end
end
