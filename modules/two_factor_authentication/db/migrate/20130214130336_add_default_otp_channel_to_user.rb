class AddDefaultOtpChannelToUser < ActiveRecord::Migration[5.0]
  def self.up
    add_column :users, :default_otp_channel, :string, :default => 'text'
  end

  def self.down
    remove_column :users, :default_otp_channel
  end
end
