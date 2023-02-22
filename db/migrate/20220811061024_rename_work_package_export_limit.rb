class RenameWorkPackageExportLimit < ActiveRecord::Migration[7.0]
  def up
    if Setting.where(name: 'work_packages_projects_export_limit').exists?
      Setting
        .where(name: 'work_packages_export_limit')
        .delete_all
    else
      Setting
        .where(name: 'work_packages_export_limit')
        .update_all(name: 'work_packages_projects_export_limit')
    end
  end

  def down
    Setting
      .where(name: 'work_packages_projects_export_limit')
      .update_all(name: 'work_packages_export_limit')
  end
end
