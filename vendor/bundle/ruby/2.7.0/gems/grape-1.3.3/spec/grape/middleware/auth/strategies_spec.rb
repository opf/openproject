# frozen_string_literal: true

require 'spec_helper'

require 'base64'

describe Grape::Middleware::Auth::Strategies do
  context 'Basic Auth' do
    def app
      proc = ->(u, p) { u && p && u == p }
      Rack::Builder.new do |b|
        b.use Grape::Middleware::Error
        b.use(Grape::Middleware::Auth::Base, type: :http_basic, proc: proc)
        b.run ->(_env) { [200, {}, ['Hello there.']] }
      end
    end

    it 'throws a 401 if no auth is given' do
      @proc = -> { false }
      get '/whatever'
      expect(last_response.status).to eq(401)
    end

    it 'authenticates if given valid creds' do
      get '/whatever', {}, 'HTTP_AUTHORIZATION' => encode_basic_auth('admin', 'admin')
      expect(last_response.status).to eq(200)
    end

    it 'throws a 401 is wrong auth is given' do
      get '/whatever', {}, 'HTTP_AUTHORIZATION' => encode_basic_auth('admin', 'wrong')
      expect(last_response.status).to eq(401)
    end
  end

  context 'Digest MD5 Auth' do
    RSpec::Matchers.define :be_challenge do
      match do |actual_response|
        actual_response.status == 401 &&
          actual_response['WWW-Authenticate'] =~ /^Digest / &&
          actual_response.body.empty?
      end
    end

    module StrategiesSpec
      class Test < Grape::API
        http_digest(realm: 'Test Api', opaque: 'secret') do |username|
          { 'foo' => 'bar' }[username]
        end

        get '/test' do
          [{ hey: 'you' }, { there: 'bar' }, { foo: 'baz' }]
        end
      end
    end

    def app
      StrategiesSpec::Test
    end

    it 'is a digest authentication challenge' do
      get '/test'
      expect(last_response).to be_challenge
    end

    it 'throws a 401 if no auth is given' do
      get '/test'
      expect(last_response.status).to eq(401)
    end

    it 'authenticates if given valid creds' do
      digest_authorize 'foo', 'bar'
      get '/test'
      expect(last_response.status).to eq(200)
    end

    it 'throws a 401 if given invalid creds' do
      digest_authorize 'bar', 'foo'
      get '/test'
      expect(last_response.status).to eq(401)
    end
  end
end
