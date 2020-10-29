require 'spec_helper.rb'

describe Rack::OAuth2::Server::Authorize::Code do
  let(:request) { Rack::MockRequest.new app }
  let(:redirect_uri)   { 'http://client.example.com/callback' }
  let(:code_verifier)  { SecureRandom.hex(16) }
  let(:code_challenge) { Base64.urlsafe_encode64(OpenSSL::Digest::SHA256.digest(code_verifier)).delete('=') }
  let(:code_challenge_method) { :S256 }
  subject { @request }

  describe 'authorization request' do
    let :app do
      Rack::OAuth2::Server::Authorize.new do |request, response|
        @request = request
      end
    end

    context 'when code_challenge is given' do
      context 'when code_challenge_method is given' do
        before do
          request.get "/?response_type=code&client_id=client&redirect_uri=#{redirect_uri}&state=state&code_challenge=#{code_challenge}&code_challenge_method=#{code_challenge_method}"
        end
        its(:code_challenge) { should == code_challenge }
        its(:code_challenge_method) { should == code_challenge_method.to_s }
      end

      context 'when code_challenge_method is omitted' do
        before do
          request.get "/?response_type=code&client_id=client&redirect_uri=#{redirect_uri}&state=state&code_challenge=#{code_challenge}"
        end
        its(:code_challenge) { should == code_challenge }
        its(:code_challenge_method) { should == nil }
      end
    end

    context 'otherwise' do
      before do
        request.get "/?response_type=code&client_id=client&redirect_uri=#{redirect_uri}&state=state"
      end
      its(:code_challenge) { should == nil }
      its(:code_challenge_method) { should == nil }
    end
  end

  describe 'token request' do
    let(:app) do
      Rack::OAuth2::Server::Token.new do |request, response|
        @request = request
        response.access_token = Rack::OAuth2::AccessToken::Bearer.new(access_token: 'access_token')
      end
    end
    let(:default_params) do
      {
        grant_type: 'authorization_code',
        client_id: 'client_id',
        client_secret: 'client_secret',
        code: 'authorization_code',
        redirect_uri: 'http://client.example.com/callback'
      }
    end

    context 'when code_verifier is given' do
      before do
        request.post '/', params: default_params.merge(
          code_verifier: code_verifier
        )
      end
      its(:code_verifier) { should == code_verifier }

      describe '#verify_code_verifier!' do
        context 'when code_verifier is given with code_challenge_method=plain' do
          it do
            expect do
              subject.verify_code_verifier! code_verifier, :plain
            end.not_to raise_error
          end
        end

        context 'when collect code_challenge is given' do
          it do
            expect do
              subject.verify_code_verifier! code_challenge
            end.not_to raise_error
          end
        end

        context 'when wrong code_challenge is blank' do
          it do
            expect do
              subject.verify_code_verifier! 'wrong'
            end.to raise_error Rack::OAuth2::Server::Token::BadRequest, /invalid_grant/
          end
        end

        context 'when code_challenge is nil' do
          it do
            expect do
              subject.verify_code_verifier! nil
            end.to raise_error Rack::OAuth2::Server::Token::BadRequest, /invalid_grant/
          end
        end

        context 'when unknown code_challenge_method is given' do
          it do
            expect do
              subject.verify_code_verifier! code_challenge, :unknown
            end.to raise_error Rack::OAuth2::Server::Token::BadRequest, /invalid_grant/
          end
        end
      end
    end

    context 'otherwise' do
      before do
        request.post '/', params: default_params
      end
      its(:code_verifier) { should == nil }

      describe '#verify_code_verifier!' do
        context 'when code_verifier is given with code_challenge_method=plain' do
          it do
            expect do
              subject.verify_code_verifier! code_verifier, :plain
            end.to raise_error Rack::OAuth2::Server::Token::BadRequest, /invalid_grant/
          end
        end

        context 'when collect code_challenge is given' do
          it do
            expect do
              subject.verify_code_verifier! code_challenge
            end.to raise_error Rack::OAuth2::Server::Token::BadRequest, /invalid_grant/
          end
        end

        context 'when wrong code_challenge is blank' do
          it do
            expect do
              subject.verify_code_verifier! 'wrong'
            end.to raise_error Rack::OAuth2::Server::Token::BadRequest, /invalid_grant/
          end
        end

        context 'when code_challenge is nil' do
          it do
            expect do
              subject.verify_code_verifier! nil
            end.not_to raise_error
          end
        end

        context 'when unknown code_challenge_method is given' do
          it do
            expect do
              subject.verify_code_verifier! code_challenge, :unknown
            end.to raise_error Rack::OAuth2::Server::Token::BadRequest, /invalid_grant/
          end
        end
      end
    end
  end
end
