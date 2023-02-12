require 'rspec/retry'
require 'retriable'

##
# Enable specs to mark metadata retry: <count> to retry that given example
# immediately after it fails.
#
# This DOES NOT retry all specs by default.
RSpec.configure do |config|
  ##
  # Print verbose information on when an example is being retried
  # and print the exception that causes a retry
  config.verbose_retry = true
  config.display_try_failure_messages = true

  ##
  # By default, do not retry specs
  config.default_retry_count = 0

  ##
  # Retry JS feature specs, but not during single runs
  if ENV['CI']
    config.around :each, :js do |ex|
      ex.run_with_retry retry: 2
    end
  end
end

##
# Allow specific code blocks to retry on specific errors
Retriable.configure do |c|
  c.intervals = [1, 1, 2]
end

##
# Helper to pass options to retriable while logging
# failures
def retry_block(args: {}, screenshot: false, &block)
  if ENV["RSPEC_RETRY_RETRY_COUNT"] == "0"
    block.call
    return
  end

  log_errors = Proc.new do |exception, try, elapsed_time, next_interval|
    max_tries = args[:tries] || (RSpec.current_example.metadata[:retry].to_i + 1)
    exception_source_line = exception.backtrace.find { |line| line.start_with?(Rails.root.to_s) }
    next_try_message = next_interval ? "#{next_interval} seconds until the next try" : "last try"
    # use stderr directly to prevent having StructuredWarnings::StandardWarning
    # messy and useless output
    $stderr.puts <<~EOS # rubocop:disable Style/StderrPuts
      -- rspec-retry #{try}/#{max_tries}--
      #{exception.class}: '#{exception.message}'
      occurred on #{exception_source_line}
      #{try} tries in #{elapsed_time} seconds, #{next_try_message}.
      --
    EOS

    if screenshot
      begin
        Capybara::Screenshot.screenshot_and_save_page
      rescue StandardError => e
        warn "Failed to take screenshot in retry_block: #{e} #{e.message}"
      end
    end
  end

  Retriable.retriable(on_retry: log_errors, **args, &block)
end
