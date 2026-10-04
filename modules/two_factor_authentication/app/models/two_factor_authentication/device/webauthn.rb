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
  class Device::Webauthn < Device
    validates :webauthn_external_id, presence: true, uniqueness: { scope: :user_id }
    validates :webauthn_public_key, presence: true

    # Check allowed channels
    def self.supported_channels
      %i(webauthn)
    end

    def self.device_type
      :webauthn
    end

    # Set default channel
    after_initialize do
      self.channel ||= :webauthn
    end
    validates_inclusion_of :channel, in: supported_channels

    def options_for_create(relying_party)
      @options_for_create ||= relying_party.options_for_registration(
        user: { id: user.webauthn_id, name: user.name },
        exclude: TwoFactorAuthentication::Device::Webauthn.where(user:).pluck(:webauthn_external_id)
      )
    end

    def options_for_get(relying_party)
      @options_for_get ||= relying_party.options_for_authentication(
        allow: [webauthn_external_id] # TODO: Maybe also allow all other tokens? Let's see
      )
    end

    def request_2fa_identifier(_channel)
      identifier
    end

    def input_based?
      false
    end
  end
end
