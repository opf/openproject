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

require "rotp"

module TwoFactorAuthentication
  class Device::Totp < Device
    validates_presence_of :otp_secret

    def self.device_type
      :totp
    end

    # Check allowed channels
    def self.supported_channels
      %i(totp)
    end
    validates_inclusion_of :channel, in: supported_channels

    # Generate Authy/Authenticator compatible secret with rotp
    after_initialize do
      self.otp_secret ||= ::ROTP::Base32.random_base32
      self.channel ||= :totp
    end

    ##
    # verify the given OTP input
    def verify_token(token)
      result = totp.verify(token.to_s, drift_behind: allowed_drift, drift_ahead: allowed_drift, after: last_used_at)

      if result.nil?
        false
      else
        update_column(:last_used_at, result)
        true
      end
    end

    ##
    #
    def account_name
      if user.present?
        user.login
      else
        model_name.human
      end
    end

    ##
    #
    def request_2fa_identifier(_channel)
      identifier
    end

    ##
    # Output the provisioning URL for the user
    # can be generated into a QR for mobile apps.
    def provisioning_url
      totp.provisioning_uri(account_name)
    end

    def allowed_drift
      self.class.manager.configuration["otp_drift_window"] || 60
    end

    def totp
      @totp ||= ::ROTP::TOTP.new otp_secret, issuer: Setting.app_title.presence || "OpenProject"
    end
  end
end
