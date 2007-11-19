class AddUserPreferencesTimeZone < ActiveRecord::Migration
  def self.up
    add_column :user_preferences, :time_zone, :string
  end

  def self.down
    remove_column :user_preferences, :time_zone
  end
end
