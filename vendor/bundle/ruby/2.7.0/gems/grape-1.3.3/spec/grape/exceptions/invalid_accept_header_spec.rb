# frozen_string_literal: true

require 'spec_helper'

describe Grape::Exceptions::InvalidAcceptHeader do
  shared_examples_for 'a valid request' do
    it 'does return with status 200' do
      expect(last_response.status).to eq 200
    end
    it 'does return the expected result' do
      expect(last_response.body).to eq('beer received')
    end
  end
  shared_examples_for 'a cascaded request' do
    it 'does not find a matching route' do
      expect(last_response.status).to eq 404
    end
  end
  shared_examples_for 'a not-cascaded request' do
    it 'does not include the X-Cascade=pass header' do
      expect(last_response.headers['X-Cascade']).to be_nil
    end
    it 'does not accept the request' do
      expect(last_response.status).to eq 406
    end
  end
  shared_examples_for 'a rescued request' do
    it 'does not include the X-Cascade=pass header' do
      expect(last_response.headers['X-Cascade']).to be_nil
    end
    it 'does show rescue handler processing' do
      expect(last_response.status).to eq 400
      expect(last_response.body).to eq('message was processed')
    end
  end

  context 'API with cascade=false and rescue_from :all handler' do
    subject { Class.new(Grape::API) }
    before do
      subject.version 'v99', using: :header, vendor: 'vendorname', format: :json, cascade: false
      subject.rescue_from :all do |e|
        rack_response 'message was processed', 400, e[:headers]
      end
      subject.get '/beer' do
        'beer received'
      end
    end

    def app
      subject
    end

    context 'that received a request with correct vendor and version' do
      before { get '/beer', {}, 'HTTP_ACCEPT' => 'application/vnd.vendorname-v99' }
      it_should_behave_like 'a valid request'
    end

    context 'that receives' do
      context 'an invalid vendor in the request' do
        before do
          get '/beer', {}, 'HTTP_ACCEPT' => 'application/vnd.invalidvendor-v99',
                           'CONTENT_TYPE' => 'application/json'
        end
        it_should_behave_like 'a rescued request'
      end
    end
  end

  context 'API with cascade=false and without a rescue handler' do
    subject { Class.new(Grape::API) }
    before do
      subject.version 'v99', using: :header, vendor: 'vendorname', format: :json, cascade: false
      subject.get '/beer' do
        'beer received'
      end
    end

    def app
      subject
    end

    context 'that received a request with correct vendor and version' do
      before { get '/beer', {}, 'HTTP_ACCEPT' => 'application/vnd.vendorname-v99' }
      it_should_behave_like 'a valid request'
    end

    context 'that receives' do
      context 'an invalid version in the request' do
        before { get '/beer', {}, 'HTTP_ACCEPT' => 'application/vnd.vendorname-v77' }
        it_should_behave_like 'a not-cascaded request'
      end
      context 'an invalid vendor in the request' do
        before { get '/beer', {}, 'HTTP_ACCEPT' => 'application/vnd.invalidvendor-v99' }
        it_should_behave_like 'a not-cascaded request'
      end
    end
  end

  context 'API with cascade=false and with rescue_from :all handler and http_codes' do
    subject { Class.new(Grape::API) }
    before do
      subject.version 'v99', using: :header, vendor: 'vendorname', format: :json, cascade: false
      subject.rescue_from :all do |e|
        rack_response 'message was processed', 400, e[:headers]
      end
      subject.desc 'Get beer' do
        failure [[400, 'Bad Request'], [401, 'Unauthorized'], [403, 'Forbidden'],
                 [404, 'Resource not found'], [406, 'API vendor or version not found'],
                 [500, 'Internal processing error']]
      end
      subject.get '/beer' do
        'beer received'
      end
    end

    def app
      subject
    end

    context 'that received a request with correct vendor and version' do
      before { get '/beer', {}, 'HTTP_ACCEPT' => 'application/vnd.vendorname-v99' }
      it_should_behave_like 'a valid request'
    end

    context 'that receives' do
      context 'an invalid vendor in the request' do
        before do
          get '/beer', {}, 'HTTP_ACCEPT' => 'application/vnd.invalidvendor-v99',
                           'CONTENT_TYPE' => 'application/json'
        end
        it_should_behave_like 'a rescued request'
      end
    end
  end

  context 'API with cascade=false, http_codes but without a rescue handler' do
    subject { Class.new(Grape::API) }
    before do
      subject.version 'v99', using: :header, vendor: 'vendorname', format: :json, cascade: false
      subject.desc 'Get beer' do
        failure [[400, 'Bad Request'], [401, 'Unauthorized'], [403, 'Forbidden'],
                 [404, 'Resource not found'], [406, 'API vendor or version not found'],
                 [500, 'Internal processing error']]
      end
      subject.get '/beer' do
        'beer received'
      end
    end

    def app
      subject
    end

    context 'that received a request with correct vendor and version' do
      before { get '/beer', {}, 'HTTP_ACCEPT' => 'application/vnd.vendorname-v99' }
      it_should_behave_like 'a valid request'
    end

    context 'that receives' do
      context 'an invalid version in the request' do
        before { get '/beer', {}, 'HTTP_ACCEPT' => 'application/vnd.vendorname-v77' }
        it_should_behave_like 'a not-cascaded request'
      end
      context 'an invalid vendor in the request' do
        before { get '/beer', {}, 'HTTP_ACCEPT' => 'application/vnd.invalidvendor-v99' }
        it_should_behave_like 'a not-cascaded request'
      end
    end
  end

  context 'API with cascade=true and rescue_from :all handler' do
    subject { Class.new(Grape::API) }
    before do
      subject.version 'v99', using: :header, vendor: 'vendorname', format: :json, cascade: true
      subject.rescue_from :all do |e|
        rack_response 'message was processed', 400, e[:headers]
      end
      subject.get '/beer' do
        'beer received'
      end
    end

    def app
      subject
    end

    context 'that received a request with correct vendor and version' do
      before { get '/beer', {}, 'HTTP_ACCEPT' => 'application/vnd.vendorname-v99' }
      it_should_behave_like 'a valid request'
    end

    context 'that receives' do
      context 'an invalid version in the request' do
        before do
          get '/beer', {}, 'HTTP_ACCEPT' => 'application/vnd.vendorname-v77',
                           'CONTENT_TYPE' => 'application/json'
        end
        it_should_behave_like 'a cascaded request'
      end
      context 'an invalid vendor in the request' do
        before do
          get '/beer', {}, 'HTTP_ACCEPT' => 'application/vnd.invalidvendor-v99',
                           'CONTENT_TYPE' => 'application/json'
        end
        it_should_behave_like 'a cascaded request'
      end
    end
  end

  context 'API with cascade=true and without a rescue handler' do
    subject { Class.new(Grape::API) }
    before do
      subject.version 'v99', using: :header, vendor: 'vendorname', format: :json, cascade: true
      subject.get '/beer' do
        'beer received'
      end
    end

    def app
      subject
    end

    context 'that received a request with correct vendor and version' do
      before { get '/beer', {}, 'HTTP_ACCEPT' => 'application/vnd.vendorname-v99' }
      it_should_behave_like 'a valid request'
    end

    context 'that receives' do
      context 'an invalid version in the request' do
        before { get '/beer', {}, 'HTTP_ACCEPT' => 'application/vnd.vendorname-v77' }
        it_should_behave_like 'a cascaded request'
      end
      context 'an invalid vendor in the request' do
        before { get '/beer', {}, 'HTTP_ACCEPT' => 'application/vnd.invalidvendor-v99' }
        it_should_behave_like 'a cascaded request'
      end
    end
  end

  context 'API with cascade=true and with rescue_from :all handler and http_codes' do
    subject { Class.new(Grape::API) }
    before do
      subject.version 'v99', using: :header, vendor: 'vendorname', format: :json, cascade: true
      subject.rescue_from :all do |e|
        rack_response 'message was processed', 400, e[:headers]
      end
      subject.desc 'Get beer' do
        failure [[400, 'Bad Request'], [401, 'Unauthorized'], [403, 'Forbidden'],
                 [404, 'Resource not found'], [406, 'API vendor or version not found'],
                 [500, 'Internal processing error']]
      end
      subject.get '/beer' do
        'beer received'
      end
    end

    def app
      subject
    end

    context 'that received a request with correct vendor and version' do
      before { get '/beer', {}, 'HTTP_ACCEPT' => 'application/vnd.vendorname-v99' }
      it_should_behave_like 'a valid request'
    end

    context 'that receives' do
      context 'an invalid version in the request' do
        before do
          get '/beer', {}, 'HTTP_ACCEPT' => 'application/vnd.vendorname-v77',
                           'CONTENT_TYPE' => 'application/json'
        end
        it_should_behave_like 'a cascaded request'
      end
      context 'an invalid vendor in the request' do
        before do
          get '/beer', {}, 'HTTP_ACCEPT' => 'application/vnd.invalidvendor-v99',
                           'CONTENT_TYPE' => 'application/json'
        end
        it_should_behave_like 'a cascaded request'
      end
    end
  end

  context 'API with cascade=true, http_codes but without a rescue handler' do
    subject { Class.new(Grape::API) }
    before do
      subject.version 'v99', using: :header, vendor: 'vendorname', format: :json, cascade: true
      subject.desc 'Get beer' do
        failure [[400, 'Bad Request'], [401, 'Unauthorized'], [403, 'Forbidden'],
                 [404, 'Resource not found'], [406, 'API vendor or version not found'],
                 [500, 'Internal processing error']]
      end
      subject.get '/beer' do
        'beer received'
      end
    end

    def app
      subject
    end

    context 'that received a request with correct vendor and version' do
      before { get '/beer', {}, 'HTTP_ACCEPT' => 'application/vnd.vendorname-v99' }
      it_should_behave_like 'a valid request'
    end

    context 'that receives' do
      context 'an invalid version in the request' do
        before { get '/beer', {}, 'HTTP_ACCEPT' => 'application/vnd.vendorname-v77' }
        it_should_behave_like 'a cascaded request'
      end
      context 'an invalid vendor in the request' do
        before { get '/beer', {}, 'HTTP_ACCEPT' => 'application/vnd.invalidvendor-v99' }
        it_should_behave_like 'a cascaded request'
      end
    end
  end
end
