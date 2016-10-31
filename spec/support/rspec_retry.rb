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
end

##
# Allow specific code blocks to retry on specific errors
Retriable.configure do |c|
  # Three tries in that block
  c.tries = 3
end
