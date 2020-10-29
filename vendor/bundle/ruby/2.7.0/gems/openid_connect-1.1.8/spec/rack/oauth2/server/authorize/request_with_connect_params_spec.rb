require 'spec_helper'

describe Rack::OAuth2::Server::Authorize::RequestWithConnectParams do
  let(:base_params) do
    {
      client_id: 'client_id',
      redirect_uri: 'https://client.example.com/callback'
    }
  end
  let(:env)     { Rack::MockRequest.env_for("/authorize?#{base_params.to_query}&#{params.to_query}") }
  let(:request) { Rack::OAuth2::Server::Authorize::Request.new env }
  subject { request }

  describe 'prompt' do
    context 'when a space-delimited string given' do
      let(:params) do
        {prompt: 'login consent'}
      end
      its(:prompt) { should == ['login', 'consent']}
    end

    context 'when a single string given' do
      let(:params) do
        {prompt: 'login'}
      end
      its(:prompt) { should == ['login']}
    end
  end

  describe 'max_age' do
    context 'when numeric value given' do
      let(:params) do
        {max_age: '5'}
      end
      its(:max_age) { should == 5}
    end

    context 'when non-numeric string given' do
      let(:params) do
        {max_age: 'foo'}
      end
      its(:max_age) { should == 0}
    end
  end
end