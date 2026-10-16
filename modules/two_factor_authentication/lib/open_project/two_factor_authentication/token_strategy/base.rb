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

module OpenProject::TwoFactorAuthentication
  module TokenStrategy
    class Base
      attr_reader :user, :device, :token, :channel

      def initialize(user:, device:, channel: nil)
        @channel = channel.presence || device.channel

        unless self.class.supported?(device.channel)
          raise ArgumentError, I18n.t("two_factor_authentication.channel_unavailable", channel: device.channel)
        end

        @user = user
        @device = device
      end

      def verify(input_token, **)
        # Ensure this strategy uses mobile tokens or overrode this method
        raise "Cannot verify mobile token" unless self.class.mobile_token?

        token = user.otp_tokens.find_by_plaintext_value(input_token)

        # Token not found in DB
        raise I18n.t(:notice_account_otp_invalid) if token.nil?
        # Token expired
        raise I18n.t(:notice_account_otp_expired) if token.expired?

        # Delete token immediately
        token.destroy

        true
      end

      def transmit
        if self.class.mobile_token?
          @token = create_mobile_otp
        end

        send :"send_#{channel}"
      end

      def identifier
        self.class.identifier
      end

      def transmit_success_message
        I18n.t("two_factor_authentication.mobile_transmit_notification")
      end

      def self.mobile_token?
        false
      end
      delegate :mobile_token?, to: :class

      def self.supported?(channel)
        supported_channels.include?(channel.to_sym)
      end

      def self.supported_channels
        []
      end

      def self.identifier
        raise SubclassResponsibilityError
      end

      def self.device_type
        :sms
      end

      def self.validate!
        true
      end

      def self.configuration_params
        Setting.plugin_openproject_two_factor_authentication[identifier.to_s]
      end

      protected

      def create_mobile_otp
        value = user.otp_tokens.create_and_return_value(user)
        user.otp_tokens.reload
        value
      end

      def configuration_params
        self.class.configuration_params
      end
    end
  end
end
