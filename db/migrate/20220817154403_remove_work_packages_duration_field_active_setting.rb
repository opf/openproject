class RemoveWorkPackagesDurationFieldActiveSetting < ActiveRecord::Migration[7.0]
  def change
    Setting.where(name: 'work_packages_duration_field_active').destroy_all
  end
end
