require 'spec_helper.rb'

describe Rack::OAuth2::Server::Token::ClientCredentials do
  let(:request) { Rack::MockRequest.new app }
  let(:app) do
    Rack::OAuth2::Server::Token.new do |request, response|
      unless request.client_id == client_id && request.client_secret == client_secret
        request.invalid_client!
      end
      response.access_token = Rack::OAuth2::AccessToken::Bearer.new(access_token: 'access_token')
    end
  end
  let(:client_id) { 'client_id '}
  let(:client_secret) { 'client_secret' }
  let(:params) do
    {
      grant_type: 'client_credentials',
      client_id: client_id,
      client_secret: client_secret
    }
  end
  subject { request.post('/', params: params) }

  its(:status)       { should == 200 }
  its(:content_type) { should == 'application/json' }
  its(:body)         { should include '"access_token":"access_token"' }
  its(:body)         { should include '"token_type":"bearer"' }

  context 'basic auth' do
    let(:params) do
      { grant_type: 'client_credentials' }
    end
    let(:encoded_creds) do
      Base64.strict_encode64([
        Rack::OAuth2::Util.www_form_url_encode(client_id),
        Rack::OAuth2::Util.www_form_url_encode(client_secret)
      ].join(':'))
    end
    subject do
      request.post('/',
        {params: params, 'HTTP_AUTHORIZATION' => "Basic #{encoded_creds}"})
    end

    its(:status)       { should == 200 }

    context 'compliance with RFC6749 sec 2.3.1' do
      let(:client_id) { 'client: yes/please!' }
      let(:client_secret) { 'terrible:secret:of:space' }

      its(:status)       { should == 200 }
    end
  end
end
