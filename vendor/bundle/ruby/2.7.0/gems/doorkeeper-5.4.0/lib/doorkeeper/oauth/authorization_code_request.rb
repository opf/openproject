# frozen_string_literal: true

module Doorkeeper
  module OAuth
    class AuthorizationCodeRequest < BaseRequest
      validate :pkce_support, error: :invalid_request
      validate :params,       error: :invalid_request
      validate :client,       error: :invalid_client
      validate :grant,        error: :invalid_grant
      # @see https://tools.ietf.org/html/rfc6749#section-5.2
      validate :redirect_uri, error: :invalid_grant
      validate :code_verifier, error: :invalid_grant

      attr_reader :grant, :client, :redirect_uri, :access_token, :code_verifier,
                  :invalid_request_reason, :missing_param

      def initialize(server, grant, client, parameters = {})
        @server = server
        @client = client
        @grant  = grant
        @grant_type = Doorkeeper::OAuth::AUTHORIZATION_CODE
        @redirect_uri = parameters[:redirect_uri]
        @code_verifier = parameters[:code_verifier]
      end

      private

      def before_successful_response
        grant.transaction do
          grant.lock!
          raise Errors::InvalidGrantReuse if grant.revoked?

          grant.revoke

          resource_owner = if Doorkeeper.config.polymorphic_resource_owner?
                             grant.resource_owner
                           else
                             grant.resource_owner_id
                           end

          find_or_create_access_token(
            grant.application,
            resource_owner,
            grant.scopes,
            server,
          )
        end

        super
      end

      def pkce_supported?
        Doorkeeper.config.access_grant_model.pkce_supported?
      end

      def validate_pkce_support
        @invalid_request_reason = :not_support_pkce if grant &&
                                                       !pkce_supported? &&
                                                       code_verifier.present?

        @invalid_request_reason.nil?
      end

      def validate_params
        @missing_param = if grant&.uses_pkce? && code_verifier.blank?
                           :code_verifier
                         elsif redirect_uri.blank?
                           :redirect_uri
                         end

        @missing_param.nil?
      end

      def validate_client
        client.present?
      end

      def validate_grant
        return false unless grant && grant.application_id == client.id

        grant.accessible?
      end

      def validate_redirect_uri
        Helpers::URIChecker.valid_for_authorization?(
          redirect_uri,
          grant.redirect_uri,
        )
      end

      # if either side (server or client) request PKCE, check the verifier
      # against the DB - if PKCE is supported
      def validate_code_verifier
        return true unless grant.uses_pkce? || code_verifier
        return false unless pkce_supported?

        if grant.code_challenge_method == "S256"
          grant.code_challenge == generate_code_challenge(code_verifier)
        elsif grant.code_challenge_method == "plain"
          grant.code_challenge == code_verifier
        else
          false
        end
      end

      def generate_code_challenge(code_verifier)
        server_config.access_grant_model.generate_code_challenge(code_verifier)
      end
    end
  end
end
