require 'spec_helper.rb'

describe Rack::OAuth2::Server::Authorize::Token do
  let(:request)      { Rack::MockRequest.new app }
  let(:redirect_uri) { 'http://client.example.com/callback' }
  let(:access_token) { 'access_token' }
  let(:response)     { request.get("/?response_type=token&client_id=client&redirect_uri=#{redirect_uri}&state=state") }

  context "when approved" do
    subject { response }
    let(:bearer_token) { Rack::OAuth2::AccessToken::Bearer.new(access_token: access_token) }
    let :app do
      Rack::OAuth2::Server::Authorize.new do |request, response|
        response.redirect_uri = redirect_uri
        response.access_token = bearer_token
        response.approve!
      end
    end
    its(:status)   { should == 302 }
    its(:location) { should == "#{redirect_uri}#access_token=#{access_token}&state=state&token_type=bearer" }

    context 'when refresh_token is given' do
      let :bearer_token do
        Rack::OAuth2::AccessToken::Bearer.new(
          access_token: access_token,
          refresh_token: 'refresh'
        )
      end
      its(:location) { should == "#{redirect_uri}#access_token=#{access_token}&state=state&token_type=bearer" }
    end

    context 'when redirect_uri is missing' do
      let :app do
        Rack::OAuth2::Server::Authorize.new do |request, response|
          response.access_token = bearer_token
          response.approve!
        end
      end
      it do
        expect { response }.to raise_error AttrRequired::AttrMissing
      end
    end

    context 'when access_token is missing' do
      let :app do
        Rack::OAuth2::Server::Authorize.new do |request, response|
          response.redirect_uri = redirect_uri
          response.approve!
        end
      end
      it do
        expect { response }.to raise_error AttrRequired::AttrMissing
      end
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
      response.location.should == "#{redirect_uri}##{error_message.to_query.gsub('+', '%20')}&state=state"
    end
  end
end
