class AddMembersMailNotification < ActiveRecord::Migration
  def self.up
    add_column :members, :mail_notification, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :members, :mail_notification
  end
end
