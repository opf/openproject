module OpenProject::TwoFactorAuthentication
  module TokenStrategy
    class Developer < Base

      def self.validate!
        if Rails.env.production?
          raise "You're trying to use the developer strategy in production. Don't!"
        end
      end

      def self.identifier
        :developer
      end

      def self.supported_channels
        [:sms, :voice]
      end

      def self.mobile_token?
        true
      end

      def transmit_success_message
        I18n.t(:notice_developer_strategy_otp, token: token, channel: channel)
      end

      private

      def send_sms
        Rails.logger.info { "[2FA] Mocked SMS token #{token} for #{user.login}" }
      end

      def send_voice
        Rails.logger.info { "[2FA] Mocked voice token #{token} for #{user.login}" }
      end
    end
  end
end