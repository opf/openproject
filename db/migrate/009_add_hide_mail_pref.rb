class AddHideMailPref < ActiveRecord::Migration
  def self.up
    add_column :user_preferences, :hide_mail, :boolean, :default => false
  end

  def self.down
    remove_column :user_preferences, :hide_mail
  end
end
