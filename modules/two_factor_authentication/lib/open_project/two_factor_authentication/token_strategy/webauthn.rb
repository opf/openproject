require 'webauthn'

module OpenProject::TwoFactorAuthentication
  module TokenStrategy
    class Webauthn < Base
      def self.supported_channels
        [:webauthn]
      end

      def self.device_type
        :webauthn
      end

      def self.identifier
        :webauthn
      end
    end
  end
end
