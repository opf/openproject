class Backup < Export
  def self.permission
    :create_backup
  end

  acts_as_attachable(
    view_permission: permission,
    add_permission: permission,
    delete_permission: permission,
    only_user_allowed: true
  )

  def ready?
    attachments.any?
  end
end
