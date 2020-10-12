require 'net/http'

module OpenProject::TwoFactorAuthentication
  module TokenStrategy
    class Restdt < Base
      def self.validate!
        if configuration_params.nil?
          raise ArgumentError, 'Missing configuration hash'
        end
        validate_params configuration_params
      end

      def self.identifier
        :restdt
      end

      def self.mobile_token?
        true
      end

      def self.supported_channels
        [:sms, :voice]
      end

      private

      def service_params
        {
          url: URI(configuration_params[:service_url]),
          request_base: {
            user: configuration_params[:username],
            pass: configuration_params[:password],
            # The API supports XML and plain.
            # In the latter case, only the status code is returned.
            output: 'plain'
          }
        }
      end


      def send_sms
        Rails.logger.info { "[2FA] REST DT delivery sending SMS request for #{user.login}" }
        submit(build_user_params(onlycall: '0'))
      end

      def send_voice
        Rails.logger.info { "[2FA] REST DT delivery sending VOICE request for #{user.login}" }
        submit(build_user_params(onlycall: '1'))
      end

      def service_url
        service_params[:url]
      end

      ##
      # Prepares the request for the given user and token
      def build_user_params(merge_params)
        language = user.language == 'de' ? 'de' : 'en'

        merge_params[:lang] = language
        merge_params[:rec] = build_user_phone
        merge_params[:txt] = token
        service_params[:request_base].merge(merge_params)
      end

      ##
      # Prepares the user's phone number for commcit.
      # Required format: 0152xxxxxxx or 0049xxxxxxxxx
      # Stored format: +xx yyy yyy yyyy (optional whitespacing)
      def build_user_phone
        phone = device.phone_number
        phone.gsub!(/[\+]/, '00')
        phone.gsub!(/\s/, '')

        phone
      end

      def submit(params)
        http = Net::HTTP.new(service_url.host, service_url.port)
        http.use_ssl = true

        request = Net::HTTP::Post.new(service_url.request_uri)
        request.set_form_data(params)
        response = http.request(request)

        # What a stupid API is this to return the code in their body
        # instead of the actual response code?
        code = response.body.strip

        if code == '200'
          Rails.logger.info { "[2FA] REST DT delivery succeeded for user #{user.login}" }
          return
        end

        Rails.logger.error { "[2FA] REST DT delivery failed for user #{user.login} " \
                            "(Error #{response.body})" }

        raise I18n.t('two_factor_authentication.restdt.delivery_failed_with_code', code: code)
      end

      def self.validate_params(params)
        %i(username password service_url).each do |key|
          unless params[key]
            raise ArgumentError, "REST DT delivery settings is missing mandatory key :#{key}"
          end
        end
      end
    end
  end
end
