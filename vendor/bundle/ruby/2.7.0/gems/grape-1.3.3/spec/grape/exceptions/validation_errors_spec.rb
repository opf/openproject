# frozen_string_literal: true

require 'spec_helper'
require 'ostruct'

describe Grape::Exceptions::ValidationErrors do
  let(:validation_message) { 'FooBar is invalid' }
  let(:validation_error) { OpenStruct.new(params: [validation_message]) }

  context 'initialize' do
    let(:headers) do
      {
        'A-Header-Key' => 'A-Header-Value'
      }
    end

    subject do
      described_class.new(errors: [validation_error], headers: headers)
    end

    it 'should assign headers through base class' do
      expect(subject.headers).to eq(headers)
    end
  end

  context 'message' do
    context 'is not repeated' do
      let(:error) do
        described_class.new(errors: [validation_error, validation_error])
      end
      subject(:message) { error.message.split(',').map(&:strip) }

      it { expect(message).to include validation_message }
      it { expect(message.size).to eq 1 }
    end
  end

  describe '#full_messages' do
    context 'with errors' do
      let(:validation_error_1) { Grape::Exceptions::Validation.new(params: ['id'], message: :presence) }
      let(:validation_error_2) { Grape::Exceptions::Validation.new(params: ['name'], message: :presence) }
      subject { described_class.new(errors: [validation_error_1, validation_error_2]).full_messages }

      it 'returns an array with each errors full message' do
        expect(subject).to contain_exactly('id is missing', 'name is missing')
      end
    end

    context 'when attributes is an array of symbols' do
      let(:validation_error) { Grape::Exceptions::Validation.new(params: [:admin_field], message: 'Can not set admin-only field') }
      subject { described_class.new(errors: [validation_error]).full_messages }

      it 'returns an array with an error full message' do
        expect(subject.first).to eq('admin_field Can not set admin-only field')
      end
    end
  end

  context 'api' do
    subject { Class.new(Grape::API) }

    def app
      subject
    end

    it 'can return structured json with separate fields' do
      subject.format :json
      subject.rescue_from Grape::Exceptions::ValidationErrors do |e|
        error!(e, 400)
      end
      subject.params do
        optional :beer
        optional :wine
        optional :juice
        exactly_one_of :beer, :wine, :juice
      end
      subject.get '/exactly_one_of' do
        'exactly_one_of works!'
      end
      get '/exactly_one_of', beer: 'string', wine: 'anotherstring'
      expect(last_response.status).to eq(400)
      expect(JSON.parse(last_response.body)).to eq(
        [
          'params' => %w[beer wine],
          'messages' => ['are mutually exclusive']
        ]
      )
    end
  end
end
