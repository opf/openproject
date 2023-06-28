require 'webauthn'

module OpenProject::TwoFactorAuthentication
  module TokenStrategy
    class Webauthn < Base
      def verify(webauthn_params)
        webauthn_credential = WebAuthn::Credential.from_get(webauthn_params)

        # TODO: Device finding can happen by the provided ID

        # TODO: Access session
        authentication_challenge = "foo"

        # This will raise WebAuthn::Error
        webauthn_credential.verify(
          authentication_challenge,
          public_key: device.webauthn_public_key,
          sign_count: device.webauthn_sign_count
        )

        device.update!(webauthn_sign_count: webauthn_credential.sign_count)
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
