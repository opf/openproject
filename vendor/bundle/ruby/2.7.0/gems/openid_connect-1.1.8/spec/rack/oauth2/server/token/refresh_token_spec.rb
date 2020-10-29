require 'spec_helper.rb'

describe Rack::OAuth2::Server::Token::RefreshToken do
  subject { response }
  let(:request) { Rack::MockRequest.new app }
  let :response do
    request.post('/', params: {
      grant_type: "refresh_token",
      client_id: "client_id",
      refresh_token: "refresh_token"
    })
  end
  let :id_token do
    OpenIDConnect::ResponseObject::IdToken.new(
      iss: 'https://server.example.com',
      sub: 'user_id',
      aud: 'client_id',
      exp: 1313424327,
      iat: 1313420327,
      nonce: 'nonce',
      secret: 'secret'
    ).to_jwt private_key
  end

  context "when id_token is given" do
    let :app do
      Rack::OAuth2::Server::Token.new do |request, response|
        response.access_token = Rack::OAuth2::AccessToken::Bearer.new(access_token: 'access_token')
        response.id_token = id_token
      end
    end
    its(:status) { should == 200 }
    its(:body)   { should include "\"id_token\":\"#{id_token}\"" }

    context 'when id_token is String' do
      let(:id_token) { 'id_token' }
      its(:body)     { should include "\"id_token\":\"id_token\"" }
    end
  end

  context "otherwise" do
    let :app do
      Rack::OAuth2::Server::Token.new do |request, response|
        response.access_token = Rack::OAuth2::AccessToken::Bearer.new(access_token: 'access_token')
      end
    end
    its(:status) { should == 200 }
    its(:body)   { should_not include "id_token" }
  end
end
