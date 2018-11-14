require 'rotp'

module OpenProject::TwoFactorAuthentication
module TokenStrategy
    class Totp < Base

      def verify(input_token)
        result = device.verify_token input_token

        # Token did not match value or surrounding drift
        raise I18n.t(:notice_account_otp_invalid) unless result == true

        result
      end

      def transmit_success_message
        nil
      end

      def self.mobile_token?
        false
      end

      def self.supported_channels
        [:totp]
      end

      def self.device_type
        :totp
      end

      def self.identifier
        :totp
      end

      private

      def send_totp
        Rails.logger.info { "[2FA] ROTP in progress for #{user.login}" }
        # Nothing to do here
      end
    end
  end
end