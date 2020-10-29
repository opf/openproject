require 'spec_helper'

describe OpenIDConnect::Discovery::Provider do
  let(:provider) { 'https://server.example.com' }
  let(:discover) { OpenIDConnect::Discovery::Provider.discover! identifier }
  let(:endpoint) { "https://#{host}/.well-known/webfinger" }
  let(:query) do
    {
      rel: OpenIDConnect::Discovery::Provider::Issuer::REL_VALUE,
      resource: resource
    }
  end

  shared_examples_for :discover_provider do
    it "should succeed" do
      mock_json :get, endpoint, 'discovery/webfinger', params: query do
        res = discover
        res.should be_a WebFinger::Response
        res.issuer.should == provider
      end
    end
  end

  describe '#discover!' do
    let(:host) { 'server.example.com' }

    context 'when URI is given' do
      let(:resource) { identifier }

      context 'when scheme included' do
        context 'when HTTPS' do
          let(:identifier) { "https://#{host}" }
          it_behaves_like :discover_provider
        end

        context 'otherwise' do
          let(:identifier) { "http://#{host}" }
          it_behaves_like :discover_provider
          it 'should access to https://**' do
            endpoint.should match /^https:\/\//
          end
        end
      end

      context 'when only host is given' do
        let(:identifier) { host }
        let(:resource)   { "https://#{host}" }
        it_behaves_like :discover_provider
      end
    end

    context 'when Email is given' do
      let(:identifier) { "nov@#{host}" }
      let(:resource)   { "acct:#{identifier}" }
      it_behaves_like :discover_provider
    end

    context 'when error occured' do
      let(:identifier) { host }
      let(:resource)   { "https://#{host}" }
      it 'should raise OpenIDConnect::Discovery::DiscoveryFailed' do
        mock_json :get, endpoint, 'discovery/webfinger', params: query, status: [404, 'Not Found'] do
          expect do
            discover
          end.to raise_error OpenIDConnect::Discovery::DiscoveryFailed
        end
      end
    end
  end
end