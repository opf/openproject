# Register "Cron-like jobs"

Rails.application.configure do |application|
  application.config.to_prepare do
    Cron::CronJob.register! Cron::ClearOldSessionsJob,
                            Cron::ClearTmpCacheJob,
                            Cron::ClearUploadedFilesJob,
                            OAuth::CleanupJob,
                            PaperTrailAudits::CleanupJob,
                            Attachments::CleanupUncontaineredJob,
                            Notifications::ScheduleDateAlertsNotificationsJob,
                            Notifications::ScheduleReminderMailsJob,
                            Ldap::SynchronizationJob
  end
end
