require 'messagebird'

module OpenProject::TwoFactorAuthentication
  module TokenStrategy
    class MessageBird < Base
      def self.validate!
        if configuration_params.nil?
          raise ArgumentError, 'Missing configuration hash'
        end
        validate_params configuration_params
      end

      def self.identifier
        :message_bird
      end

      def self.mobile_token?
        true
      end

      def self.supported_channels
        %i[sms voice]
      end

      private

      def send_sms
        Rails.logger.info { "[2FA] MessageBird delivery sending SMS request for #{user.login}" }
        params = build_user_params

        # Validity 720 = 15 minutes of login token validity - 3 minutes buffer
        response = message_bird_client.message_create Setting.app_title,
                                                      params[:recipients],
                                                      params[:message],
                                                      validity: 720

        raise "Failed to deliver SMS" if response.recipients['totalDeliveryFailedCount'] > 0
      rescue => e
        Rails.logger.error("[2FA] MessageBird SMS delivery failed for user #{user.login}. Error: #{e} #{e.message}")
        raise I18n.t('two_factor_authentication.message_bird.sms_delivery_failed')
      end

      def send_voice
        Rails.logger.info { "[2FA] MessageBird delivery sending VOICE request for #{user.login}" }

        params = build_user_params
        response = message_bird_client.voice_message_create params[:recipients],
                                                            params[:message],
                                                            ifMachine: :continue,
                                                            language: params[:language]

        raise "Failed to initiate voice message" if response.recipients['totalDeliveryFailedCount'] > 0
      rescue => e
        Rails.logger.error("[2FA] MessageBird VOICE delivery failed for user #{user.login}. Error: #{e} #{e.message}")
        raise I18n.t('two_factor_authentication.message_bird.voice_delivery_failed')
      end

      def message_bird_client
        ::MessageBird::Client.new(configuration_params[:apikey])
      end

      ##
      # Prepares the request for the given user and token
      def build_user_params(params = {})
        build_localized_message(params)
        build_recipients(params)

        params
      end

      ##
      # Available languages for the voice message
      def available_languages
        %i[
          de-de
          en-us
          en-gb
          nl-nl
          da-dk
          cy-gb
          en-au
          en-in
          es-es
          es-mx
          es-us
          fr-ca
          fr-fr
          is-is
          it-it
          ja-jp
          ko-kr
          nb-no
          pl-pl
          pt-pt
          pt-br
          ro-ro
          ru-ru
          sv-se
          tr-tr
          zh-cn
        ]
      end

      ##
      # Select a matching language from the available languages
      def build_localized_message(params)
        locale_key = (user.language || Setting.default_language)

        # Check if the translation exist or fall back to english
        language =
          if has_localized_text? locale_key
            get_matching_language(locale_key.downcase.to_sym)
          end

        params[:language] = language.presence || fallback_language
        params[:message] = localized_message(locale_key, token)
      end

      def get_matching_language(language)
        if available_languages.include?(language)
          language
        elsif match = available_languages.detect { |key| key =~ /\A#{language}-/ }
          match
        end
      end

      ##

      ##
      # Fallback language
      def fallback_language
        :"en-us"
      end


      ##
      # Checks whether the locale has a non-fallback
      def has_localized_text?(locale_key)
        localized_message(locale_key, token, fallback: false, raise_on_missing: true)
        true
      rescue ::I18n::MissingTranslationData
        false
      end

      ##
      # Localize the message
      def localized_message(locale_key, token_value, fallback: true, raise_on_missing: false)
        pause = ''

        # Output pauses for TTS in voice mode
        if channel == :voice
          token_value = token_value.split('').join('<break time="400ms"/>')
          pause = '<break time="500ms"/>'
        end

        I18n.t "two_factor_authentication.text_otp_delivery_message_#{channel}",
               pause: pause,
               token: token_value,
               app_title: Setting.app_title, locale: locale_key,
               fallback: fallback, raise: raise_on_missing
      end

      ##
      # Prepares the user's phone number for messagebird (msisdn).
      # Stored format: +xx yyy yyy yyyy (optional whitespacing)
      # Output format: xxyyyyyyyyyy
      def build_recipients(params)
        phone = device.phone_number
        phone.gsub!(/[\+\s]/, '')

        params[:recipients] = phone
      end

      def self.validate_params(params)
        %i(apikey).each do |key|
          unless params[key]
            raise ArgumentError, "MessageBird delivery settings is missing mandatory #{key}"
          end
        end
      end
    end
  end
end
