class AddAddWorkPackageAttachmentPermissionToCommenters < ActiveRecord::Migration[7.0]
  def up
    WorkPackageRole.find_by(builtin: Role::BUILTIN_WORK_PACKAGE_COMMENTER).add_permission! :add_work_package_attachments
  end

  def down
    WorkPackageRole.find_by(builtin: Role::BUILTIN_WORK_PACKAGE_COMMENTER).remove_permission! :add_work_package_attachments
  end
end
