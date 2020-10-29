# frozen_string_literal: true

require 'spec_helper'

describe Grape::Exceptions::UnknownValidator do
  describe '#message' do
    let(:error) do
      described_class.new('gt_10')
    end

    it 'contains the problem in the message' do
      expect(error.message).to include(
        'unknown validator: gt_10'
      )
    end
  end
end
