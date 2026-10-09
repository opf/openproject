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

module TwoFactorAuthentication
  class TokenService
    attr_reader :user, :device, :strategy, :channel

    ##
    # Create a token service for the given user.
    def initialize(user:, use_device: nil, use_channel: nil)
      @user = user
      @device = use_device || user.otp_devices.get_default
      @channel = use_channel || device.try(:channel)

      matching_strategy = get_matching_strategy
      if matching_strategy
        @strategy = matching_strategy.new(user: @user, device: @device, channel: @channel)
      end
    end

    ##
    # Determines whether a token should be entered by the user.
    def requires_token?
      # If 2FA is enforced, always required
      return true if manager.enforced?

      # Otherwise, only enabled if active and a device is present for the user
      manager.enabled? && device.present?
    end

    ##
    # Determines whether the given user needs to register a
    # device during the login flow.
    def needs_registration?
      return false unless manager.enforced?

      device.nil?
    end

    ##
    # Request a token through the active strategy
    # IF the instance is set up to have optional 2FA
    def request
      # Validate that we can request the token for this user
      # and get the matching strategy we will use
      verify_device_and_strategy

      # Produce the token with the given strategy (e.g., sending an sms)
      strategy.transmit

      ServiceResult.success(result: strategy.transmit_success_message)
    rescue StandardError => e
      Rails.logger.error "[2FA plugin] Error during token request to user##{user.id}: #{e}"

      result = ServiceResult.failure
      result.errors.add(:base, e.message)

      result
    end

    ##
    # Validate a token that was input by the user
    def verify(input, **)
      # Validate that we can request the token for this user
      # and get the matching strategy we will use
      verify_device_and_strategy

      # Produce the token with the given strategy (e.g., sending an sms)
      result = strategy.verify(input, **)

      ServiceResult.new(success: result)
    rescue StandardError => e
      Rails.logger.error "[2FA plugin] Error during token validation for user##{user.id}: #{e.class} #{e}"

      result = ServiceResult.failure
      result.errors.add(:base, e.message)

      result
    end

    private

    ##
    # Get the matching strategy from the desired channel, if set.
    def get_matching_strategy
      if @channel
        manager.find_matching_strategy(@channel)
      end
    end

    ##
    # Perform service checks for the request and validate endpoints of this service
    def verify_device_and_strategy
      raise I18n.t("two_factor_authentication.error_2fa_disabled") unless manager.enabled?

      # Ensure the user's default device for OTP exists
      raise I18n.t("two_factor_authentication.error_no_device") if device.nil?

      # Ensure a matching registered strategy for the device's channel exists
      raise I18n.t("two_factor_authentication.error_no_matching_strategy") if strategy.nil?
    end

    def manager
      ::OpenProject::TwoFactorAuthentication::TokenStrategyManager
    end
  end
end
