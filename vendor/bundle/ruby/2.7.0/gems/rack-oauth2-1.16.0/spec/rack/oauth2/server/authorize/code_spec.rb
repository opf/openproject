require 'spec_helper.rb'

describe Rack::OAuth2::Server::Authorize::Code do
  let(:request)            { Rack::MockRequest.new app }
  let(:redirect_uri)       { 'http://client.example.com/callback' }
  let(:authorization_code) { 'authorization_code' }
  let(:response)           { request.get "/?response_type=code&client_id=client&redirect_uri=#{redirect_uri}&state=state" }

  context 'when approved' do
    subject { response }
    let :app do
      Rack::OAuth2::Server::Authorize.new do |request, response|
        response.redirect_uri = redirect_uri
        response.code = authorization_code
        response.approve!
      end
    end
    its(:status)   { should == 302 }
    its(:location) { should == "#{redirect_uri}?code=#{authorization_code}&state=state" }

    context 'when redirect_uri already includes query' do
      let(:redirect_uri) { 'http://client.example.com/callback?k=v' }
      its(:location)     { should == "#{redirect_uri}&code=#{authorization_code}&state=state" }
    end

    context 'when redirect_uri is missing' do
      let(:redirect_uri) { nil }
      it do
        expect { response }.to raise_error AttrRequired::AttrMissing
      end
    end

    context 'when code is missing' do
      let(:authorization_code) { nil }
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
    it 'should redirect with error in query' do
      response.status.should == 302
      error_message = {
        error: :access_denied,
        error_description: Rack::OAuth2::Server::Authorize::ErrorMethods::DEFAULT_DESCRIPTION[:access_denied]
      }
      response.location.should == "#{redirect_uri}?#{error_message.to_query.gsub('+', '%20')}&state=state"
    end
  end
end
