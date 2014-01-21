class RenameModulenameIssueTracking < ActiveRecord::Migration
  def up
    update <<-SQL
      UPDATE enabled_modules
      SET name = 'work_package_tracking'
      WHERE name = 'issue_tracking';
    SQL
  end

  def down
  end
end
