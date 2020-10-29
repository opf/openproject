require 'omniauth/openid_connect/providers'

describe OmniAuth::OpenIDConnect::Providers do
  describe '#load' do
    let(:configs) do
      {
        :test => {
          host: 'example.net',
          identifier: 'chorizo',
          secret: 'fat'
        },
        :heroku => {
          'identifier' => 'chuchu',
          'secret' => 'doesthetrain'
        },
        'google.staging' => {
          identifier: 'cowboy',
          secret: 'hat'
        },
        'invalid.key.format' => {
          identifier: 'foo',
          secret: 'bar'
        },
        'nonexistant.provider_class' => {
          identifier: 'baz',
          secret: 'boo'
        }
      }
    end

    let(:providers) { OmniAuth::OpenIDConnect::Providers.load configs }

    before do
      OmniAuth::OpenIDConnect::Providers.configure base_redirect_uri: 'https://example.net'
    end

    it 'returns 3 providers ignoring an invalid one and one that could not be found' do
      expect(providers.size).to eq 3
    end

    it 'returns one default provider named test' do
      provider = providers.find { |p| p.name == 'test' }

      expect(provider).to be_a OmniAuth::OpenIDConnect::Provider
      expect(provider.to_h[:client_options][:identifier]).to eq 'chorizo'
    end

    it 'returns one heroku provider' do
      provider = providers.find { |p| p.name == 'heroku' }

      expect(provider).to be_a OmniAuth::OpenIDConnect::Heroku
      expect(provider.to_h[:client_options][:identifier]).to eq 'chuchu'
    end

    it 'returns one google provider named staging' do
      provider = providers.find { |p| p.name == 'staging' }

      expect(provider).to be_a OmniAuth::OpenIDConnect::Google
      expect(provider.to_h[:client_options][:identifier]).to eq 'cowboy'
    end
  end
end
