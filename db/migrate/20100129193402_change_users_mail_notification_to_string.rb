class ChangeUsersMailNotificationToString < ActiveRecord::Migration
  def self.up
    change_column :users, :mail_notification, :string, :default => '', :null => false
  end

  def self.down
    change_column :users, :mail_notification, :boolean, :default => true, :null => false
  end
end
