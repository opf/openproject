require 'spec_helper.rb'

describe Rack::OAuth2::Server::Authorize::Code do
  let(:request) { Rack::MockRequest.new app }
  let(:redirect_uri)   { 'http://client.example.com/callback' }
  let(:response_mode)  { 'form_post' }
  subject { @request }

  describe 'authorization request' do
    let :app do
      Rack::OAuth2::Server::Authorize.new do |request, response|
        @request = request
      end
    end

    context 'when response_mode is given' do
      before do
        request.get "/?response_type=code&client_id=client&redirect_uri=#{redirect_uri}&state=state&response_mode=#{response_mode}"
      end
      its(:response_mode) { should == response_mode }
    end

    context 'otherwise' do
      before do
        request.get "/?response_type=code&client_id=client&redirect_uri=#{redirect_uri}&state=state"
      end
      its(:response_mode) { should == nil }
    end
  end
end
