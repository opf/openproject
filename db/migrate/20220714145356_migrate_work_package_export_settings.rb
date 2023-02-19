class MigrateWorkPackageExportSettings < ActiveRecord::Migration[7.0]
  def up
    execute <<~SQL.squish
      UPDATE settings SET name = 'work_packages_projects_export_limit'
        WHERE name = 'work_packages_export_limit'
    SQL
  end

  def down
    execute <<~SQL.squish
      UPDATE settings SET name = 'work_packages_export_limit'
        WHERE name = 'work_packages_projects_export_limit'
    SQL
  end
end
