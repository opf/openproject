module SentryHelper
  def sentry_frontend_tags
    return '' unless OpenProject::Configuration.sentry_frontend_dsn

    sentry_frontend_dsn_tag + sentry_tracing_meta_tag
  end

  ##
  # Communicate the sentry DSN to the frontend
  # if this instance has enabled JavaScript tracing
  def sentry_frontend_dsn_tag
    tag :meta,
        name: 'openproject_sentry',
        data: {
          dsn: OpenProject::Configuration.sentry_frontend_dsn,
          version: OpenProject::VERSION.to_s,
          tracing_factor: OpenProject::Configuration.sentry_frontend_trace_factor
        }
  end

  ##
  # Meta tag to connect backend request to frontend
  # https://docs.sentry.io/platforms/javascript/performance/connect-services/ %>
  def sentry_tracing_meta_tag
    span_id = current_sentry_tracing_id
    return '' unless span_id

    tag :meta,
        name: 'sentry-trace',
        content: span_id
  end

  ##
  # Get the parent sentry tracing id of the current transaction
  def current_sentry_tracing_id
    Sentry.get_current_scope&.span&.to_sentry_trace
  end
end
