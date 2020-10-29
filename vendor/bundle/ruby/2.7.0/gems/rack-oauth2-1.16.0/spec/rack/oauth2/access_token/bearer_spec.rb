require 'spec_helper'

describe Rack::OAuth2::AccessToken::Bearer do
  let :token do
    Rack::OAuth2::AccessToken::Bearer.new(
      access_token: 'access_token'
    )
  end
  let(:resource_endpoint) { 'https://server.example.com/resources/fake' }
  let(:request) { HTTPClient.new.send(:create_request, :post, URI.parse(resource_endpoint), {}, {hello: "world"}, {}) }

  describe '.authenticate' do
    it 'should set Authorization header' do
      expect(request.header).to receive(:[]=).with('Authorization', 'Bearer access_token')
      token.authenticate(request)
    end
  end
end
