require 'spec_helper'

describe OpenIDConnect::Client::Registrar do
  subject { instance }
  let(:attributes) { minimum_attributes }
  let(:minimum_attributes) do
    {
      redirect_uris: ['https://client.example.com/callback']
    }
  end
  let(:instance) { OpenIDConnect::Client::Registrar.new(endpoint, attributes) }
  let(:endpoint) { 'https://server.example.com/clients' }

  context 'when endpoint given' do
    context 'when required attributes given' do
      let(:attributes) do
        minimum_attributes
      end
      it { should be_valid }
    end

    context 'otherwise' do
      let(:instance) { OpenIDConnect::Client::Registrar.new(endpoint) }
      it { should_not be_valid }
    end
  end

  context 'otherwise' do
    let(:endpoint) { '' }
    it { should_not be_valid }
  end

  describe '#initialize' do
    it 'creates attribute writers for all attributes' do
      described_class.metadata_attributes.each do |attr|
        expect(subject).to respond_to("#{attr}=")
      end
    end
  end

  describe '#sector_identifier' do
    context 'when sector_identifier_uri given' do
      let(:attributes) do
        minimum_attributes.merge(
          sector_identifier_uri: 'https://client2.example.com/sector_identifier.json'
        )
      end
      its(:sector_identifier) { should == 'client2.example.com' }

      context 'when sector_identifier_uri is invalid URI' do
        let(:attributes) do
          minimum_attributes.merge(
            sector_identifier_uri: 'invalid'
          )
        end
        it { should_not be_valid }
      end
    end

    context 'otherwise' do
      let(:attributes) do
        minimum_attributes.merge(
          redirect_uris: redirect_uris
        )
      end

      context 'when redirect_uris includes only one host' do
        let(:redirect_uris) do
          [
            'https://client.example.com/callback/op1',
            'https://client.example.com/callback/op2'
          ]
        end
        its(:sector_identifier) { should == 'client.example.com' }
      end

      context 'when redirect_uris includes multiple hosts' do
        let(:redirect_uris) do
          [
            'https://client1.example.com/callback',
            'https://client2.example.com/callback'
          ]
        end
        its(:sector_identifier) { should be_nil }

        context 'when subject_type=pairwise' do
          let(:attributes) do
            minimum_attributes.merge(
              redirect_uris: redirect_uris,
              subject_type: :pairwise
            )
          end
          it { should_not be_valid }
        end
      end

      context 'when redirect_uris includes invalid URL' do
        let(:redirect_uris) do
          [
            'invalid'
          ]
        end
        its(:sector_identifier) { should be_nil }
      end
    end
  end

  describe '#redirect_uris' do
    let(:base_url) { 'http://client.example.com/callback' }
    let(:attributes) { minimum_attributes.merge(redirect_uris: [redirect_uri]) }

    context 'when query included' do
      let(:redirect_uri) { [base_url, '?foo=bar'].join }
      it { should be_valid }
      its(:redirect_uris) { should == [redirect_uri] }
    end

    context 'when fragment included' do
      let(:redirect_uri) { [base_url, '#foo=bar'].join }
      it { should be_valid }
    end
  end

  describe '#contacts' do
    context 'when contacts given' do
      let(:attributes) do
        minimum_attributes.merge(
          contacts: contacts
        )
      end

      context 'when invalid email included' do
        let(:contacts) do
          [
            'invalid',
            'nov@matake.jp'
          ]
        end
        it { should_not be_valid }
      end

      context 'when localhost address included' do
        let(:contacts) do
          [
            'nov@localhost',
            'nov@matake.jp'
          ]
        end
        it { should_not be_valid }
      end

      context 'otherwise' do
        let(:contacts) do
          ['nov@matake.jp']
        end
        it { should be_valid }
      end
    end
  end

  describe '#as_json' do
    context 'when valid' do
      its(:as_json) do
        should == minimum_attributes
      end
    end

    context 'otherwise' do
      let(:attributes) do
        minimum_attributes.merge(
          sector_identifier_uri: 'invalid'
        )
      end
      it do
        expect do
          instance.as_json
        end.to raise_error OpenIDConnect::ValidationFailed
      end
    end
  end

  describe '#register!' do
    it 'should return OpenIDConnect::Client' do
      client = mock_json :post, endpoint, 'client/registered', params: minimum_attributes do
        instance.register!
      end
      client.should be_instance_of OpenIDConnect::Client
      client.identifier.should == 'client.example.com'
      client.secret.should == 'client_secret'
      client.expires_in.should == 3600
    end

    context 'when failed' do
      it 'should raise OpenIDConnect::Client::Registrar::RegistrationFailed' do
        mock_json :post, endpoint, 'errors/unknown', params: minimum_attributes, status: 400 do
          expect do
            instance.register!
          end.to raise_error OpenIDConnect::Client::Registrar::RegistrationFailed
        end
      end
    end
  end

  describe '#validate!' do
    context 'when valid' do
      it do
        expect do
          instance.validate!
        end.not_to raise_error { |e|
          e.should be_a OpenIDConnect::ValidationFailed
        }
      end
    end

    context 'otherwise' do
      let(:attributes) do
        minimum_attributes.merge(
          sector_identifier_uri: 'invalid'
        )
      end

      it do
        expect do
          instance.validate!
        end.to raise_error OpenIDConnect::ValidationFailed
      end
    end
  end

  describe 'http_client' do
    subject { instance.send(:http_client) }

    context 'when initial_access_token given' do
      let(:attributes) do
        minimum_attributes.merge(
          initial_access_token: initial_access_token
        )
      end

      context 'when Rack::OAuth2::AccessToken::Bearer given' do
        let(:initial_access_token) do
          Rack::OAuth2::AccessToken::Bearer.new(access_token: 'access_token')
        end
        it { should be_instance_of Rack::OAuth2::AccessToken::Bearer }
        its(:access_token) { should == 'access_token' }
      end

      context 'otherwise' do
        let(:initial_access_token) { 'access_token' }
        it { should be_instance_of Rack::OAuth2::AccessToken::Bearer }
        its(:access_token) { should == 'access_token' }
      end
    end

    context 'otherwise' do
      it { should be_instance_of HTTPClient }
    end
  end
end
