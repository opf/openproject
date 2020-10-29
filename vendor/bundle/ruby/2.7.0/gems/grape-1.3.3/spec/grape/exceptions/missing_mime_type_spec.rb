# frozen_string_literal: true

require 'spec_helper'

describe Grape::Exceptions::MissingMimeType do
  describe '#message' do
    let(:error) do
      described_class.new('new_json')
    end

    it 'contains the problem in the message' do
      expect(error.message).to include 'missing mime type for new_json'
    end

    it 'contains the resolution in the message' do
      expect(error.message).to include "or add your own with content_type :new_json, 'application/new_json' "
    end
  end
end
