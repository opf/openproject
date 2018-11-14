class ChangeDefaultChannel < ActiveRecord::Migration[5.0]
  def self.up
    change_column_default(:users, :default_otp_channel, 'sms')
    User.where(default_otp_channel: 'text').update_all(default_otp_channel: 'sms')
  end

  def self.down
    change_column_default(:users, :default_otp_channel, 'text')
    User.where(default_otp_channel: 'sms').update_all(default_otp_channel: 'text')
  end
end
