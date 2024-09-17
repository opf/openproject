# frozen_string_literal: true

module Capybara::BrowserLogs
  # Capture browser logs on failed examples and output them in Progress and
  # Documentation formatters.
  class Capture
    class << self
      def after_failed_example(example)
        return unless failed?(example)
        return unless example.example_group.include?(Capybara::DSL)
        return if Capybara.page.current_url.blank?
        return unless Capybara.page.driver.browser.respond_to?(:manage)

        logs = Capybara.page.driver.browser.manage.instance_variable_get(:@bridge).log("browser")
        example.metadata[:browser_logs] = logs
      rescue StandardError => e
        warn "Unable to get browser logs: #{e}"
      end

      private

      # borrowed from capybara-screenshot code
      def failed?(example)
        return true if example.exception
        return false unless defined?(::RSpec::Expectations::FailureAggregator)

        failure_notifier = ::RSpec::Support.failure_notifier
        return false unless failure_notifier.is_a?(::RSpec::Expectations::FailureAggregator)

        failure_notifier.failures.any? || failure_notifier.other_errors.any?
      end
    end
  end

  # Print the captured browser logs to the output
  class Formatter
    RSpec::Core::Formatters.register(
      self,
      :example_failed
    )

    attr_reader :output

    EXCLUDE_PATTERN = /(Angular is running in development mode|\[DEBUG\]|"details:" Object|DEPRECATED)/

    def initialize(output)
      @output = output
    end

    def example_failed(notification)
      output_browser_logs(notification.example)
    end

    private

    def output_browser_logs(example)
      return unless example.metadata[:browser_logs]

      logs = example.metadata[:browser_logs]
        .map(&:to_s)
        .grep_v(EXCLUDE_PATTERN)
      output.puts("  Browser logs:\n    #{logs.join("\n    ")}")
    end
  end
end

# Output browser logs after failed feature test
RSpec.configure do |config|
  config.after(type: :feature) do |example|
    Capybara::BrowserLogs::Capture.after_failed_example(example)
  end

  config.before(:suite) do
    config.add_formatter(Capybara::BrowserLogs::Formatter)
  end
end
