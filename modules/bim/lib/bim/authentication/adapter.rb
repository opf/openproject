# frozen_string_literal: true

module Bim
  module Authentication
    # Abstract base class for authentication adapters
    # Provides a pluggable authentication system for optional SSO, LDAP, 2FA, etc.
    class Adapter
      # Authenticate user with given credentials
      # @param credentials [Hash] Authentication credentials
      # @return [User, nil] Authenticated user or nil
      def authenticate(credentials)
        raise NotImplementedError, "#{self.class} must implement #authenticate"
      end

      # Check if this adapter supports two-factor authentication
      # @return [Boolean]
      def supports_2fa?
        false
      end

      # Check if this adapter is currently enabled
      # @return [Boolean]
      def enabled?
        true
      end

      # Get adapter name for logging
      # @return [String]
      def name
        self.class.name.split('::').last
      end

      # Priority for adapter chain (lower = higher priority)
      # @return [Integer]
      def priority
        100
      end
    end
  end
end
