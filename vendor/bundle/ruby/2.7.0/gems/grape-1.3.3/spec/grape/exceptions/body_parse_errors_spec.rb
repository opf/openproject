# frozen_string_literal: true

require 'spec_helper'

describe Grape::Exceptions::ValidationErrors do
  context 'api with rescue_from :all handler' do
    subject { Class.new(Grape::API) }
    before do
      subject.rescue_from :all do |_e|
        rack_response 'message was processed', 400
      end
      subject.params do
        requires :beer
      end
      subject.post '/beer' do
        'beer received'
      end
    end

    def app
      subject
    end

    context 'with content_type json' do
      it 'can recover from failed body parsing' do
        post '/beer', 'test', 'CONTENT_TYPE' => 'application/json'
        expect(last_response.status).to eq 400
        expect(last_response.body).to eq('message was processed')
      end
    end

    context 'with content_type xml' do
      it 'can recover from failed body parsing' do
        post '/beer', 'test', 'CONTENT_TYPE' => 'application/xml'
        expect(last_response.status).to eq 400
        expect(last_response.body).to eq('message was processed')
      end
    end

    context 'with content_type text' do
      it 'can recover from failed body parsing' do
        post '/beer', 'test', 'CONTENT_TYPE' => 'text/plain'
        expect(last_response.status).to eq 400
        expect(last_response.body).to eq('message was processed')
      end
    end

    context 'with no specific content_type' do
      it 'can recover from failed body parsing' do
        post '/beer', 'test', {}
        expect(last_response.status).to eq 400
        expect(last_response.body).to eq('message was processed')
      end
    end
  end

  context 'api with rescue_from :grape_exceptions handler' do
    subject { Class.new(Grape::API) }
    before do
      subject.rescue_from :all do |_e|
        rack_response 'message was processed', 400
      end
      subject.rescue_from :grape_exceptions

      subject.params do
        requires :beer
      end
      subject.post '/beer' do
        'beer received'
      end
    end

    def app
      subject
    end

    context 'with content_type json' do
      it 'returns body parsing error message' do
        post '/beer', 'test', 'CONTENT_TYPE' => 'application/json'
        expect(last_response.status).to eq 400
        expect(last_response.body).to include 'message body does not match declared format'
      end
    end

    context 'with content_type xml' do
      it 'returns body parsing error message' do
        post '/beer', 'test', 'CONTENT_TYPE' => 'application/xml'
        expect(last_response.status).to eq 400
        expect(last_response.body).to include 'message body does not match declared format'
      end
    end
  end

  context 'api without a rescue handler' do
    subject { Class.new(Grape::API) }
    before do
      subject.params do
        requires :beer
      end
      subject.post '/beer' do
        'beer received'
      end
    end

    def app
      subject
    end

    context 'and with content_type json' do
      it 'can recover from failed body parsing' do
        post '/beer', 'test', 'CONTENT_TYPE' => 'application/json'
        expect(last_response.status).to eq 400
        expect(last_response.body).to include('message body does not match declared format')
        expect(last_response.body).to include('application/json')
      end
    end

    context 'with content_type xml' do
      it 'can recover from failed body parsing' do
        post '/beer', 'test', 'CONTENT_TYPE' => 'application/xml'
        expect(last_response.status).to eq 400
        expect(last_response.body).to include('message body does not match declared format')
        expect(last_response.body).to include('application/xml')
      end
    end

    context 'with content_type text' do
      it 'can recover from failed body parsing' do
        post '/beer', 'test', 'CONTENT_TYPE' => 'text/plain'
        expect(last_response.status).to eq 400
        expect(last_response.body).to eq('beer is missing')
      end
    end

    context 'and with no specific content_type' do
      it 'can recover from failed body parsing' do
        post '/beer', 'test', {}
        expect(last_response.status).to eq 400
        # plain response with text/html
        expect(last_response.body).to eq('beer is missing')
      end
    end
  end
end
