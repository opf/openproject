# frozen_string_literal: true

module Doorkeeper
  module OAuth
    class RefreshTokenRequest < BaseRequest
      include OAuth::Helpers

      validate :token_presence, error: :invalid_request
      validate :token,        error: :invalid_grant
      validate :client,       error: :invalid_client
      validate :client_match, error: :invalid_grant
      validate :scope,        error: :invalid_scope

      attr_reader :access_token, :client, :credentials, :refresh_token
      attr_reader :missing_param

      def initialize(server, refresh_token, credentials, parameters = {})
        @server = server
        @refresh_token = refresh_token
        @credentials = credentials
        @original_scopes = parameters[:scope] || parameters[:scopes]
        @refresh_token_parameter = parameters[:refresh_token]
        @client = load_client(credentials) if credentials
      end

      private

      def load_client(credentials)
        server_config.application_model.by_uid_and_secret(credentials.uid, credentials.secret)
      end

      def before_successful_response
        refresh_token.transaction do
          refresh_token.lock!
          raise Errors::InvalidGrantReuse if refresh_token.revoked?

          refresh_token.revoke unless refresh_token_revoked_on_use?
          create_access_token
        end
        super
      end

      def refresh_token_revoked_on_use?
        server_config.access_token_model.refresh_token_revoked_on_use?
      end

      def default_scopes
        refresh_token.scopes
      end

      def create_access_token
        attributes = {}

        resource_owner =
          if Doorkeeper.config.polymorphic_resource_owner?
            refresh_token.resource_owner
          else
            refresh_token.resource_owner_id
          end

        if refresh_token_revoked_on_use?
          attributes[:previous_refresh_token] = refresh_token.refresh_token
        end

        @access_token = server_config.access_token_model.create_for(
          application: refresh_token.application,
          resource_owner: resource_owner,
          scopes: scopes,
          expires_in: refresh_token.expires_in,
          use_refresh_token: true,
          **attributes,
        )
      end

      def validate_token_presence
        @missing_param = :refresh_token if refresh_token.blank? && @refresh_token_parameter.blank?

        @missing_param.nil?
      end

      def validate_token
        refresh_token.present? && !refresh_token.revoked?
      end

      def validate_client
        return true if credentials.blank?

        client.present?
      end

      # @see https://tools.ietf.org/html/draft-ietf-oauth-v2-22#section-1.5
      #
      def validate_client_match
        return true if refresh_token.application_id.blank?

        client && refresh_token.application_id == client.id
      end

      def validate_scope
        if @original_scopes.present?
          ScopeChecker.valid?(
            scope_str: @original_scopes,
            server_scopes: refresh_token.scopes,
          )
        else
          true
        end
      end
    end
  end
end
