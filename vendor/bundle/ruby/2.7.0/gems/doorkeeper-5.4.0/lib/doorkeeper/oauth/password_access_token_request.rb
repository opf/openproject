# frozen_string_literal: true

module Doorkeeper
  module OAuth
    class PasswordAccessTokenRequest < BaseRequest
      include OAuth::Helpers

      validate :client, error: :invalid_client
      validate :client_supports_grant_flow, error: :unauthorized_client
      validate :resource_owner, error: :invalid_grant
      validate :scopes, error: :invalid_scope

      attr_reader :client, :resource_owner, :parameters, :access_token

      def initialize(server, client, resource_owner, parameters = {})
        @server          = server
        @resource_owner  = resource_owner
        @client          = client
        @parameters      = parameters
        @original_scopes = parameters[:scope]
        @grant_type      = Doorkeeper::OAuth::PASSWORD
      end

      private

      def before_successful_response
        find_or_create_access_token(client, resource_owner, scopes, server)
        super
      end

      def validate_scopes
        return true if scopes.blank?

        ScopeChecker.valid?(
          scope_str: scopes.to_s,
          server_scopes: server.scopes,
          app_scopes: client.try(:scopes),
          grant_type: grant_type,
        )
      end

      def validate_resource_owner
        resource_owner.present?
      end

      def validate_client
        !parameters[:client_id] || client.present?
      end

      def validate_client_supports_grant_flow
        server_config.allow_grant_flow_for_client?(grant_type, client&.application)
      end
    end
  end
end
