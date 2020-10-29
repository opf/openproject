require 'spec_helper'

describe Rack::OAuth2::AccessToken::Legacy do
  let :token do
    Rack::OAuth2::AccessToken::Legacy.new(
      access_token: 'access_token'
    )
  end
  let(:resource_endpoint) { 'https://server.example.com/resources/fake' }
  let(:request) { HTTPClient.new.send(:create_request, :post, URI.parse(resource_endpoint), {}, {hello: "world"}, {}) }

  describe '#to_s' do
    subject { token }
    its(:to_s) { should == token.access_token }
  end

  describe '.authenticate' do
    it 'should set Authorization header' do
      expect(request.header).to receive(:[]=).with('Authorization', 'OAuth access_token')
      token.authenticate(request)
    end
  end
end
