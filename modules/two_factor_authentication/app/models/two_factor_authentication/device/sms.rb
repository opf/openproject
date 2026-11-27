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
  class Device::Sms < Device
    validates_presence_of :phone_number
    validates_uniqueness_of :phone_number, scope: :user_id
    validates_format_of :phone_number, with: /\A(?:\+(?:[0-9][- ]?)+[0-9])?\z/, message: :error_phone_number_format

    # Check allowed channels
    def self.supported_channels
      %i(sms voice)
    end

    def self.device_type
      :sms
    end

    # Set default channel
    after_initialize do
      self.channel ||= :sms
    end

    validates_inclusion_of :channel, in: supported_channels

    def identifier
      value = read_attribute(:identifier)

      if value
        "#{value} (#{phone_number})"
      else
        default_identifier
      end
    end

    def default_identifier
      if phone_number.present?
        "#{name} (#{phone_number})"
      else
        "#{name} (#{user.login})"
      end
    end

    ##
    #
    def request_2fa_identifier(channel)
      channel_name =
        if channel == :sms
          "SMS"
        else
          "Voice"
        end

      I18n.t "two_factor_authentication.devices.sms.request_2fa_identifier",
             redacted_identifier:, delivery_channel: channel_name
    end

    def redacted_identifier
      number = phone_number.dup
      number[1..-3] = "*" * number[1..-3].length
      I18n.t "two_factor_authentication.devices.sms.redacted_identifier",
             redacted_number: number
    end

    def phone_number=(number)
      super(number.try(:strip))
    end
  end
end
