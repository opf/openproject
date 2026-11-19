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

FactoryBot.define do
  factory :two_factor_authentication_device_sms, class: "::TwoFactorAuthentication::Device::Sms" do
    user
    channel { :sms }
    active { true }
    default { true }
    phone_number { "+49 123456789" }
    identifier { "Phone number (+49 123456789)" }

    transient do
      make_default { false }
    end

    callback(:after_create) do |device, evaluator|
      device.make_default! if evaluator.make_default
    end
  end

  factory :two_factor_authentication_device_totp, class: "::TwoFactorAuthentication::Device::Totp" do
    user
    channel { :totp }
    active { true }
    default { true }
    identifier { "TOTP device" }

    transient do
      make_default { false }
    end

    callback(:after_create) do |device, evaluator|
      device.make_default! if evaluator.make_default
    end
  end

  factory :two_factor_authentication_device_webauthn, class: "::TwoFactorAuthentication::Device::Webauthn" do
    user
    channel { :webauthn }
    active { true }
    default { true }
    identifier { "WebAuthn device" }

    webauthn_external_id { "foo" }
    webauthn_public_key { "bar" }

    transient do
      make_default { false }
    end

    callback(:after_create) do |device, evaluator|
      # Ensure user has a webauthn id
      if device.user.webauthn_id.blank?
        device.user.update!(webauthn_id: WebAuthn.generate_user_id)
      end

      # Generate Fake Credential, see https://github.com/cedarcode/webauthn-ruby/blob/master/spec/spec_helper.rb#L26

      device.make_default! if evaluator.make_default
    end
  end
end
