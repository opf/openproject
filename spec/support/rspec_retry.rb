# frozen_string_literal: true

require "rspec/retry"
require "retriable"

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
  if ENV["CI"]
    config.around :each, :js do |ex|
      ex.run_with_retry retry: ENV["RSPEC_RETRY_RETRY_COUNT"].to_i
    end
  end
end

##
# Allow specific code blocks to retry on specific errors
Retriable.configure do |c|
  # Setting intervals overrides `tries`, `base_interval`, `max_interval`,
  # `rand_factor`, and `multiplier` parameters and thus ruins the benefit of
  # calling `retry_block` with `args: { tries: _ }` argument.
  #
  # Prefer setting `base_interval`, `max_interval`, `rand_factor`, and
  # `multiplier` instead to keep the benefit of `args: { tries: _ }` argument.
  #
  # This will generate the following intervals: [0.5, 0.75, 1.125, ~1.7, ~2.5, ~3.8, ...]
  c.base_interval = 0.5
  c.multiplier = 1.5
  c.rand_factor = 0.0
end

##
# Helper to pass options to retriable while logging
# failures
def retry_block(args: {}, screenshot: false, &)
  if ENV["RSPEC_RETRY_RETRY_COUNT"] == "0"
    yield
    return
  end

  log_errors = Proc.new do |exception, try, elapsed_time, next_interval|
    max_tries = args[:tries] || Retriable.config.tries
    exception_source_lines = backtrace_up_to_spec_file(exception)
    next_try_message = next_interval ? "waiting #{next_interval} seconds until the next try" : "it was the last try"
    # use stderr directly to prevent having StructuredWarnings::StandardWarning
    # messy and useless output
    $stderr.puts <<~MSG # rubocop:disable Style/StderrPuts
      -- rspec-retry: failed try #{try} of #{max_tries} max --
      #{exception.class}: '#{exception.message}'
      occurred on #{exception_source_lines.first}
      backtrace:
      #{exception_source_lines.map { "  #{it}" }.join("\n")}
      ran #{try} #{'try'.pluralize(try)} in #{elapsed_time} seconds, #{next_try_message}.
      --
    MSG

    if screenshot
      begin
        Capybara::Screenshot.screenshot_and_save_page
      rescue StandardError => e
        warn "Failed to take screenshot in retry_block: #{e} #{e.message}"
      end
    end
  end

  # By default retry_block works with StandardError, but the ExpectationNotMetError is
  # not inherited from StandardError. Adding the RSpec::Expectations::ExpectationNotMetError
  # will makes sure we retry if an expectation fails inside the retry_block.
  args[:on] ||= [StandardError, RSpec::Expectations::ExpectationNotMetError]

  Retriable.retriable(on_retry: log_errors, **args, &)
end

def backtrace_up_to_spec_file(exception)
  exception.backtrace
    .filter { |line| line.start_with?(Rails.root.to_s) }
    .grep_v(%r[/spec/support/shared/with_(mail|direct_uploads)])
    .grep_v(%r[#{Rails.root.join('bin')}])
end
