module Rack
  module OAuth2
    class Client
      include AttrRequired, AttrOptional
      attr_required :identifier
      attr_optional :secret, :private_key, :certificate, :redirect_uri, :scheme, :host, :port, :authorization_endpoint, :token_endpoint

      def initialize(attributes = {})
        (required_attributes + optional_attributes).each do |key|
          self.send :"#{key}=", attributes[key]
        end
        @grant = Grant::ClientCredentials.new
        @authorization_endpoint ||= '/oauth2/authorize'
        @token_endpoint ||= '/oauth2/token'
        attr_missing!
      end

      def authorization_uri(params = {})
        params[:redirect_uri] ||= self.redirect_uri
        params[:response_type] ||= :code
        params[:response_type] = Array(params[:response_type]).join(' ')
        params[:scope] = Array(params[:scope]).join(' ')
        Util.redirect_uri absolute_uri_for(authorization_endpoint), :query, params.merge(
          client_id: self.identifier
        )
      end

      def authorization_code=(code)
        @grant = Grant::AuthorizationCode.new(
          code: code,
          redirect_uri: self.redirect_uri
        )
      end

      def resource_owner_credentials=(credentials)
        @grant = Grant::Password.new(
          username: credentials.first,
          password: credentials.last
        )
      end

      def refresh_token=(token)
        @grant = Grant::RefreshToken.new(
          refresh_token: token
        )
      end

      def jwt_bearer=(assertion)
        @grant = Grant::JWTBearer.new(
          assertion: assertion
        )
      end

      def saml2_bearer=(assertion)
        @grant = Grant::SAML2Bearer.new(
          assertion: assertion
        )
      end

      def subject_token=(subject_token, subject_token_type = URN::TokenType::JWT)
        @grant = Grant::TokenExchange.new(
          subject_token: subject_token,
          subject_token_type: subject_token_type
        )
      end

      def force_token_type!(token_type)
        @forced_token_type = token_type.to_s
      end

      def access_token!(*args)
        headers, params = {}, @grant.as_json
        http_client = Rack::OAuth2.http_client

        # NOTE:
        #  Using Array#extract_options! for backward compatibility.
        #  Until v1.0.5, the first argument was 'client_auth_method' in scalar.
        options = args.extract_options!
        client_auth_method = args.first || options.delete(:client_auth_method).try(:to_sym) || :basic

        params[:scope] = Array(options.delete(:scope)).join(' ') if options[:scope].present?
        params.merge! options

        case client_auth_method
        when :basic
          cred = Base64.strict_encode64 [
            Util.www_form_url_encode(identifier),
            Util.www_form_url_encode(secret)
          ].join(':')
          headers.merge!(
            'Authorization' => "Basic #{cred}"
          )
        when :jwt_bearer
          params.merge!(
            client_assertion_type: URN::ClientAssertionType::JWT_BEARER
          )
          # NOTE: optionally auto-generate client_assertion.
          if params[:client_assertion].blank?
            require 'json/jwt'
            params[:client_assertion] = JSON::JWT.new(
              iss: identifier,
              sub: identifier,
              aud: absolute_uri_for(token_endpoint),
              jti: SecureRandom.hex(16),
              iat: Time.now,
              exp: 3.minutes.from_now
            ).sign(private_key || secret).to_s
          end
        when :saml2_bearer
          params.merge!(
            client_assertion_type: URN::ClientAssertionType::SAML2_BEARER
          )
        when :mtls
          params.merge!(
            client_id: identifier
          )
          http_client.ssl_config.client_key = private_key
          http_client.ssl_config.client_cert = certificate
        else
          params.merge!(
            client_id: identifier,
            client_secret: secret
          )
        end
        handle_response do
          http_client.post(
            absolute_uri_for(token_endpoint),
            Util.compact_hash(params),
            headers
          )
        end
      end

      private

      def absolute_uri_for(endpoint)
        _endpoint_ = Util.parse_uri endpoint
        _endpoint_.scheme ||= self.scheme || 'https'
        _endpoint_.host ||= self.host
        _endpoint_.port ||= self.port
        raise 'No Host Info' unless _endpoint_.host
        _endpoint_.to_s
      end

      def handle_response
        response = yield
        case response.status
        when 200..201
          handle_success_response response
        else
          handle_error_response response
        end
      end

      def handle_success_response(response)
        token_hash = JSON.parse(response.body).with_indifferent_access
        case (@forced_token_type || token_hash[:token_type]).try(:downcase)
        when 'bearer'
          AccessToken::Bearer.new(token_hash)
        when 'mac'
          AccessToken::MAC.new(token_hash)
        when nil
          AccessToken::Legacy.new(token_hash)
        else
          raise 'Unknown Token Type'
        end
      rescue JSON::ParserError
        # NOTE: Facebook support (They don't use JSON as token response)
        AccessToken::Legacy.new Rack::Utils.parse_nested_query(response.body).with_indifferent_access
      end

      def handle_error_response(response)
        error = JSON.parse(response.body).with_indifferent_access
        raise Error.new(response.status, error)
      rescue JSON::ParserError
        raise Error.new(response.status, error: 'Unknown', error_description: response.body)
      end
    end
  end
end

require 'rack/oauth2/client/error'
require 'rack/oauth2/client/grant'
