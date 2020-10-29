require 'spec_helper'

describe Rack::OAuth2::AccessToken::MAC do
  let(:ts) { 1305820234 }
  let :token do
    Rack::OAuth2::AccessToken::MAC.new(
      access_token: 'access_token',
      mac_key: 'secret',
      mac_algorithm: 'hmac-sha-256',
      ts: ts
    )
  end
  let :token_with_ext_verifier do
    Rack::OAuth2::AccessToken::MAC.new(
      access_token: 'access_token',
      mac_key: 'secret',
      mac_algorithm: 'hmac-sha-256',
      ts: ts,
      ext_verifier: Rack::OAuth2::AccessToken::MAC::Sha256HexVerifier
    )
  end
  let(:nonce) { '1000:51e74de734c05613f37520872e68db5f' }
  let(:resource_endpoint) { 'https://server.example.com/resources/fake' }
  subject { token }

  its(:mac_key)    { should == 'secret' }
  its(:mac_algorithm) { should == 'hmac-sha-256' }
  its(:token_response) do
    should == {
      access_token: 'access_token',
      refresh_token: nil,
      token_type: :mac,
      expires_in: nil,
      scope: '',
      mac_key: 'secret',
      mac_algorithm: 'hmac-sha-256'
    }
  end
  its(:generate_nonce) { should be_a String }

  describe 'verify!' do
    let(:request) { Rack::OAuth2::Server::Resource::MAC::Request.new(env) }

    context 'when no ext_verifier is given' do
      let(:env) do
        Rack::MockRequest.env_for(
          '/protected_resources',
          'HTTP_AUTHORIZATION' => %{MAC id="access_token", nonce="#{nonce}", ts="#{ts}" mac="#{signature}"}
        )
      end

      context 'when signature is valid' do
        let(:signature) { 'BgooS/voPOZWLwoVfx4+zbC3xAVKW3jtjhKYOfIGZOA=' }
        it do

          token.verify!(request.setup!).should == :verified
        end
      end

      context 'otherwise' do
        let(:signature) { 'invalid' }
        it do
          expect { token.verify!(request.setup!) }.to raise_error(
            Rack::OAuth2::Server::Resource::MAC::Unauthorized,
            'invalid_token :: Signature Invalid'
          )
        end
      end
    end

    context 'when ext_verifier is given' do
      let(:env) do
        Rack::MockRequest.env_for(
          '/protected_resources',
          method: :POST,
          params: {
            key1: 'value1'
          },
          'HTTP_AUTHORIZATION' => %{MAC id="access_token", nonce="#{nonce}", ts="#{ts}", mac="#{signature}", ext="#{ext}"}
        )
      end
      let(:signature) { 'invalid' }

      context 'when ext is invalid' do
        let(:ext) { 'invalid' }
        it do
          expect { token_with_ext_verifier.verify!(request.setup!) }.to raise_error(
            Rack::OAuth2::Server::Resource::MAC::Unauthorized,
            'invalid_token :: Sha256HexVerifier Invalid'
          )
        end
      end

      context 'when ext is valid' do
        let(:ext) { '4cfcd46c59f54b5ea6a5f9b05c28b52fef2864747194b5fdfc3d59c0057bf35a' }

        context 'when signature is valid' do
          let(:signature) { 'dZYR54n+Lym5qCRRmDqmRZ71rG+bkjSWmqrOv8OjYHk=' }
          it do
            Time.fix(Time.at(1302361200)) do
              token_with_ext_verifier.verify!(request.setup!).should == :verified
            end
          end
        end

        context 'otherwise' do
          it do
            expect { token.verify!(request.setup!) }.to raise_error(
              Rack::OAuth2::Server::Resource::MAC::Unauthorized,
              'invalid_token :: Signature Invalid'
            )
          end
        end
      end
    end
  end

  describe '.authenticate' do
    let(:request) { HTTPClient.new.send(:create_request, :post, URI.parse(resource_endpoint), {}, {hello: "world"}, {}) }
    context 'when no ext_verifier is given' do
      let(:signature) { 'pOBaL6HRawe4tUPmcU4vJEj1f2GJqrbQOlCcdAYgI/s=' }

      it 'should set Authorization header' do
        expect(token).to receive(:generate_nonce).and_return(nonce)
        expect(request.header).to receive(:[]=).with('Authorization', "MAC id=\"access_token\", nonce=\"#{nonce}\", ts=\"#{ts.to_i}\", mac=\"#{signature}\"")
        token.authenticate(request)
      end
    end

    context 'when ext_verifier is given' do
      let(:signature) { 'vgU0fj6rSpwUCAoCOrXlu8pZBR8a5Q5xIVlB4MCvJeM=' }
      let(:ext) { '3d011e09502a84552a0f8ae112d024cc2c115597e3a577d5f49007902c221dc5' }
      it 'should set Authorization header with ext_verifier' do
        expect(token_with_ext_verifier).to receive(:generate_nonce).and_return(nonce)
        expect(request.header).to receive(:[]=).with('Authorization', "MAC id=\"access_token\", nonce=\"#{nonce}\", ts=\"#{ts.to_i}\", mac=\"#{signature}\", ext=\"#{ext}\"")
        token_with_ext_verifier.authenticate(request)
      end
    end

  end
end
