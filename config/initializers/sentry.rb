if OpenProject::Logging::SentryLogger.enabled?
  require "sentry-ruby"
  require "sentry-rails"
  require "sentry-delayed_job"

  Sentry.init do |config|
    config.dsn = OpenProject::Logging::SentryLogger.sentry_dsn
    config.breadcrumbs_logger = [:active_support_logger]

    # Submit events as delayed job
    # TODO perform_later
    config.async = lambda { |event, hint| ::SentryJob.perform_now(event, hint) }

    # Cleanup backtrace
    config.backtrace_cleanup_callback = lambda do |backtrace|
      Rails.backtrace_cleaner.clean(backtrace)
    end

    # Set release info
    config.release = OpenProject::VERSION.to_s
  end

  # Extend the core log delegator
  handler = ::OpenProject::Logging::SentryLogger.method(:log)
  ::OpenProject::Logging::LogDelegator.register(:sentry, handler)
end
