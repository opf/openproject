# frozen_string_literal: true

require 'spec_helper'

describe Grape::Exceptions::Validation do
  it 'fails when params are missing' do
    expect { Grape::Exceptions::Validation.new(message: 'presence') }.to raise_error(ArgumentError, /missing keyword:.+?params/)
  end
  context 'when message is a symbol' do
    it 'stores message_key' do
      expect(Grape::Exceptions::Validation.new(params: ['id'], message: :presence).message_key).to eq(:presence)
    end
  end
  context 'when message is a String' do
    it 'does not store the message_key' do
      expect(Grape::Exceptions::Validation.new(params: ['id'], message: 'presence').message_key).to eq(nil)
    end
  end
end
