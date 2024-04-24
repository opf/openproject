class Projects::Export < Export
  acts_as_attachable view_permission: :view_project,
                     add_permission: :view_project,
                     delete_permission: :view_project,
                     allow_uncontainered: false,
                     only_user_allowed: true

  def ready?
    attachments.any?
  end
end
