class RemoveSummableSetting < ActiveRecord::Migration[6.0]
  # Do not need a down migration as we simply fall back on the default settings
  def up
    execute <<~SQL
      DELETE FROM settings WHERE name = 'work_package_list_summable_columns'
    SQL
  end
end
