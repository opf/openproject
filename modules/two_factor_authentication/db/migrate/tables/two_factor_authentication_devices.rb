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

require Rails.root.join("db/migrate/tables/base").to_s

class Tables::TwoFactorAuthenticationDevices < Tables::Base
  def self.table(migration)
    create_table migration do |t|
      t.string :type

      # Whether this is the default strategy
      t.boolean :default, default: false, null: false

      # Whether the device has been fully registered
      t.boolean :active, default: false, null: false

      # Channel the OTP is delivered through
      # (e.g., voice, sms)
      t.string :channel, null: false

      # Phone number for SMS/voice actions
      t.string :phone_number, null: true

      # User-given identifier for this device
      t.string :identifier, null: false

      # Default rails timestamps
      t.timestamps precision: false

      # Last used datetime (relevant for totp)
      t.integer :last_used_at, null: true

      # OTP secret for totp
      t.text :otp_secret, null: true

      t.references :user, foreign_key: true

      t.string :webauthn_external_id,
               null: true,
               index: { unique: true, name: "index_two_factor_authentication_devices_on_webauthn_external_id" }

      t.string :webauthn_public_key, null: true
      t.bigint :webauthn_sign_count, null: false, default: 0
    end
  end
end
