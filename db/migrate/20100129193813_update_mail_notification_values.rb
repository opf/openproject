# Patch the data from a boolean change.
class UpdateMailNotificationValues < ActiveRecord::Migration
  def self.up
    User.update_all("mail_notification = 'all'", "mail_notification = '1'")
    User.update_all("mail_notification = 'only_my_events'", "mail_notification = '0'")
  end

  def self.down
    # No-op
  end
end
