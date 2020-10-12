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
      t.string "identifier",  null: false

      # Default rails timestamps
      t.timestamps

      # Last used datetime (relevant for totp)
      t.integer "last_used_at", null: true

      # OTP secret for totp
      t.text 'otp_secret', null: true
    end
    add_reference :two_factor_authentication_devices, :user, foreign_key: true, type: :integer

    # Create existing SMS device for data currently in users table
    User.transaction do
      User.find_each do |user|
        phone = user.verified_phone || user.unverified_phone
        next unless phone.present?

        sms = ::TwoFactorAuthentication::Device::Sms.create!(
          user_id: user.id,
          identifier: 'Mobile',
          channel: user.default_otp_channel,
          phone_number: phone,
          active: true
        )
        sms.update_column(:default, true)
      end
    end

    change_table 'users' do |t|
      t.remove :verified_phone
      t.remove :unverified_phone
      t.remove :default_otp_channel
    end
  end

  def self.down
    change_table 'users' do |t|
      t.string :verified_phone
      t.string :unverified_phone
      t.string :default_otp_channel, default: 'sms'
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
