class AddTimestampsToUserPreferences < ActiveRecord::Migration[7.1]
  def change
    add_timestamps :user_preferences, default: DateTime.now
  end
end
