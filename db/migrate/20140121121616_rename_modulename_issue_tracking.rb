class RenameModulenameIssueTracking < ActiveRecord::Migration
  def up
    update <<-SQL
      UPDATE enabled_modules
      SET name = 'work_package_tracking'
      WHERE name = 'issue_tracking';
    SQL
  end

  def down
    update <<-SQL
      UPDATE enabled_modules
      SET name = 'issue_tracking'
      WHERE name = 'work_package_tracking';
    SQL
  end
end
