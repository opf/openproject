# frozen_string_literal: true

module Bim
  module Authentication
    # LDAP authentication adapter (optional, disabled by default)
    # Enable by setting ENV['BIM_LDAP_ENABLED'] = 'true'
    class LdapAdapter < Adapter
      def self.available?
        ENV['BIM_LDAP_ENABLED'] == 'true'
      end

      def enabled?
        self.class.available?
      end

      def authenticate(credentials)
        return nil unless credentials[:username] && credentials[:password]
        return nil unless ldap_configured?

        ldap_bind(credentials[:username], credentials[:password])
      end

      def priority
        30 # Try after SSO
      end

      private

      def ldap_configured?
        ENV['LDAP_HOST'].present? && ENV['LDAP_BASE_DN'].present?
      end

      def ldap_bind(username, password)
        # Implementation would use net-ldap or similar
        # Placeholder for now
        Rails.logger.warn "LDAP authentication attempted but not fully implemented"
        nil
      end
    end
  end
end
