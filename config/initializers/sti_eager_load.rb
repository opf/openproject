
unless Rails.application.config.eager_load
  Rails.application.config.to_prepare do
    # Enumerations
    IssuePriority
    TimeEntryActivity
    DocumentCategory
  end
end
