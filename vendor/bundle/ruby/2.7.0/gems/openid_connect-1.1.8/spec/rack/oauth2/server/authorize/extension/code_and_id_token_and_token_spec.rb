require 'spec_helper'

describe Rack::OAuth2::Server::Authorize::Extension::CodeAndIdTokenAndToken do
  subject { response }
  let(:request)      { Rack::MockRequest.new app }
  let(:response)     { request.get('/?response_type=code%20id_token%20token&client_id=client&state=state') }
  let(:redirect_uri) { 'http://client.example.com/callback' }
  let(:bearer_token) { Rack::OAuth2::AccessToken::Bearer.new(access_token: 'access_token') }
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

  context 'when id_token is given' do
    let :app do
      Rack::OAuth2::Server::Authorize.new do |request, response|
        response.redirect_uri = redirect_uri
        response.code = code
        response.id_token = id_token
        response.access_token = bearer_token
        response.approve!
      end
    end
    its(:status)   { should == 302 }
    its(:location) { should include "#{redirect_uri}#" }
    its(:location) { should include "access_token=#{bearer_token.access_token}" }
    its(:location) { should include "id_token=#{id_token}" }
    its(:location) { should include "token_type=#{bearer_token.token_type}" }
    its(:location) { should include "code=#{code}" }
    its(:location) { should include 'state=state' }

    context 'when id_token is String' do
      let(:id_token) { 'id_token' }
      its(:location) { should include 'id_token=id_token' }
    end
  end

  context 'otherwise' do
    let :app do
      Rack::OAuth2::Server::Authorize.new do |request, response|
        response.redirect_uri = redirect_uri
        response.approve!
      end
    end
    it do
      expect { response }.to raise_error AttrRequired::AttrMissing, "'access_token', 'code', 'id_token' required."
    end
  end

  context 'when error response' do
    let(:env)     { Rack::MockRequest.env_for("/authorize?client_id=client_id") }
    let(:request) { Rack::OAuth2::Server::Authorize::Extension::CodeAndIdTokenAndToken::Request.new env }

    it 'should set protocol_params_location = :fragment' do
      expect { request.bad_request! }.to raise_error(Rack::OAuth2::Server::Authorize::BadRequest) { |e|
        e.protocol_params_location.should == :fragment
      }
    end
  end
end