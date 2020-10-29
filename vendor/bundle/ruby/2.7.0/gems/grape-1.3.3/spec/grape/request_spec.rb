# frozen_string_literal: true

require 'spec_helper'

module Grape
  describe Request do
    let(:default_method) { 'GET' }
    let(:default_params) { {} }
    let(:default_options) do
      {
        method: method,
        params: params
      }
    end
    let(:default_env) do
      Rack::MockRequest.env_for('/', options)
    end
    let(:method) { default_method }
    let(:params) { default_params }
    let(:options) { default_options }
    let(:env) { default_env }

    let(:request) do
      Grape::Request.new(env)
    end

    describe '#params' do
      let(:params) do
        {
          a: '123',
          b: 'xyz'
        }
      end

      it 'by default returns stringified parameter keys' do
        expect(request.params).to eq(ActiveSupport::HashWithIndifferentAccess.new('a' => '123', 'b' => 'xyz'))
      end

      context 'when build_params_with: Grape::Extensions::Hash::ParamBuilder is specified' do
        let(:request) do
          Grape::Request.new(env, build_params_with: Grape::Extensions::Hash::ParamBuilder)
        end

        it 'returns symbolized params' do
          expect(request.params).to eq(a: '123', b: 'xyz')
        end
      end

      describe 'with grape.routing_args' do
        let(:options) do
          default_options.merge('grape.routing_args' => routing_args)
        end
        let(:routing_args) do
          {
            version: '123',
            route_info: '456',
            c: 'ccc'
          }
        end

        it 'cuts version and route_info' do
          expect(request.params).to eq(ActiveSupport::HashWithIndifferentAccess.new(a: '123', b: 'xyz', c: 'ccc'))
        end
      end
    end

    describe 'when the param_builder is set to Hashie' do
      before do
        Grape.configure do |config|
          config.param_builder = Grape::Extensions::Hashie::Mash::ParamBuilder
        end
      end

      after do
        Grape.config.reset
      end

      subject(:request_params) { Grape::Request.new(env, opts).params }

      context 'when the API does not include a specific param builder' do
        let(:opts) { {} }
        it { is_expected.to be_a(Hashie::Mash) }
      end

      context 'when the API includes a specific param builder' do
        let(:opts) { { build_params_with: Grape::Extensions::Hash::ParamBuilder } }
        it { is_expected.to be_a(Hash) }
      end
    end

    describe '#headers' do
      let(:options) do
        default_options.merge(request_headers)
      end

      describe 'with http headers in env' do
        let(:request_headers) do
          {
            'HTTP_X_GRAPE_IS_COOL' => 'yeah'
          }
        end

        it 'cuts HTTP_ prefix and capitalizes header name words' do
          expect(request.headers).to eq('X-Grape-Is-Cool' => 'yeah')
        end
      end

      describe 'with non-HTTP_* stuff in env' do
        let(:request_headers) do
          {
            'HTP_X_GRAPE_ENTITY_TOO' => 'but now we are testing Grape'
          }
        end

        it 'does not include them' do
          expect(request.headers).to eq({})
        end
      end

      describe 'with symbolic header names' do
        let(:request_headers) do
          {
            HTTP_GRAPE_LIKES_SYMBOLIC: 'it is true'
          }
        end
        let(:env) do
          default_env.merge(request_headers)
        end

        it 'converts them to string' do
          expect(request.headers).to eq('Grape-Likes-Symbolic' => 'it is true')
        end
      end
    end
  end
end
