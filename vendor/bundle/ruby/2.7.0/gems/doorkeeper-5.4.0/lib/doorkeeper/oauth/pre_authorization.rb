# frozen_string_literal: true

module Doorkeeper
  module OAuth
    class PreAuthorization
      include Validations

      validate :client_id, error: :invalid_request
      validate :client, error: :invalid_client
      validate :client_supports_grant_flow, error: :unauthorized_client
      validate :resource_owner_authorize_for_client, error: :invalid_client
      validate :redirect_uri, error: :invalid_redirect_uri
      validate :params, error: :invalid_request
      validate :response_type, error: :unsupported_response_type
      validate :scopes, error: :invalid_scope
      validate :code_challenge_method, error: :invalid_code_challenge_method

      attr_reader :client, :code_challenge, :code_challenge_method, :missing_param,
                  :redirect_uri, :resource_owner, :response_type, :state

      def initialize(server, parameters = {}, resource_owner = nil)
        @server                = server
        @client_id             = parameters[:client_id]
        @response_type         = parameters[:response_type]
        @redirect_uri          = parameters[:redirect_uri]
        @scope                 = parameters[:scope]
        @state                 = parameters[:state]
        @code_challenge        = parameters[:code_challenge]
        @code_challenge_method = parameters[:code_challenge_method]
        @resource_owner        = resource_owner
      end

      def authorizable?
        valid?
      end

      def scopes
        Scopes.from_string(scope)
      end

      def scope
        @scope.presence || (server.default_scopes.presence && build_scopes)
      end

      def error_response
        if error == :invalid_request
          OAuth::InvalidRequestResponse.from_request(
            self,
            response_on_fragment: response_on_fragment?,
          )
        else
          OAuth::ErrorResponse.from_request(self, response_on_fragment: response_on_fragment?)
        end
      end

      def as_json(_options = nil)
        pre_auth_hash
      end

      private

      attr_reader :client_id, :server

      def build_scopes
        client_scopes = client.scopes
        if client_scopes.blank?
          server.default_scopes.to_s
        else
          (server.default_scopes & client_scopes).to_s
        end
      end

      def validate_client_id
        @missing_param = :client_id if client_id.blank?
        @missing_param.nil?
      end

      def validate_client
        @client = OAuth::Client.find(client_id)
        @client.present?
      end

      def validate_client_supports_grant_flow
        Doorkeeper.config.allow_grant_flow_for_client?(grant_type, client.application)
      end

      def validate_redirect_uri
        return false if redirect_uri.blank?

        Helpers::URIChecker.valid_for_authorization?(
          redirect_uri,
          client.redirect_uri,
        )
      end

      def validate_params
        @missing_param = if response_type.blank?
                           :response_type
                         elsif @scope.blank? && server.default_scopes.blank?
                           :scope
                         end

        @missing_param.nil?
      end

      def validate_response_type
        server.authorization_response_types.include?(response_type)
      end

      def validate_scopes
        Helpers::ScopeChecker.valid?(
          scope_str: scope,
          server_scopes: server.scopes,
          app_scopes: client.scopes,
          grant_type: grant_type,
        )
      end

      def validate_code_challenge_method
        code_challenge.blank? ||
          (code_challenge_method.present? && code_challenge_method =~ /^plain$|^S256$/)
      end

      def validate_resource_owner_authorize_for_client
        # The `authorize_resource_owner_for_client` config option is used for this validation
        client.application.authorized_for_resource_owner?(@resource_owner)
      end

      def response_on_fragment?
        response_type == "token"
      end

      def grant_type
        response_type == "code" ? AUTHORIZATION_CODE : IMPLICIT
      end

      def pre_auth_hash
        {
          client_id: client.uid,
          redirect_uri: redirect_uri,
          state: state,
          response_type: response_type,
          scope: scope,
          client_name: client.name,
          status: I18n.t("doorkeeper.pre_authorization.status"),
        }
      end
    end
  end
end
