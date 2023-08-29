module BackupPreviewHelper
  def backup_preview?
    cookies.signed[:backup_preview].present?
  end

  def backup_preview
    @backup_preview ||= load_backup_preview_yaml cookies.signed[:backup_preview]
  end

  def load_backup_preview_yaml(yaml)
    YAML.safe_load yaml, permitted_classes: [Symbol, Time, ActiveSupport::TimeWithZone, ActiveSupport::TimeZone], aliases: true
  end
end
