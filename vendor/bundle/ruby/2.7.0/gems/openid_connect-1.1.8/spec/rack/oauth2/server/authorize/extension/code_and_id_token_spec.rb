require 'spec_helper'

describe Rack::OAuth2::Server::Authorize::Extension::CodeAndIdToken do
  subject { response }
  let(:request)      { Rack::MockRequest.new app }
  let(:response)     { request.get("/?response_type=code%20id_token&client_id=client&state=state") }
  let(:redirect_uri) { 'http://client.example.com/callback' }
  let(:code)         { 'authorization_code' }
  let :id_token do
    OpenIDConnect::ResponseObject::IdToken.new(
      iss: 'https://server.example.com',
      sub: 'user_id',
      aud: 'client_id',
      nonce: 'nonce',
      exp: 1313424327,
      iat: 1313420327
    ).to_jwt private_key
  end

  context "when id_token is given" do
    let :app do
      Rack::OAuth2::Server::Authorize.new do |request, response|
        response.redirect_uri = redirect_uri
        response.code = code
        response.id_token = id_token
        response.approve!
      end
    end
    its(:status)   { should == 302 }
    its(:location) { should include "#{redirect_uri}#" }
    its(:location) { should include "code=#{code}" }
    its(:location) { should include "id_token=#{id_token}" }
    its(:location) { should include "state=state" }

    context 'when id_token is String' do
      let(:id_token) { 'non_jwt_string' }
      its(:location) { should include "id_token=non_jwt_string" }
    end
  end

  context "otherwise" do
    let :app do
      Rack::OAuth2::Server::Authorize.new do |request, response|
        response.redirect_uri = redirect_uri
        response.code = code
        response.approve!
      end
    end
    it do
      expect { response }.to raise_error AttrRequired::AttrMissing, "'id_token' required."
    end
  end

  context 'when error response' do
    let(:env)     { Rack::MockRequest.env_for("/authorize?client_id=client_id") }
    let(:request) { Rack::OAuth2::Server::Authorize::Extension::CodeAndIdToken::Request.new env }

    it 'should set protocol_params_location = :fragment' do
      expect { request.bad_request! }.to raise_error(Rack::OAuth2::Server::Authorize::BadRequest) { |e|
        e.protocol_params_location.should == :fragment
      }
    end
  end
end