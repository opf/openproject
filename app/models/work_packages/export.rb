class WorkPackages::Export < ApplicationRecord
  self.table_name = 'work_package_exports'

  belongs_to :user

  acts_as_attachable view_permission: :export_work_packages,
                     add_permission: :export_work_packages,
                     delete_permission: :export_work_packages,
                     only_user_allowed: true

  def visible?(user)
    user_id == user.id
  end

  def ready?
    attachments.any?
  end
end
