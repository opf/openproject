# frozen_string_literal: true

require 'spec_helper'

describe Grape::Exceptions::MissingOption do
  describe '#message' do
    let(:error) do
      described_class.new(:path)
    end

    it 'contains the problem in the message' do
      expect(error.message).to include(
        'You must specify :path options.'
      )
    end
  end
end
