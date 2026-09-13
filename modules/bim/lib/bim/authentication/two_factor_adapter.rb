# frozen_string_literal: true

module Bim
  module Authentication
    # Two-Factor Authentication adapter (optional, disabled by default)
    # Enable by setting ENV['BIM_2FA_ENABLED'] = 'true'
    class TwoFactorAdapter < Adapter
      def self.available?
        ENV['BIM_2FA_ENABLED'] == 'true'
      end

      def enabled?
        self.class.available?
      end

      def supports_2fa?
        true
      end

      def authenticate(credentials)
        # 2FA is typically a second step after primary authentication
        # This adapter verifies the 2FA token
        return nil unless credentials[:user] && credentials[:totp_token]

        verify_totp(credentials[:user], credentials[:totp_token])
      end

      def verify_totp(user, token)
        # Implementation would use rotp or similar
        # Placeholder for now
        Rails.logger.warn "2FA verification attempted but not fully implemented"
        nil
      end

      def priority
        40 # Lowest priority - 2FA is secondary verification
      end
    end
  end
end
