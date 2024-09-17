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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class ModelReorganization < ActiveRecord::Migration[5.0]
  def self.up
    # Add devices table
    create_table "two_factor_authentication_devices" do |t|
      t.string "type"

      # Whether this is the default strategy
      t.boolean "default", default: false, null: false

      # Whether the device has been fully registered
      t.boolean "active", default: false, null: false

      # Channel the OTP is delivered through
      # (e.g., voice, sms)
      t.string "channel", null: false

      # Phone number for SMS/voice actions
      t.string "phone_number",  null: true

      # User-given identifier for this device
      t.string "identifier", null: false

      # Default rails timestamps
      t.timestamps

      # Last used datetime (relevant for totp)
      t.integer "last_used_at", null: true

      # OTP secret for totp
      t.text "otp_secret", null: true
    end
    add_reference :two_factor_authentication_devices, :user, foreign_key: true, type: :integer

    # Create existing SMS device for data currently in users table
    User.transaction do
      User.find_each do |user|
        phone = user.verified_phone || user.unverified_phone
        next if phone.blank?

        sms = ::TwoFactorAuthentication::Device::Sms.create!(
          user_id: user.id,
          identifier: "Mobile",
          channel: user.default_otp_channel,
          phone_number: phone,
          active: true
        )
        sms.update_column(:default, true)
      end
    end

    change_table "users" do |t|
      t.remove :verified_phone
      t.remove :unverified_phone
      t.remove :default_otp_channel
    end
  end

  def self.down
    change_table "users" do |t|
      t.string :verified_phone
      t.string :unverified_phone
      t.string :default_otp_channel, default: "sms"
    end

    # Write back information from sms devices to table
    User.transaction do
      ::TwoFactorAuthentication::Device::Sms
        .where(active: true)
        .includes(:user)
        .find_each do |device|
        device.user.update_columns(unverified_phone: device.phone_number, default_otp_channel: device.channel)
      end
    end

    drop_table :two_factor_authentication_devices
  end
end
