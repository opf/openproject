# frozen_string_literal: true

module Bim
  module Authentication
    # API token authentication for external integrations (Revit, etc.)
    class ApiTokenAdapter < Adapter
      def authenticate(credentials)
        return nil unless credentials[:api_token]

        token = Bim::ApiToken.find_by_token(credentials[:api_token])
        return nil unless token&.valid_token?

        # Update token usage
        token.touch_last_used!(ip_address: credentials[:ip_address])

        # Return the user associated with the token
        token.user
      end

      def priority
        5 # Highest priority - check API tokens first
      end
    end
  end
end
