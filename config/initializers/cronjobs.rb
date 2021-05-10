# Register "Cron-like jobs"

OpenProject::Application.configure do |application|
  application.config.to_prepare do
    ::Cron::CronJob.register! ::Cron::ClearOldSessionsJob,
                              ::Cron::ClearTmpCacheJob,
                              ::Cron::ClearUploadedFilesJob,
                              ::OAuth::CleanupJob,
                              ::Attachments::CleanupUncontaineredJob
  end
end
