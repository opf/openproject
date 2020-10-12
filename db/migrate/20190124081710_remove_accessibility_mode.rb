class RemoveAccessibilityMode < ActiveRecord::Migration[5.2]
  def change
    remove_column :user_preferences, :impaired
    delete_accessibility_mode_from_settings
  end

  private

  def delete_accessibility_mode_from_settings
    delete <<-SQL
      DELETE FROM settings
      WHERE name = 'accessibility_mode_for_anonymous'
    SQL
  end
end
