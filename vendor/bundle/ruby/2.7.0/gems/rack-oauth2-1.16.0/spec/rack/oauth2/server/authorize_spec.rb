require 'spec_helper.rb'

describe Rack::OAuth2::Server::Authorize do
  let(:app)          { Rack::OAuth2::Server::Authorize.new }
  let(:request)      { Rack::MockRequest.new app }
  let(:redirect_uri) { 'http://client.example.com/callback' }
  let(:bad_request)  { Rack::OAuth2::Server::Authorize::BadRequest }

  context 'when response_type is missing' do
    it do
      expect { request.get "/?client_id=client&redirect_uri=#{redirect_uri}" }.to raise_error bad_request
    end
  end

  context 'when redirect_uri is missing' do
    it do
      expect { request.get "/?response_type=code&client_id=client" }.not_to raise_error
    end
  end

  context 'when client_id is missing' do
    it do
      expect { request.get "/?response_type=code&redirect_uri=#{redirect_uri}" }.to raise_error bad_request
    end
  end

  context 'when unknown response_type is given' do
    it do
      expect { request.get "/?response_type=unknown&client_id=client&redirect_uri=#{redirect_uri}" }.to raise_error bad_request
    end
  end

  context 'when all required parameters are valid' do
    [:code, :token].each do |request_type|
      context "when response_type = :#{request_type}" do
        subject { request.get "/?response_type=#{request_type}&client_id=client&redirect_uri=#{redirect_uri}" }
        its(:status) { should == 200 }
      end
    end
  end

  describe Rack::OAuth2::Server::Authorize::Request do
    let(:env)     { Rack::MockRequest.env_for("/authorize?client_id=client&redirect_uri=#{redirect_uri}") }
    let(:request) { Rack::OAuth2::Server::Authorize::Request.new env }

    describe '#varified_redirect_uri' do
      context 'when an Array of pre-registered URIs are given' do
        context 'when given redirect_uri is valid against one of them' do
          let :pre_registered do
            [
              redirect_uri,
              'http://ja.client.example.com/callback',
              'http://en.client.example.com/callback'
            ]
          end
          it 'should be valid' do
            request.verify_redirect_uri!(pre_registered).should == redirect_uri
          end
        end

        context 'otherwise' do
          let :pre_registered do
            [
              'http://ja.client.example.com/callback',
              'http://en.client.example.com/callback'
            ]
          end
          it do
            expect do
              request.verify_redirect_uri!(pre_registered)
            end.to raise_error bad_request
          end
        end
      end

      context 'when exact mathed redirect_uri is given' do
        let(:pre_registered) { redirect_uri }
        it 'should be valid' do
          request.verify_redirect_uri!(pre_registered).should == redirect_uri
        end
      end

      context 'when partially mathed redirect_uri is given' do
        let(:pre_registered) { 'http://client.example.com' }

        context 'when partial matching allowed' do
          it 'should be valid' do
            request.verify_redirect_uri!(pre_registered, :allow_partial_match).should == redirect_uri
          end
        end

        context 'otherwise' do
          it do
            expect do
              request.verify_redirect_uri!(pre_registered)
            end.to raise_error bad_request
          end
        end
      end

      context 'when invalid redirect_uri is given' do
        let(:pre_registered) { 'http://client2.example.com' }
        it do
          expect do
            request.verify_redirect_uri!(pre_registered)
          end.to raise_error bad_request
        end
      end

      context 'when redirect_uri is missing' do
        let(:env) { Rack::MockRequest.env_for("/authorize?client_id=client") }

        context 'when pre-registered redirect_uri is a String' do
          let(:pre_registered) { redirect_uri }
          it 'should use pre-registered redirect_uri' do
            request.verify_redirect_uri!(pre_registered).should == pre_registered
          end
        end

        context 'when pre-registered redirect_uri is an Array' do
          context 'when only 1' do
            let(:pre_registered) { [redirect_uri] }

            context 'when partial match allowed' do
              it do
                expect do
                  request.verify_redirect_uri!(pre_registered, :allow_partial_match)
                end.to raise_error bad_request
              end
            end

            context 'otherwise' do
              it 'should use pre-registered redirect_uri' do
                request.verify_redirect_uri!(pre_registered).should == pre_registered.first
              end
            end
          end

          context 'when more than 2' do
            let(:pre_registered) { [redirect_uri, 'http://client.example.com/callback2'] }
            it do
              expect do
                request.verify_redirect_uri!(pre_registered)
              end.to raise_error bad_request
            end
          end
        end
      end
    end
  end

  describe 'extensibility' do
    before do
      require 'rack/oauth2/server/authorize/extension/code_and_token'
    end

    let(:env) do
      Rack::MockRequest.env_for("/authorize?response_type=#{response_type}&client_id=client")
    end
    let(:request) { Rack::OAuth2::Server::Authorize::Request.new env }
    its(:extensions) { should == [Rack::OAuth2::Server::Authorize::Extension::CodeAndToken] }

    describe 'code token' do
      let(:response_type) { 'code%20token' }
      it do
        app.send(
          :response_type_for, request
        ).should == Rack::OAuth2::Server::Authorize::Extension::CodeAndToken
      end
    end

    describe 'token code' do
      let(:response_type) { 'token%20code' }
      it do
        app.send(
          :response_type_for, request
        ).should == Rack::OAuth2::Server::Authorize::Extension::CodeAndToken
      end
    end

    describe 'token code id_token' do
      let(:response_type) { 'token%20code%20id_token' }
      it do
        expect do
          app.send(:response_type_for, request)
        end.to raise_error bad_request
      end
    end

    describe 'id_token' do
      before do
        class Rack::OAuth2::Server::Authorize::Extension::IdToken < Rack::OAuth2::Server::Abstract::Handler
          def self.response_type_for?(response_type)
            response_type == 'id_token'
          end
        end
      end

      its(:extensions) do
        should == [
          Rack::OAuth2::Server::Authorize::Extension::CodeAndToken,
          Rack::OAuth2::Server::Authorize::Extension::IdToken
        ]
      end

      let(:response_type) { 'id_token' }
      it do
        app.send(
          :response_type_for, request
        ).should == Rack::OAuth2::Server::Authorize::Extension::IdToken
      end
    end
  end
end
