# frozen_string_literal: true

require 'spec_helper'

describe Grape::Exceptions::InvalidVersionerOption do
  describe '#message' do
    let(:error) do
      described_class.new('headers')
    end

    it 'contains the problem in the message' do
      expect(error.message).to include(
        'Unknown :using for versioner: headers'
      )
    end
  end
end
