# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Capybara::BrowserLogs
  # Capture browser logs on failed examples and output them in Progress and
  # Documentation formatters.
  class Capture
    # Regex matching Ferrum's incoming CDP message format: "  ◀ 0.123 {json}"
    CDP_INCOMING_MESSAGE_PATTERN = /^\s+◀\s+[\d.]+\s+(.+)$/

    class << self
      def after_failed_example(example)
        return if ENV["SKIP_CAPYBARA_BROWSER_LOGS"] == "true"
        return unless failed?(example)
        return unless example.example_group.include?(Capybara::DSL)
        return if Capybara.page.current_url.blank?

        logs = extract_logs
        example.metadata[:browser_logs] = logs if logs
      rescue StandardError => e
        warn "Unable to get browser logs: #{e}"
      end

      private

      def extract_logs
        if cuprite_driver?
          extract_cuprite_logs
        elsif selenium_driver?
          extract_selenium_logs
        end
      end

      def cuprite_driver?
        Capybara.page.driver.is_a?(Capybara::Cuprite::Driver)
      end

      def selenium_driver?
        Capybara.page.driver.browser.respond_to?(:manage)
      end

      def extract_selenium_logs
        Capybara.page.driver.browser.manage.instance_variable_get(:@bridge).log("browser")
      end

      def extract_cuprite_logs
        logger = CupriteCdpLogger.logger
        return unless logger

        logger.string.each_line.filter_map do |line|
          match = line.match(CDP_INCOMING_MESSAGE_PATTERN)
          next unless match

          parse_console_api_called(match[1])
        end
      end

      def parse_console_api_called(json_string)
        data = JSON.parse(json_string)
        return unless data["method"] == "Runtime.consoleAPICalled"

        params = data["params"]
        type = params["type"]
        args = params["args"].map { |arg| format_cdp_arg(arg) }
        "#{type}: #{args.join(' ')}"
      rescue JSON::ParserError
        nil
      end

      def format_cdp_arg(arg)
        return arg["value"].to_s if arg.key?("value")

        if (preview = arg["preview"]) && (properties = preview["properties"])
          formatted = properties.map { |p| "#{p['name']}: #{p['value']}" }.join(", ")
          overflow = preview["overflow"] ? ", ..." : ""
          return "{#{formatted}#{overflow}}"
        end

        arg["description"] || arg["type"]
      end

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
      return if logs.empty?

      output.puts("  Browser logs:\n    #{logs.join("\n    ")}")
    end
  end
end

# Output browser logs after failed feature test
RSpec.configure do |config|
  config.after(type: :feature) do |example|
    Capybara::BrowserLogs::Capture.after_failed_example(example)
    if (logger = CupriteCdpLogger.logger)
      logger.truncate(0)
      logger.rewind
    end
  end

  config.before(:suite) do
    config.add_formatter(Capybara::BrowserLogs::Formatter)
  end
end
