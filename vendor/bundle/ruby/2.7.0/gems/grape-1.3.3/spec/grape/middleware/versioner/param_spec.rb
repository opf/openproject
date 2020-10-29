# frozen_string_literal: true

require 'spec_helper'

describe Grape::Middleware::Versioner::Param do
  let(:app) { ->(env) { [200, env, env['api.version']] } }
  let(:options) { {} }
  subject { Grape::Middleware::Versioner::Param.new(app, **options) }

  it 'sets the API version based on the default param (apiver)' do
    env = Rack::MockRequest.env_for('/awesome', params: { 'apiver' => 'v1' })
    expect(subject.call(env)[1]['api.version']).to eq('v1')
  end

  it 'cuts (only) the version out of the params' do
    env = Rack::MockRequest.env_for('/awesome', params: { 'apiver' => 'v1', 'other_param' => '5' })
    env['rack.request.query_hash'] = Rack::Utils.parse_nested_query(env['QUERY_STRING'])
    expect(subject.call(env)[1]['rack.request.query_hash']['apiver']).to be_nil
    expect(subject.call(env)[1]['rack.request.query_hash']['other_param']).to eq('5')
  end

  it 'provides a nil version if no version is given' do
    env = Rack::MockRequest.env_for('/')
    expect(subject.call(env).last).to be_nil
  end

  context 'with specified parameter name' do
    let(:options) { { version_options: { parameter: 'v' } } }
    it 'sets the API version based on the custom parameter name' do
      env = Rack::MockRequest.env_for('/awesome', params: { 'v' => 'v1' })
      expect(subject.call(env)[1]['api.version']).to eq('v1')
    end
    it 'does not set the API version based on the default param' do
      env = Rack::MockRequest.env_for('/awesome', params: { 'apiver' => 'v1' })
      expect(subject.call(env)[1]['api.version']).to be_nil
    end
  end

  context 'with specified versions' do
    let(:options) { { versions: %w[v1 v2] } }
    it 'throws an error if a non-allowed version is specified' do
      env = Rack::MockRequest.env_for('/awesome', params: { 'apiver' => 'v3' })
      expect(catch(:error) { subject.call(env) }[:status]).to eq(404)
    end
    it 'allows versions that have been specified' do
      env = Rack::MockRequest.env_for('/awesome', params: { 'apiver' => 'v1' })
      expect(subject.call(env)[1]['api.version']).to eq('v1')
    end
  end

  context 'when no version is set' do
    let(:options) do
      {
        versions: ['v1'],
        version_options: { using: :header }
      }
    end
    it 'returns a 200 (matches the first version found)' do
      env = Rack::MockRequest.env_for('/awesome', params: {})
      expect(subject.call(env).first).to eq(200)
    end
  end

  context 'when there are multiple versions without a custom param' do
    subject { Class.new(Grape::API) }

    let(:v1_app) do
      Class.new(Grape::API) do
        version 'v1', using: :param
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
        version 'v2', using: :param
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

    it 'responds correctly to a v1 request' do
      versioned_get '/users/hello', 'v1', using: :param, parameter: :apiver
      expect(last_response.body).to eq('one')
      expect(last_response.body).not_to include('API vendor or version not found')
    end

    it 'responds correctly to a v2 request' do
      versioned_get '/users/hello', 'v2', using: :param, parameter: :apiver
      expect(last_response.body).to eq('two')
      expect(last_response.body).not_to include('API vendor or version not found')
    end
  end

  context 'when there are multiple versions with a custom param' do
    subject { Class.new(Grape::API) }

    let(:v1_app) do
      Class.new(Grape::API) do
        version 'v1', using: :param, parameter: 'v'
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
        version 'v2', using: :param, parameter: 'v'
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

    it 'responds correctly to a v1 request' do
      versioned_get '/users/hello', 'v1', using: :param, parameter: 'v'
      expect(last_response.body).to eq('one')
      expect(last_response.body).not_to include('API vendor or version not found')
    end

    it 'responds correctly to a v2 request' do
      versioned_get '/users/hello', 'v2', using: :param, parameter: 'v'
      expect(last_response.body).to eq('two')
      expect(last_response.body).not_to include('API vendor or version not found')
    end
  end
end
