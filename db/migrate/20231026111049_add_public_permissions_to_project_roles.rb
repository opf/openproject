class AddPublicPermissionsToProjectRoles < ActiveRecord::Migration[7.0]
  def up
    ProjectRole.find_each do |role|
      role.add_permission! *OpenProject::AccessControl.public_permissions.map(&:name)
    end
  end

  def down
    ProjectRole.find_each do |role|
      role.remove_permission! *OpenProject::AccessControl.public_permissions.map(&:name)
    end
  end
end
