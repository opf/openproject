require 'net/http'
require 'aws-sdk'

module OpenProject::TwoFactorAuthentication
  module TokenStrategy
    class Sns < Base
      cattr_accessor :service_params

      def self.validate!
        super
        validate_params
      end

      def self.identifier
        :sns
      end

      def self.mobile_token?
        true
      end

      def self.supported_channels
        [:sms]
      end

      private

      def send_sms
        Rails.logger.info { "[2FA] SNS delivery sending SMS request for #{user.login}" }
        submit
      end

      ##
      # Prepares the request for the given user and token
      def build_sms_params
        {
          phone_number: build_user_phone,
          message: build_token_text(token)
        }
      end

      def build_token_text(token)
        I18n.t('two_factor_authentication.text_otp_delivery_message_sms', app_title: Setting.app_title, token: token)
      end

      ##
      # Prepares the user's phone number for commcit.
      # Required format: +xxaaabbbccc
      # Stored format: +xx yyy yyy yyyy (optional whitespacing)
      def build_user_phone
        phone = device.phone_number
        phone.gsub!(/\s/, '')

        phone
      end

      def submit
        aws_params = self.configuration_params.slice :region, :access_key_id, :secret_access_key
        sns = ::Aws::SNS::Client.new aws_params

        sns.set_sms_attributes(
          attributes: {
            # Use transactional message type to ensure timely delivery.
            # Amazon SNS optimizes the message delivery to achieve the highest reliability.
            'DefaultSMSType' => 'Transactional',

            # Set sender ID name (may not be supported in all countries)
            'DefaultSenderID' => self.configuration_params.fetch(:sender_id, 'OpenProject')
          }
        )

        result = sns.publish(build_sms_params)

        # If successful, SNS returns an object with a message id
        message_id = result.try :message_id

        if message_id.present?
          Rails.logger.info { "[2FA] SNS delivery succeeded for user #{user.login}: #{message_id}" }
          return
        end

        raise result
      rescue => e
        Rails.logger.error { "[2FA] SNS delivery failed for user #{user.login} " \
                            "(Error: #{e})" }

        raise I18n.t('two_factor_authentication.sns.delivery_failed')
      end

      def self.validate_params
        %i(access_key_id secret_access_key region).each do |key|
          unless configuration_params[key]
            raise ArgumentError, "Amazon SNS delivery settings is missing mandatory key :#{key}"
          end
        end
      end
    end
  end
end
