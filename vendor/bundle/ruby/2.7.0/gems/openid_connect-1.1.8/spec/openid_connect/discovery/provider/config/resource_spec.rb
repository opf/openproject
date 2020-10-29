require 'spec_helper'

describe OpenIDConnect::Discovery::Provider::Config::Resource do
  let(:resource) do
    uri = URI.parse 'http://server.example.com'
    OpenIDConnect::Discovery::Provider::Config::Resource.new uri
  end

  describe '#endpoint' do
    context 'when invalid host' do
      before do
        resource.host = 'hoge*hoge'
      end

      it do
        expect { resource.endpoint }.to raise_error SWD::Exception
      end
    end
  end
end