# Patch the data from a boolean change.
class UpdateMailNotificationValues < ActiveRecord::Migration
  def self.up
    # No-op
    # See 20100129193402_change_users_mail_notification_to_string.rb
  end

  def self.down
    # No-op
  end
end
