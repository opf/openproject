require 'spec_helper.rb'

describe Rack::OAuth2::Server::Token::JWTBearer do
  let(:request) { Rack::MockRequest.new app }
  let(:app) do
    Rack::OAuth2::Server::Token.new do |request, response|
      response.access_token = Rack::OAuth2::AccessToken::Bearer.new(access_token: 'access_token')
    end
  end
  let(:params) do
    {
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      client_id: 'client_id',
      assertion: 'header.payload.signature'
    }
  end
  subject { request.post('/', params: params) }

  its(:status)       { should == 200 }
  its(:content_type) { should == 'application/json' }
  its(:body)         { should include '"access_token":"access_token"' }
  its(:body)         { should include '"token_type":"bearer"' }

  context 'when assertion is missing' do
    before do
      params.delete_if do |key, value|
        key == :assertion
      end
    end
    its(:status)       { should == 400 }
    its(:content_type) { should == 'application/json' }
    its(:body)         { should include '"error":"invalid_request"' }
  end
end
