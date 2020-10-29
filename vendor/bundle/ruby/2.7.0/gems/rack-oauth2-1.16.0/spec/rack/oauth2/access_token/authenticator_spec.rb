require 'spec_helper'

describe Rack::OAuth2::AccessToken::Authenticator do
  let(:resource_endpoint) { 'https://server.example.com/resources/fake' }
  let(:request) { HTTP::Message.new_request(:get, URI.parse(resource_endpoint)) }
  let(:authenticator) { Rack::OAuth2::AccessToken::Authenticator.new(token) }

  shared_examples_for :authenticator do
    it 'should let the token authenticate the request' do
      expect(token).to receive(:authenticate).with(request)
      authenticator.filter_request(request)
    end
  end

  context 'when Legacy token is given' do
    let(:token) do
      Rack::OAuth2::AccessToken::Legacy.new(
        access_token: 'access_token'
      )
    end
    it_behaves_like :authenticator
  end

  context 'when Bearer token is given' do
    let(:token) do
      Rack::OAuth2::AccessToken::Bearer.new(
        access_token: 'access_token'
      )
    end
    it_behaves_like :authenticator
  end

  context 'when MAC token is given' do
    let(:token) do
      Rack::OAuth2::AccessToken::MAC.new(
        access_token: 'access_token',
        mac_key: 'secret',
        mac_algorithm: 'hmac-sha-256'
      )
    end
    it_behaves_like :authenticator
  end
end
