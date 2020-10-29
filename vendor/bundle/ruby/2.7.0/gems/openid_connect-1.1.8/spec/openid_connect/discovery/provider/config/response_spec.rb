require 'spec_helper'

describe OpenIDConnect::Discovery::Provider::Config::Response do
  let :instance do
    OpenIDConnect::Discovery::Provider::Config::Response.new attributes
  end
  let :jwks_uri do
    'https://server.example.com/jwks.json'
  end
  let :minimum_attributes do
    {
      issuer: 'https://server.example.com',
      authorization_endpoint: 'https://server.example.com/authorize',
      jwks_uri: jwks_uri,
      response_types_supported: [
        :code, :id_token, 'token id_token'
      ],
      subject_types_supported: [
        :public, :pairwise
      ],
      id_token_signing_alg_values_supported: [
        :RS256
      ]
    }
  end
  let :attributes do
    minimum_attributes
  end
  subject { instance }

  context 'when required attributes missing' do
    let :attributes do
      {}
    end
    it { should_not be_valid }
  end

  context 'when end_session_endpoint given' do
    let(:end_session_endpoint) { 'https://server.example.com/end_session' }
    let :attributes do
      minimum_attributes.merge(
        end_session_endpoint: end_session_endpoint
      )
    end
    it { should be_valid }
    its(:end_session_endpoint) { should == end_session_endpoint }
  end

  context 'when check_session_iframe given' do
    let(:check_session_iframe) { 'https://server.example.com/check_session_iframe.html' }
    let :attributes do
      minimum_attributes.merge(
        check_session_iframe: check_session_iframe
      )
    end
    it { should be_valid }
    its(:check_session_iframe) { should == check_session_iframe }
  end

  describe '#as_json' do
    subject { instance.as_json }
    it { should == minimum_attributes }
  end

  describe '#validate!' do
    context 'when required attributes missing' do
      let :attributes do
        {}
      end
      it do
        expect do
          instance.validate!
        end.to raise_error OpenIDConnect::ValidationFailed
      end
    end

    context 'otherwise' do
      it do
        expect do
          instance.validate!
        end.not_to raise_error{ |e|
          e.should be_a OpenIDConnect::ValidationFailed
        }
      end
    end
  end

  describe '#jwks' do
    it do
      jwks = mock_json :get, jwks_uri, 'public_keys/jwks' do
        instance.jwks
      end
      jwks.should be_instance_of JSON::JWK::Set
    end
  end

  describe '#public_keys' do
    it do
      public_keys = mock_json :get, jwks_uri, 'public_keys/jwks' do
        instance.public_keys
      end
      public_keys.should be_instance_of Array
      public_keys.first.should be_instance_of OpenSSL::PKey::RSA
    end
  end
end
