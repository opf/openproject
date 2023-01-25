require 'rotp'

module OpenProject::TwoFactorAuthentication
  module TokenStrategy
    class Totp < Base
      def verify(input_token)
        result = device.verify_token input_token

        # Token did not match value or surrounding drift
        raise verification_failed_message unless result == true

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

      def verification_failed_message
        if device.active?
          I18n.t(:notice_account_otp_invalid)
        else
          I18n.t('two_factor_authentication.devices.totp.otp_invalid_drift_notice',
                 time: Time.zone.now.in_time_zone(User.current.time_zone).strftime('%T'))
        end
      end

      def send_totp
        Rails.logger.info { "[2FA] ROTP in progress for #{user.login}" }
        # Nothing to do here
      end
    end
  end
end
