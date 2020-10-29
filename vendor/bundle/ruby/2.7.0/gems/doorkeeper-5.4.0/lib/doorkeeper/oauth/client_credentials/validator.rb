# frozen_string_literal: true

module Doorkeeper
  module OAuth
    module ClientCredentials
      class Validator
        include Validations
        include OAuth::Helpers

        validate :client, error: :invalid_client
        validate :client_supports_grant_flow, error: :unauthorized_client
        validate :scopes, error: :invalid_scope

        def initialize(server, request)
          @server = server
          @request = request
          @client = request.client

          validate
        end

        private

        def validate_client
          @client.present?
        end

        def validate_client_supports_grant_flow
          return if @client.blank?

          Doorkeeper.config.allow_grant_flow_for_client?(
            Doorkeeper::OAuth::CLIENT_CREDENTIALS,
            @client.application,
          )
        end

        def validate_scopes
          return true if @request.scopes.blank?

          application_scopes = if @client.present?
                                 @client.application.scopes
                               else
                                 ""
                               end

          ScopeChecker.valid?(
            scope_str: @request.scopes.to_s,
            server_scopes: @server.scopes,
            app_scopes: application_scopes,
            grant_type: Doorkeeper::OAuth::CLIENT_CREDENTIALS,
          )
        end
      end
    end
  end
end
