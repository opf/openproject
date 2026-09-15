# frozen_string_literal: true

module Bim
  module Authentication
    # SSO/SAML authentication adapter (optional, disabled by default)
    # Enable by setting ENV['BIM_SSO_ENABLED'] = 'true'
    class SsoAdapter < Adapter
      def self.available?
        ENV['BIM_SSO_ENABLED'] == 'true'
      end

      def enabled?
        self.class.available?
      end

      def authenticate(credentials)
        return nil unless credentials[:saml_response]

        # Parse SAML response
        saml_response = parse_saml_response(credentials[:saml_response])
        return nil unless saml_response&.valid?

        # Find or create user from SAML attributes
        find_or_create_user_from_saml(saml_response)
      end

      def priority
        20 # Try after API tokens and database
      end

      private

      def parse_saml_response(response_xml)
        # Implementation would use ruby-saml or similar
        # Placeholder for now
        Rails.logger.warn "SSO authentication attempted but not fully implemented"
        nil
      end

      def find_or_create_user_from_saml(saml_response)
        # Extract user info from SAML attributes
        # Find or create user
        # Placeholder for now
        nil
      end
    end
  end
end
