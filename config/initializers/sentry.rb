if OpenProject::Logging::SentryLogger.enabled?
  require "sentry-ruby"
  require "sentry-rails"
  require "sentry-delayed_job"

  # Explicitly require the send event job
  require File.join(Sentry::Engine.root, 'app/jobs/sentry/send_event_job')

  # We need to manually load the sentry initializer
  # as we're dynamically loading it
  # https://github.com/getsentry/sentry-ruby/blob/master/sentry-rails/lib/sentry/rails/railtie.rb#L8-L13
  OpenProject::Application.configure do |app|
    # need to be placed at first to capture as many errors as possible
    app.config.middleware.insert 0, Sentry::Rails::CaptureExceptions
    # need to be placed at last to smuggle app exceptions via env
    app.config.middleware.use(Sentry::Rails::RescuedExceptionInterceptor)
  end

  ##
  # Define the SentryJob here, as sentry gets dynamically loaded
  class SentryJob < Sentry::SendEventJob
    queue_with_priority :low
  end

  Sentry.init do |config|
    config.dsn = OpenProject::Logging::SentryLogger.sentry_dsn
    config.breadcrumbs_logger = [:active_support_logger]

    # Submit events as delayed job
    config.async = lambda { |event, hint| ::SentryJob.perform_later(event, hint) }

    # Cleanup backtrace
    config.backtrace_cleanup_callback = lambda do |backtrace|
      Rails.backtrace_cleaner.clean(backtrace)
    end

    # Sample rate for performance
    # 0.0 = disabled
    # 1.0 = all samples are traced
    config.traces_sample_rate = OpenProject::Configuration.sentry_traces_sample_rate

    # Set release info
    config.release = OpenProject::VERSION.to_s
  end

  # Extend the core log delegator
  handler = ::OpenProject::Logging::SentryLogger.method(:log)
  ::OpenProject::Logging::LogDelegator.register(:sentry, handler)
end
