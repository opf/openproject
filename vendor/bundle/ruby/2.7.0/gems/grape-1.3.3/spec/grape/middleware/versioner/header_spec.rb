# frozen_string_literal: true

require 'spec_helper'

describe Grape::Middleware::Versioner::Header do
  let(:app) { ->(env) { [200, env, env] } }
  subject { Grape::Middleware::Versioner::Header.new(app, **(@options || {})) }

  before do
    @options = {
      version_options: {
        using: :header,
        vendor: 'vendor'
      }
    }
  end

  context 'api.type and api.subtype' do
    it 'sets type and subtype to first choice of content type if no preference given' do
      status, _, env = subject.call('HTTP_ACCEPT' => '*/*')
      expect(env['api.type']).to eql 'application'
      expect(env['api.subtype']).to eql 'vnd.vendor+xml'
      expect(status).to eq(200)
    end

    it 'sets preferred type' do
      status, _, env = subject.call('HTTP_ACCEPT' => 'application/*')
      expect(env['api.type']).to eql 'application'
      expect(env['api.subtype']).to eql 'vnd.vendor+xml'
      expect(status).to eq(200)
    end

    it 'sets preferred type and subtype' do
      status, _, env = subject.call('HTTP_ACCEPT' => 'text/plain')
      expect(env['api.type']).to eql 'text'
      expect(env['api.subtype']).to eql 'plain'
      expect(status).to eq(200)
    end
  end

  context 'api.format' do
    it 'is set' do
      status, _, env = subject.call('HTTP_ACCEPT' => 'application/vnd.vendor+json')
      expect(env['api.format']).to eql 'json'
      expect(status).to eq(200)
    end

    it 'is nil if not provided' do
      status, _, env = subject.call('HTTP_ACCEPT' => 'application/vnd.vendor')
      expect(env['api.format']).to eql nil
      expect(status).to eq(200)
    end

    ['v1', :v1].each do |version|
      context "when version is set to #{version}" do
        before do
          @options[:versions] = [version]
        end

        it 'is set' do
          status, _, env = subject.call('HTTP_ACCEPT' => 'application/vnd.vendor-v1+json')
          expect(env['api.format']).to eql 'json'
          expect(status).to eq(200)
        end

        it 'is nil if not provided' do
          status, _, env = subject.call('HTTP_ACCEPT' => 'application/vnd.vendor-v1')
          expect(env['api.format']).to eql nil
          expect(status).to eq(200)
        end
      end
    end
  end

  context 'api.vendor' do
    it 'is set' do
      status, _, env = subject.call('HTTP_ACCEPT' => 'application/vnd.vendor')
      expect(env['api.vendor']).to eql 'vendor'
      expect(status).to eq(200)
    end

    it 'is set if format provided' do
      status, _, env = subject.call('HTTP_ACCEPT' => 'application/vnd.vendor+json')
      expect(env['api.vendor']).to eql 'vendor'
      expect(status).to eq(200)
    end

    it 'fails with 406 Not Acceptable if vendor is invalid' do
      expect { subject.call('HTTP_ACCEPT' => 'application/vnd.othervendor+json').last }
        .to raise_exception do |exception|
          expect(exception).to be_a(Grape::Exceptions::InvalidAcceptHeader)
          expect(exception.headers).to eql('X-Cascade' => 'pass')
          expect(exception.status).to eql 406
          expect(exception.message).to include 'API vendor not found'
        end
    end

    context 'when version is set' do
      before do
        @options[:versions] = ['v1']
      end

      it 'is set' do
        status, _, env = subject.call('HTTP_ACCEPT' => 'application/vnd.vendor-v1')
        expect(env['api.vendor']).to eql 'vendor'
        expect(status).to eq(200)
      end

      it 'is set if format provided' do
        status, _, env = subject.call('HTTP_ACCEPT' => 'application/vnd.vendor-v1+json')
        expect(env['api.vendor']).to eql 'vendor'
        expect(status).to eq(200)
      end

      it 'fails with 406 Not Acceptable if vendor is invalid' do
        expect { subject.call('HTTP_ACCEPT' => 'application/vnd.othervendor-v1+json').last }
          .to raise_exception do |exception|
            expect(exception).to be_a(Grape::Exceptions::InvalidAcceptHeader)
            expect(exception.headers).to eql('X-Cascade' => 'pass')
            expect(exception.status).to eql 406
            expect(exception.message).to include('API vendor not found')
          end
      end
    end
  end

  context 'api.version' do
    before do
      @options[:versions] = ['v1']
    end

    it 'is set' do
      status, _, env = subject.call('HTTP_ACCEPT' => 'application/vnd.vendor-v1')
      expect(env['api.version']).to eql 'v1'
      expect(status).to eq(200)
    end

    it 'is set if format provided' do
      status, _, env = subject.call('HTTP_ACCEPT' => 'application/vnd.vendor-v1+json')
      expect(env['api.version']).to eql 'v1'
      expect(status).to eq(200)
    end

    it 'fails with 406 Not Acceptable if version is invalid' do
      expect { subject.call('HTTP_ACCEPT' => 'application/vnd.vendor-v2+json').last }.to raise_exception do |exception|
        expect(exception).to be_a(Grape::Exceptions::InvalidVersionHeader)
        expect(exception.headers).to eql('X-Cascade' => 'pass')
        expect(exception.status).to eql 406
        expect(exception.message).to include('API version not found')
      end
    end
  end

  it 'succeeds if :strict is not set' do
    expect(subject.call('HTTP_ACCEPT' => '').first).to eq(200)
    expect(subject.call({}).first).to eq(200)
  end

  it 'succeeds if :strict is set to false' do
    @options[:version_options][:strict] = false
    expect(subject.call('HTTP_ACCEPT' => '').first).to eq(200)
    expect(subject.call({}).first).to eq(200)
  end

  it 'succeeds if :strict is set to false and given an invalid header' do
    @options[:version_options][:strict] = false
    expect(subject.call('HTTP_ACCEPT' => 'yaml').first).to eq(200)
    expect(subject.call({}).first).to eq(200)
  end

  context 'when :strict is set' do
    before do
      @options[:versions] = ['v1']
      @options[:version_options][:strict] = true
    end

    it 'fails with 406 Not Acceptable if header is not set' do
      expect { subject.call({}).last }.to raise_exception do |exception|
        expect(exception).to be_a(Grape::Exceptions::InvalidAcceptHeader)
        expect(exception.headers).to eql('X-Cascade' => 'pass')
        expect(exception.status).to eql 406
        expect(exception.message).to include('Accept header must be set.')
      end
    end

    it 'fails with 406 Not Acceptable if header is empty' do
      expect { subject.call('HTTP_ACCEPT' => '').last }.to raise_exception do |exception|
        expect(exception).to be_a(Grape::Exceptions::InvalidAcceptHeader)
        expect(exception.headers).to eql('X-Cascade' => 'pass')
        expect(exception.status).to eql 406
        expect(exception.message).to include('Accept header must be set.')
      end
    end

    it 'succeeds if proper header is set' do
      expect(subject.call('HTTP_ACCEPT' => 'application/vnd.vendor-v1+json').first).to eq(200)
    end
  end

  context 'when :strict and cascade: false' do
    before do
      @options[:versions] = ['v1']
      @options[:version_options][:strict] = true
      @options[:version_options][:cascade] = false
    end

    it 'fails with 406 Not Acceptable if header is not set' do
      expect { subject.call({}).last }.to raise_exception do |exception|
        expect(exception).to be_a(Grape::Exceptions::InvalidAcceptHeader)
        expect(exception.headers).to eql({})
        expect(exception.status).to eql 406
        expect(exception.message).to include('Accept header must be set.')
      end
    end

    it 'fails with 406 Not Acceptable if header is application/xml' do
      expect { subject.call('HTTP_ACCEPT' => 'application/xml').last }
        .to raise_exception do |exception|
        expect(exception).to be_a(Grape::Exceptions::InvalidAcceptHeader)
        expect(exception.headers).to eql({})
        expect(exception.status).to eql 406
        expect(exception.message).to include('API vendor or version not found.')
      end
    end

    it 'fails with 406 Not Acceptable if header is empty' do
      expect { subject.call('HTTP_ACCEPT' => '').last }.to raise_exception do |exception|
        expect(exception).to be_a(Grape::Exceptions::InvalidAcceptHeader)
        expect(exception.headers).to eql({})
        expect(exception.status).to eql 406
        expect(exception.message).to include('Accept header must be set.')
      end
    end

    it 'fails with 406 Not Acceptable if header contains a single invalid accept' do
      expect { subject.call('HTTP_ACCEPT' => 'application/json;application/vnd.vendor-v1+json').first }
        .to raise_exception do |exception|
        expect(exception).to be_a(Grape::Exceptions::InvalidAcceptHeader)
        expect(exception.headers).to eql({})
        expect(exception.status).to eql 406
        expect(exception.message).to include('API vendor or version not found.')
      end
    end

    it 'succeeds if proper header is set' do
      expect(subject.call('HTTP_ACCEPT' => 'application/vnd.vendor-v1+json').first).to eq(200)
    end
  end

  context 'when multiple versions are specified' do
    before do
      @options[:versions] = %w[v1 v2]
    end

    it 'succeeds with v1' do
      expect(subject.call('HTTP_ACCEPT' => 'application/vnd.vendor-v1+json').first).to eq(200)
    end

    it 'succeeds with v2' do
      expect(subject.call('HTTP_ACCEPT' => 'application/vnd.vendor-v2+json').first).to eq(200)
    end

    it 'fails with another version' do
      expect { subject.call('HTTP_ACCEPT' => 'application/vnd.vendor-v3+json') }.to raise_exception do |exception|
        expect(exception).to be_a(Grape::Exceptions::InvalidVersionHeader)
        expect(exception.headers).to eql('X-Cascade' => 'pass')
        expect(exception.status).to eql 406
        expect(exception.message).to include('API version not found')
      end
    end
  end

  context 'when there are multiple versions with complex vendor specified with rescue_from :all' do
    subject do
      Class.new(Grape::API) do
        rescue_from :all
      end
    end

    let(:v1_app) do
      Class.new(Grape::API) do
        version 'v1', using: :header, vendor: 'test.a-cool_resource', cascade: false, strict: true
        content_type :v1_test, 'application/vnd.test.a-cool_resource-v1+json'
        formatter :v1_test, ->(object, _) { object }
        format :v1_test

        resources :users do
          get :hello do
            'one'
          end
        end
      end
    end

    let(:v2_app) do
      Class.new(Grape::API) do
        version 'v2', using: :header, vendor: 'test.a-cool_resource', strict: true
        content_type :v2_test, 'application/vnd.test.a-cool_resource-v2+json'
        formatter :v2_test, ->(object, _) { object }
        format :v2_test

        resources :users do
          get :hello do
            'two'
          end
        end
      end
    end

    def app
      subject.mount v2_app
      subject.mount v1_app
      subject
    end

    context 'with header versioned endpoints and a rescue_all block defined' do
      it 'responds correctly to a v1 request' do
        versioned_get '/users/hello', 'v1', using: :header, vendor: 'test.a-cool_resource'
        expect(last_response.body).to eq('one')
        expect(last_response.body).not_to include('API vendor or version not found')
      end

      it 'responds correctly to a v2 request' do
        versioned_get '/users/hello', 'v2', using: :header, vendor: 'test.a-cool_resource'
        expect(last_response.body).to eq('two')
        expect(last_response.body).not_to include('API vendor or version not found')
      end
    end
  end
end
