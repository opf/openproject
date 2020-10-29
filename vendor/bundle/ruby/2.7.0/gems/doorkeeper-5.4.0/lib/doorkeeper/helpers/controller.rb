# frozen_string_literal: true

# Define methods that can be called in any controller that inherits from
# Doorkeeper::ApplicationMetalController or Doorkeeper::ApplicationController
module Doorkeeper
  module Helpers
    # Rails controller helpers.
    #
    module Controller
      private

      # :doc:
      def authenticate_resource_owner!
        current_resource_owner
      end

      # :doc:
      def current_resource_owner
        @current_resource_owner ||= begin
          instance_eval(&Doorkeeper.config.authenticate_resource_owner)
        end
      end

      def resource_owner_from_credentials
        instance_eval(&Doorkeeper.config.resource_owner_from_credentials)
      end

      # :doc:
      def authenticate_admin!
        instance_eval(&Doorkeeper.config.authenticate_admin)
      end

      def server
        @server ||= Server.new(self)
      end

      # :doc:
      def doorkeeper_token
        @doorkeeper_token ||= OAuth::Token.authenticate(request, *config_methods)
      end

      def config_methods
        @config_methods ||= Doorkeeper.config.access_token_methods
      end

      def get_error_response_from_exception(exception)
        if exception.respond_to?(:response)
          exception.response
        elsif exception.type == :invalid_request
          OAuth::InvalidRequestResponse.new(
            name: exception.type,
            state: params[:state],
            missing_param: exception.missing_param,
          )
        else
          OAuth::ErrorResponse.new(name: exception.type, state: params[:state])
        end
      end

      def handle_token_exception(exception)
        error = get_error_response_from_exception(exception)
        headers.merge!(error.headers)
        self.response_body = error.body.to_json
        self.status = error.status
      end

      def skip_authorization?
        !!instance_exec(
          [server.current_resource_owner, @pre_auth.client],
          &Doorkeeper.config.skip_authorization
        )
      end

      def enforce_content_type
        if (request.put? || request.post? || request.patch?) && !x_www_form_urlencoded?
          render json: {}, status: :unsupported_media_type
        end
      end

      def x_www_form_urlencoded?
        request.content_type == "application/x-www-form-urlencoded"
      end
    end
  end
end
