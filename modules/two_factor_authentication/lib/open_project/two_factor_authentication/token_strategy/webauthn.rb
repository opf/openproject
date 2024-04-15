require "webauthn"

module OpenProject::TwoFactorAuthentication
  module TokenStrategy
    class Webauthn < Base
      def verify(webauthn_credential, webauthn_challenge:, webauthn_relying_party:)
        # This will raise WebAuthn::Error
        credential = webauthn_relying_party.verify_authentication(
          webauthn_credential,
          webauthn_challenge,
          sign_count: device.webauthn_sign_count,
          public_key: device.webauthn_public_key
        )

        device.update!(webauthn_sign_count: credential.sign_count)
        true
      end

      def transmit_success_message
        nil
      end

      def self.mobile_token?
        false
      end

      def self.supported_channels
        [:webauthn]
      end

      def self.device_type
        :webauthn
      end

      def self.identifier
        :webauthn
      end

      private

      def send_webauthn
        Rails.logger.info { "[2FA] WebAuthn in progress for #{user.login}" }
        # Nothing to do here
      end
    end
  end
end
