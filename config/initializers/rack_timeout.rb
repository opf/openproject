# Use rack-timeout if we run in clustered mode with at least 2 workers
# so that workers, should a timeout occur, can be restarted without interruption.
if OpenProject::Configuration.web_workers >= 2
  service_timeout = OpenProject::Configuration.web_timeout
  wait_timeout = OpenProject::Configuration.web_wait_timeout

  Rails.logger.debug { "Enabling Rack::Timeout (service=#{service_timeout}s wait=#{wait_timeout}s)" }

  Rails.application.config.middleware.insert_before(
    Rack::Runtime,
    Rack::Timeout,
    service_timeout:, # time after which a request being served times out
    wait_timeout:, # time after which a request waiting to be served times out
    term_on_timeout: 1, # shut down worker (gracefully) right away on timeout to be restarted
    service_past_wait: true # Treat the service timeout as independent from the wait timeout
  )

  Rails.application.config.after_initialize do
    # remove default logger (logging uninteresting extra info with each not timed out request)
    Rack::Timeout.unregister_state_change_observer(:logger)

    Rack::Timeout.register_state_change_observer(:wait_timeout_logger) do |env|
      details = env[Rack::Timeout::ENV_INFO_KEY]

      if details.state == :timed_out && details.wait.present?
        OpenProject.logger.error "Request timed out waiting to be served!"
      end
    end

    # The timeout itself is already reported so no need to
    # report the generic internal server error too as it doesn't
    # add any more information. Even worse, it's not immediately
    # clear that the two reports are related.
    require "rack/timeout/suppress_internal_error_report_on_timeout"

    OpenProjectErrorHelper.prepend Rack::Timeout::SuppressInternalErrorReportOnTimeout
  end
else
  Rails.logger.debug { "Not enabling Rack::Timeout since we are not running in cluster mode with at least 2 workers" }
end
