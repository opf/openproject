require 'spec_helper'

describe Rack::OAuth2::Server::Authorize::Extension::IdToken do
  subject { response }
  let(:request)      { Rack::MockRequest.new app }
  let(:response)     { request.get('/?response_type=id_token&client_id=client&state=state') }
  let(:redirect_uri) { 'http://client.example.com/callback' }
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
        response.id_token = id_token
        response.approve!
      end
    end
    its(:status)   { should == 302 }
    its(:location) { should include "#{redirect_uri}#" }
    its(:location) { should include "id_token=#{id_token}" }
    its(:location) { should include 'state=state' }

    context 'when id_token is String' do
      let(:id_token) { 'id_token' }
      its(:location) { should include 'id_token=id_token' }
    end
  end

  context 'when id_token is missing' do
    let :app do
      Rack::OAuth2::Server::Authorize.new do |request, response|
        response.redirect_uri = redirect_uri
        response.approve!
      end
    end
    it do
      expect { response }.to raise_error AttrRequired::AttrMissing, "'id_token' required."
    end
  end

  context 'when error response' do
    let(:env)     { Rack::MockRequest.env_for("/authorize?client_id=client_id") }
    let(:request) { Rack::OAuth2::Server::Authorize::Extension::IdToken::Request.new env }

    it 'should set protocol_params_location = :fragment' do
      expect { request.bad_request! }.to raise_error(Rack::OAuth2::Server::Authorize::BadRequest) { |e|
        e.protocol_params_location.should == :fragment
      }
    end
  end

  context 'when openid scope given' do
    let(:env)     { Rack::MockRequest.env_for("/authorize?client_id=client_id&scope=openid") }
    let(:request) { Rack::OAuth2::Server::Authorize::Extension::IdToken::Request.new env }
    it do
      request.openid_connect_request?.should == true
    end
  end
end