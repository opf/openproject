require 'spec_helper.rb'
require 'rack/oauth2/server/authorize/extension/code_and_token'

describe Rack::OAuth2::Server::Authorize::Extension::CodeAndToken do
  let(:request)            { Rack::MockRequest.new app }
  let(:redirect_uri)       { 'http://client.example.com/callback' }
  let(:access_token)       { 'access_token' }
  let(:authorization_code) { 'authorization_code' }
  let(:response) do
    request.get("/?response_type=code%20token&client_id=client&redirect_uri=#{redirect_uri}")
  end

  context "when approved" do
    subject { response }
    let(:bearer_token) { Rack::OAuth2::AccessToken::Bearer.new(access_token: access_token) }
    let :app do
      Rack::OAuth2::Server::Authorize.new do |request, response|
        response.redirect_uri = redirect_uri
        response.access_token = bearer_token
        response.code         = authorization_code
        response.approve!
      end
    end
    its(:status)   { should == 302 }
    its(:location) { should include "#{redirect_uri}#" }
    its(:location) { should include "code=#{authorization_code}"}
    its(:location) { should include "access_token=#{access_token}"}
    its(:location) { should include 'token_type=bearer' }

    context 'when refresh_token is given' do
      let :bearer_token do
        Rack::OAuth2::AccessToken::Bearer.new(
          access_token: access_token,
          refresh_token: 'refresh'
        )
      end
      its(:location) { should include "#{redirect_uri}#" }
      its(:location) { should include "code=#{authorization_code}"}
      its(:location) { should include "access_token=#{access_token}"}
      its(:location) { should include 'token_type=bearer' }
    end
  end

  context 'when denied' do
    let :app do
      Rack::OAuth2::Server::Authorize.new do |request, response|
        request.verify_redirect_uri! redirect_uri
        request.access_denied!
      end
    end
    it 'should redirect with error in fragment' do
      response.status.should == 302
      error_message = {
        error: :access_denied,
        error_description: Rack::OAuth2::Server::Authorize::ErrorMethods::DEFAULT_DESCRIPTION[:access_denied]
      }
      response.location.should == "#{redirect_uri}##{error_message.to_query.gsub('+', '%20')}"
    end
  end
end
