class Backup < Export
  class << self
    def permission
      :create_backup
    end

    def include_attachments?
      val = OpenProject::Configuration.backup_include_attachments

      val.nil? ? true : val.to_s.to_bool # default to true
    end

    ##
    # Don't include attachments in archive if they are larger than
    # this value combined.
    def attachment_size_max_sum_mb
      (OpenProject::Configuration.backup_attachment_size_max_sum_mb.presence || 1024).to_i
    end

    def attachments_query
      Attachment
        .not_pending_direct_upload
        .where.not(container_type: nil)
        .where.not(container_type: Export.name)
    end

    def attachments_size_in_mb(attachments_query = self.attachments_query)
      attachments_query.pluck(:filesize).sum / 1024.0 / 1024.0
    end

    def attachments_size_in_bounds?(attachments_query = self.attachments_query, max: attachment_size_max_sum_mb)
      attachments_size_in_mb(attachments_query) <= max
    end
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
