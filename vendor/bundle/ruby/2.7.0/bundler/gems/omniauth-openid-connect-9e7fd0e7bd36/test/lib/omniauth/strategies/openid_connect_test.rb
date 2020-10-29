require 'test_helper'

module OmniAuth
  module Strategies
    class OpenIDConnectTest < StrategyTestCase
      def test_client_options_defaults
        assert_equal 'https', strategy.options.client_options.scheme
        assert_equal 443, strategy.options.client_options.port
        assert_equal '/authorize', strategy.options.client_options.authorization_endpoint
        assert_equal '/token', strategy.options.client_options.token_endpoint
      end

      def test_request_phase
        expected_redirect = /^https:\/\/example\.com\/authorize\?client_id=1234&nonce=\w{32}&response_type=code&scope=openid&state=\w{32}$/
        strategy.options.issuer = 'example.com'
        strategy.options.client_options.host = 'example.com'
        strategy.expects(:redirect).with(regexp_matches(expected_redirect))
        strategy.request_phase
      end

      def test_request_phase_with_discovery
        expected_redirect = /^https:\/\/example\.com\/authorization\?client_id=1234&nonce=\w{32}&response_type=code&scope=openid&state=\w{32}$/
        strategy.options.client_options.host = 'example.com'
        strategy.options.discovery = true

        issuer = stub('OpenIDConnect::Discovery::Issuer')
        issuer.stubs(:issuer).returns('https://example.com/')
        ::OpenIDConnect::Discovery::Provider.stubs(:discover!).returns(issuer)

        config = stub('OpenIDConnect::Discovery::Provder::Config')
        config.stubs(:authorization_endpoint).returns('https://example.com/authorization')
        config.stubs(:token_endpoint).returns('https://example.com/token')
        config.stubs(:userinfo_endpoint).returns('https://example.com/userinfo')
        config.stubs(:jwks_uri).returns('https://example.com/jwks')
        ::OpenIDConnect::Discovery::Provider::Config.stubs(:discover!).with('https://example.com/').returns(config)

        strategy.expects(:redirect).with(regexp_matches(expected_redirect))
        strategy.request_phase

        assert_equal strategy.options.issuer, 'https://example.com/'
        assert_equal strategy.options.client_options.authorization_endpoint, 'https://example.com/authorization'
        assert_equal strategy.options.client_options.token_endpoint, 'https://example.com/token'
        assert_equal strategy.options.client_options.userinfo_endpoint, 'https://example.com/userinfo'
        assert_equal strategy.options.client_options.jwks_uri, 'https://example.com/jwks'
      end

      def test_uid
        assert_equal user_info.sub, strategy.uid
      end

      #def test_callback_phase(session = {}, params = {})
      #  code = SecureRandom.hex(16)
      #  state = SecureRandom.hex(16)
      #  request.stubs(:params).returns({'code' => code,'state' => state}.merge(params))
      #  request.stubs(:path_info).returns("")

      def test_callback_phase(session = {}, params = {})
        code = SecureRandom.hex(16)
        state = SecureRandom.hex(16)
        nonce = SecureRandom.hex(16)
        request.stubs(:params).returns('code' => code, 'state' => state)
        request.stubs(:path_info).returns('')

        strategy.options.issuer = 'example.com'
        strategy.options.client_signing_alg = :RS256
        strategy.options.client_jwk_signing_key = File.read('test/fixtures/jwks.json')

        id_token = stub('OpenIDConnect::ResponseObject::IdToken')
        id_token.stubs(:verify!).with(issuer: strategy.options.issuer, client_id: @identifier, nonce: nonce).returns(true)
        ::OpenIDConnect::ResponseObject::IdToken.stubs(:decode).returns(id_token)

        strategy.unstub(:user_info)
        access_token = stub('OpenIDConnect::AccessToken')
        access_token.stubs(:access_token)
        access_token.stubs(:refresh_token)
        access_token.stubs(:expires_in)
        access_token.stubs(:scope)
        access_token.stubs(:id_token).returns(File.read('test/fixtures/id_token.txt'))
        client.expects(:access_token!).at_least_once.returns(access_token)
        access_token.expects(:userinfo!).returns(user_info)

        strategy.call!('rack.session' => { 'omniauth.state' => state, 'omniauth.nonce' => nonce })
        strategy.callback_phase
      end

      def test_callback_phase_with_discovery
        code = SecureRandom.hex(16)
        state = SecureRandom.hex(16)
        nonce = SecureRandom.hex(16)
        jwks = JSON::JWK::Set.new(JSON.parse(File.read('test/fixtures/jwks.json'))['keys'])

        request.stubs(:params).returns('code' => code, 'state' => state)
        request.stubs(:path_info).returns('')

        strategy.options.client_options.host = 'example.com'
        strategy.options.discovery = true

        issuer = stub('OpenIDConnect::Discovery::Issuer')
        issuer.stubs(:issuer).returns('https://example.com/')
        ::OpenIDConnect::Discovery::Provider.stubs(:discover!).returns(issuer)

        config = stub('OpenIDConnect::Discovery::Provder::Config')
        config.stubs(:authorization_endpoint).returns('https://example.com/authorization')
        config.stubs(:token_endpoint).returns('https://example.com/token')
        config.stubs(:userinfo_endpoint).returns('https://example.com/userinfo')
        config.stubs(:jwks_uri).returns('https://example.com/jwks')
        config.stubs(:jwks).returns(jwks)

        ::OpenIDConnect::Discovery::Provider::Config.stubs(:discover!).with('https://example.com/').returns(config)

        id_token = stub('OpenIDConnect::ResponseObject::IdToken')
        id_token.stubs(:verify!).with(issuer: 'https://example.com/', client_id: @identifier, nonce: nonce).returns(true)
        ::OpenIDConnect::ResponseObject::IdToken.stubs(:decode).returns(id_token)

        strategy.unstub(:user_info)
        access_token = stub('OpenIDConnect::AccessToken')
        access_token.stubs(:access_token)
        access_token.stubs(:refresh_token)
        access_token.stubs(:expires_in)
        access_token.stubs(:scope)
        access_token.stubs(:id_token).returns(File.read('test/fixtures/id_token.txt'))
        client.expects(:access_token!).at_least_once.returns(access_token)
        access_token.expects(:userinfo!).returns(user_info)

        strategy.call!('rack.session' => { 'omniauth.state' => state, 'omniauth.nonce' => nonce })
        strategy.callback_phase
      end

      def test_callback_phase_with_error
        state = SecureRandom.hex(16)
        nonce = SecureRandom.hex(16)
        request.stubs(:params).returns('error' => 'invalid_request')
        request.stubs(:path_info).returns('')

        strategy.call!({'rack.session' => {'omniauth.state' => state, 'omniauth.nonce' => nonce}})
        strategy.expects(:fail!)
        strategy.callback_phase
      end

      def test_callback_phase_with_invalid_state
        code = SecureRandom.hex(16)
        state = SecureRandom.hex(16)
        nonce = SecureRandom.hex(16)
        request.stubs(:params).returns('code' => code, 'state' => 'foobar')
        request.stubs(:path_info).returns('')

        strategy.call!('rack.session' => { 'omniauth.state' => state, 'omniauth.nonce' => nonce })
        result = strategy.callback_phase

        assert result.kind_of?(Array)
        assert result.first == 401, "Expecting unauthorized"
      end

      def test_callback_phase_with_timeout
        code = SecureRandom.hex(16)
        state = SecureRandom.hex(16)
        nonce = SecureRandom.hex(16)
        request.stubs(:params).returns('code' => code, 'state' => state)
        request.stubs(:path_info).returns('')

        strategy.options.issuer = 'example.com'

        strategy.stubs(:access_token).raises(::Timeout::Error.new('error'))
        strategy.call!('rack.session' => { 'omniauth.state' => state, 'omniauth.nonce' => nonce })
        strategy.expects(:fail!)
        strategy.callback_phase
      end

      def test_callback_phase_with_etimeout
        code = SecureRandom.hex(16)
        state = SecureRandom.hex(16)
        nonce = SecureRandom.hex(16)
        request.stubs(:params).returns('code' => code, 'state' => state)
        request.stubs(:path_info).returns('')

        strategy.options.issuer = 'example.com'

        strategy.stubs(:access_token).raises(::Errno::ETIMEDOUT.new('error'))
        strategy.call!('rack.session' => { 'omniauth.state' => state, 'omniauth.nonce' => nonce })
        strategy.expects(:fail!)
        strategy.callback_phase
      end

      def test_callback_phase_with_socket_error
        code = SecureRandom.hex(16)
        state = SecureRandom.hex(16)
        nonce = SecureRandom.hex(16)
        request.stubs(:params).returns('code' => code, 'state' => state)
        request.stubs(:path_info).returns('')

        strategy.options.issuer = 'example.com'

        strategy.stubs(:access_token).raises(::SocketError.new('error'))
        strategy.call!('rack.session' => { 'omniauth.state' => state, 'omniauth.nonce' => nonce })
        strategy.expects(:fail!)
        strategy.callback_phase
      end

      def test_info
        info = strategy.info
        assert_equal user_info.name, info[:name]
        assert_equal user_info.email, info[:email]
        assert_equal user_info.preferred_username, info[:nickname]
        assert_equal user_info.given_name, info[:first_name]
        assert_equal user_info.family_name, info[:last_name]
        assert_equal user_info.gender, info[:gender]
        assert_equal user_info.picture, info[:image]
        assert_equal user_info.phone_number, info[:phone]
        assert_equal({ website: user_info.website }, info[:urls])
      end

      def test_extra
        assert_equal({ raw_info: user_info.as_json }, strategy.extra)
      end

      def test_credentials
        strategy.options.issuer = 'example.com'
        strategy.options.client_signing_alg = :RS256
        strategy.options.client_jwk_signing_key = File.read('test/fixtures/jwks.json')

        id_token = stub('OpenIDConnect::ResponseObject::IdToken')
        id_token.stubs(:verify!).returns(true)
        ::OpenIDConnect::ResponseObject::IdToken.stubs(:decode).returns(id_token)

        access_token = stub('OpenIDConnect::AccessToken')
        access_token.stubs(:access_token).returns(SecureRandom.hex(16))
        access_token.stubs(:refresh_token).returns(SecureRandom.hex(16))
        access_token.stubs(:expires_in).returns(Time.now)
        access_token.stubs(:scope).returns('openidconnect')
        access_token.stubs(:id_token).returns(File.read('test/fixtures/id_token.txt'))

        client.expects(:access_token!).returns(access_token)
        access_token.expects(:refresh_token).returns(access_token.refresh_token)
        access_token.expects(:expires_in).returns(access_token.expires_in)

        assert_equal(
          {
            id_token: access_token.id_token,
            token: access_token.access_token,
            refresh_token: access_token.refresh_token,
            expires_in: access_token.expires_in,
            scope: access_token.scope
          },
          strategy.credentials
        )
      end

      def test_option_send_nonce
        strategy.options.client_options[:host] = 'foobar.com'

        assert(strategy.authorize_uri =~ /nonce=/, 'URI must contain nonce')

        strategy.options.send_nonce = false
        assert(!(strategy.authorize_uri =~ /nonce=/), 'URI must not contain nonce')
      end

      def test_failure_endpoint_redirect
        OmniAuth.config.stubs(:failure_raise_out_environments).returns([])
        strategy.stubs(:env).returns({})
        request.stubs(:params).returns('error' => 'access denied')

        result = strategy.callback_phase

        assert(result.is_a? Array)
        assert(result[0] == 302, 'Redirect')
        assert(result[1]["Location"] =~ /\/auth\/failure/)
      end

      def test_state
        strategy.options.state = lambda { 42 }
        session = { "state" => 42 }

        expected_redirect = /&state=/
        strategy.options.issuer = 'example.com'
        strategy.options.client_options.host = 'example.com'
        strategy.expects(:redirect).with(regexp_matches(expected_redirect))
        strategy.request_phase

        # this should succeed as the correct state is passed with the request
        test_callback_phase(session, { 'state' => 42 })

        # the following should fail because the wrong state is passed to the callback
        code = SecureRandom.hex(16)
        request.stubs(:params).returns('code' => code, 'state' => 43)
        request.stubs(:path_info).returns('')
        strategy.call!('rack.session' => session)

        result = strategy.callback_phase

        assert result.kind_of?(Array)
        assert result.first == 401, 'Expecting unauthorized'
      end

      def test_option_client_auth_method
        state = SecureRandom.hex(16)
        nonce = SecureRandom.hex(16)

        opts = strategy.options.client_options
        opts[:host] = 'foobar.com'
        strategy.options.issuer = 'foobar.com'
        strategy.options.client_auth_method = :not_basic
        strategy.options.client_signing_alg = :RS256
        strategy.options.client_jwk_signing_key = File.read('test/fixtures/jwks.json')

        json_response = {
          access_token: 'test_access_token',
          id_token: File.read('test/fixtures/id_token.txt'),
          token_type: 'Bearer',
        }.to_json
        success = Struct.new(:status, :body).new(200, json_response)

        request.stubs(:path_info).returns('')
        strategy.call!('rack.session' => { 'omniauth.state' => state, 'omniauth.nonce' => nonce })

        id_token = stub('OpenIDConnect::ResponseObject::IdToken')
        id_token.stubs(:verify!).with(issuer: strategy.options.issuer, client_id: @identifier, nonce: nonce).returns(true)
        ::OpenIDConnect::ResponseObject::IdToken.stubs(:decode).returns(id_token)

        HTTPClient.any_instance.stubs(:post).with(
          "#{ opts.scheme }://#{ opts.host }:#{ opts.port }#{ opts.token_endpoint }",
          { scope: 'openid', grant_type: :client_credentials, client_id: @identifier, client_secret: @secret },
          {}
        ).returns(success)

        assert(strategy.send :access_token)
      end

      def test_public_key_with_jwks
        strategy.options.client_signing_alg = :RS256
        strategy.options.client_jwk_signing_key = File.read('./test/fixtures/jwks.json')

        assert_equal JSON::JWK::Set, strategy.public_key.class
      end

      def test_public_key_with_jwk
        strategy.options.client_signing_alg = :RS256
        jwks_str = File.read('./test/fixtures/jwks.json')
        jwks = JSON.parse(jwks_str)
        jwk = jwks['keys'].first
        strategy.options.client_jwk_signing_key = jwk.to_json

        assert_equal JSON::JWK, strategy.public_key.class
      end

      def test_public_key_with_x509
        strategy.options.client_signing_alg = :RS256
        strategy.options.client_x509_signing_key = File.read('./test/fixtures/test.crt')
        assert_equal OpenSSL::PKey::RSA, strategy.public_key.class
      end

      #def test_option_client_auth_method
      #  opts = strategy.options.client_options
      #  opts[:host] = "foobar.com"
      #  strategy.options.client_auth_method = :not_basic
      #  success = Struct.new(:status).new(200)

      #  HTTPClient.any_instance.stubs(:post).with(
      #    "#{opts.scheme}://#{opts.host}:#{opts.port}#{opts.token_endpoint}",
      #    {:grant_type => :client_credentials, :client_id => @identifier, :client_secret => @secret},
      #    {}
      #  ).returns(success)
      #  OpenIDConnect::Client.any_instance.stubs(:handle_success_response).with(success).returns(true)

      #  assert(strategy.send :access_token)
      #end

      #def test_failure_endpoint_redirect
      #  OmniAuth.config.stubs(:failure_raise_out_environments).returns([])
      #  strategy.stubs(:env).returns({})
      #  request.stubs(:params).returns({"error" => "access denied"})

      #  result = strategy.callback_phase

      #  assert(result.is_a? Array)
      #  assert(result[0] == 302, "Redirect")
      #  assert(result[1]["Location"] =~ /\/auth\/failure/)
      #end

      #def test_option_send_nonce
      #  strategy.options.client_options[:host] = "foobar.com"

      #  assert(strategy.authorize_uri =~ /nonce=/, "URI must contain nonce")

      #  strategy.options.send_nonce = false
      #  assert(!(strategy.authorize_uri =~ /nonce=/), "URI must not contain nonce")
      #end

      #def test_state
      #  strategy.options.state = lambda { 42 }
      #  session = { "state" => 42 }

      #  expected_redirect = /&state=/
      #  strategy.options.client_options.host = "example.com"
      #  strategy.expects(:redirect).with(regexp_matches(expected_redirect))
      #  strategy.request_phase

      #  # this should succeed as the correct state is passed with the request
      #  test_callback_phase(session, { "state" => 42 })

      #  # the following should fail because the wrong state is passed to the callback
      #  code = SecureRandom.hex(16)
      #  request.stubs(:params).returns({"code" => code, "state" => 43})
      #  request.stubs(:path_info).returns("")
      #  strategy.call!({"rack.session" => session})

      #  result = strategy.callback_phase

      #  assert result.kind_of?(Array)
      #  assert result.first == 401, "Expecting unauthorized"

      def test_public_key_with_hmac
        strategy.options.client_options.secret = 'secret'
        strategy.options.client_signing_alg = :HS256
        assert_equal strategy.options.client_options.secret, strategy.public_key
      end
    end
  end
end
