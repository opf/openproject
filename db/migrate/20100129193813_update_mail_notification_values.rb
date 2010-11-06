# Patch the data from a boolean change.
class UpdateMailNotificationValues < ActiveRecord::Migration
  def self.up
    User.update_all("mail_notification = 'all'", "mail_notification IN ('1', 't')")
    User.update_all("mail_notification = 'selected'", "EXISTS (SELECT 1 FROM #{Member.table_name} WHERE #{Member.table_name}.mail_notification = #{connection.quoted_true} AND #{Member.table_name}.user_id = #{User.table_name}.id)")
    User.update_all("mail_notification = 'only_my_events'", "mail_notification NOT IN ('all', 'selected')")
  end

  def self.down
    # No-op
  end
end
