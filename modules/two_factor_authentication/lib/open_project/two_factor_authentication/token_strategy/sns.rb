# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "net/http"
require "aws-sdk-sns"

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

      def self.validate_params
        %w[access_key_id secret_access_key region].each do |key|
          unless configuration_params[key]
            raise ArgumentError, "Amazon SNS delivery settings is missing mandatory key :#{key}"
          end
        end
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
        I18n.t("two_factor_authentication.text_otp_delivery_message_sms", app_title: Setting.app_title, token:)
      end

      ##
      # Prepares the user's phone number for commcit.
      # Required format: +xxaaabbbccc
      # Stored format: +xx yyy yyy yyyy (optional whitespacing)
      def build_user_phone
        phone = device.phone_number
        phone.gsub!(/\s/, "")

        phone
      end

      # rubocop:disable Metrics/AbcSize
      def submit
        aws_params = configuration_params.slice "region", "access_key_id", "secret_access_key"
        sns = ::Aws::SNS::Client.new aws_params

        sns.set_sms_attributes(
          attributes: {
            # Use transactional message type to ensure timely delivery.
            # Amazon SNS optimizes the message delivery to achieve the highest reliability.
            "DefaultSMSType" => "Transactional",

            # Set sender ID name (may not be supported in all countries)
            "DefaultSenderID" => configuration_params.fetch("sender_id", "OpenProject")
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
      rescue StandardError => e
        Rails.logger.error do
          "[2FA] SNS delivery failed for user #{user.login} (Error: #{e})"
        end

        raise I18n.t("two_factor_authentication.sns.delivery_failed")
      end
      # rubocop:enable Metrics/AbcSize
    end
  end
end
