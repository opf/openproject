require 'spec_helper'

describe OpenIDConnect::Discovery::Provider::Config do
  let(:provider) { 'https://connect-op.heroku.com' }
  let(:endpoint) { 'https://connect-op.heroku.com/.well-known/openid-configuration' }

  describe 'discover!' do
    it 'should setup given attributes' do
      mock_json :get, endpoint, 'discovery/config' do
        config = OpenIDConnect::Discovery::Provider::Config.discover! provider
        config.should be_instance_of OpenIDConnect::Discovery::Provider::Config::Response
        config.issuer.should == 'https://connect-op.heroku.com'
        config.authorization_endpoint.should == 'https://connect-op.heroku.com/authorizations/new'
        config.token_endpoint.should == 'https://connect-op.heroku.com/access_tokens'
        config.userinfo_endpoint.should == 'https://connect-op.heroku.com/userinfo'
        config.jwks_uri.should == 'https://connect-op.heroku.com/jwks.json'
        config.registration_endpoint.should == 'https://connect-op.heroku.com/connect/client'
        config.scopes_supported.should == ['openid', 'profile', 'email', 'address']
        config.response_types_supported.should == ['code', 'token', 'id_token', 'code token', 'code id_token', 'id_token token']
        config.acr_values_supported.should be_nil
        config.subject_types_supported.should == ['public', 'pairwise']
        config.claims_supported.should == ['sub', 'iss', 'name', 'email']
        config.id_token_signing_alg_values_supported.should == ['RS256']
      end
    end

    context 'when OP identifier includes custom port' do
      let(:provider) { 'https://connect-op.heroku.com:8080' }
      let(:endpoint) { 'https://connect-op.heroku.com:8080/.well-known/openid-configuration' }

      it 'should construct well-known URI with given port' do
        mock_json :get, endpoint, 'discovery/config_with_custom_port' do
          OpenIDConnect::Discovery::Provider::Config.discover! provider
        end
      end
    end

    context 'when OP identifier includes path' do
      let(:provider) { 'https://connect.openid4.us/abop' }
      let(:endpoint) { 'https://connect.openid4.us/abop/.well-known/openid-configuration' }

      it 'should construct well-known URI with given port' do
        mock_json :get, endpoint, 'discovery/config_with_path' do
          OpenIDConnect::Discovery::Provider::Config.discover! provider
        end
      end
    end

    context 'when SWD::Exception raised' do
      it do
        expect do
          mock_json :get, endpoint, 'errors/unknown', status: [404, 'Not Found'] do
            OpenIDConnect::Discovery::Provider::Config.discover! provider
          end
        end.to raise_error OpenIDConnect::Discovery::DiscoveryFailed
      end
    end

    describe 'when response include invalid issuer' do
      context 'with normal configuration' do
        it do
          expect do
            mock_json :get, endpoint, 'discovery/config_with_invalid_issuer' do
              OpenIDConnect::Discovery::Provider::Config.discover! provider
            end
          end.to raise_error OpenIDConnect::Discovery::DiscoveryFailed
        end
      end

      context 'when issuer validation is disabled.' do
        before :each do
          OpenIDConnect.validate_discovery_issuer = false
        end

        after :each do
          OpenIDConnect.validate_discovery_issuer = true
        end

        it do
          expect do
            mock_json :get, endpoint, 'discovery/config_with_invalid_issuer' do
              OpenIDConnect::Discovery::Provider::Config.discover! provider
            end
          end.not_to raise_error
        end
      end
    end

    context 'when response include no issuer' do
      it do
        expect do
          mock_json :get, endpoint, 'discovery/config_without_issuer' do
            OpenIDConnect::Discovery::Provider::Config.discover! provider
          end
        end.to raise_error OpenIDConnect::Discovery::DiscoveryFailed
      end
    end
  end
end
