class WorkPackages::Export < ApplicationRecord
  self.table_name = 'work_package_exports'

  acts_as_attachable view_permission: :export_work_packages,
                     add_permission: :export_work_packages,
                     delete_permission: :export_work_packages,
                     only_user_allowed: true

  def ready?
    attachments.any?
  end
end
