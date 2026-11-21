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

module Capybara
  # Collects uncaught browser exceptions from the Cuprite CDP log, so a feature
  # example fails with them once it has run.
  #
  # Ferrum's own `js_errors` option raises them with `Thread.main.raise`, which
  # can interrupt the main thread anywhere, including database rollbacks and
  # request draining during teardown, and leak records into later examples.
  module UncaughtBrowserErrors
    class UncaughtError < StandardError; end

    Record = Data.define(:sequence, :exception_id, :class_name, :message)

    # Known errors from dependencies, each until the linked fix is released.
    IGNORED_MESSAGES = [
      # https://community.openproject.org/wp/DREAM-1065
      /\AInvalidStateError: Failed to execute 'showPopover' on 'HTMLElement': .* during another show operation/
    ].freeze

    LONE_HIGH_SURROGATE = /\\u[dD][89abAB][0-9a-fA-F]{2}(?!\\u[dD][c-fC-F][0-9a-fA-F]{2})/

    module_function

    # Exceptions in the given CDP log entries, without the rejections Chrome
    # revoked because they were handled after all.
    def extract(entries)
      entries.each_with_object([]) do |entry, records|
        data = incoming_message(entry.text)
        case data&.dig("method")
        when "Runtime.exceptionThrown"
          record = record_for(entry.sequence, data.dig("params", "exceptionDetails"))
          records << record if record && !ignored?(record)
        when "Runtime.exceptionRevoked"
          revoked = records.rindex { it.exception_id == data.dig("params", "exceptionId") }
          records.delete_at(revoked) if revoked
        end
      end
    end

    def raise_if_any!(records)
      return if records.empty?

      messages = records.map(&:message).tally.map do |message, count|
        count > 1 ? "#{count}× #{message}" : message
      end

      raise UncaughtError,
            "#{records.size} uncaught JavaScript error(s) in the browser:\n\n#{messages.join("\n\n")}"
    end

    def expected_sequences
      @expected_sequences ||= Set.new
    end

    def unexpected(records)
      records.reject { expected_sequences.include?(it.sequence) }
    end

    def incoming_message(text)
      match = text.match(BrowserLogs::Capture::CDP_INCOMING_MESSAGE_PATTERN)
      return unless match

      parse_json(match[1])
    end

    def parse_json(json)
      JSON.parse(json)
    rescue JSON::ParserError
      begin
        JSON.parse(json.gsub(LONE_HIGH_SURROGATE, "\\ufffd"))
      rescue JSON::ParserError
        nil
      end
    end
    private_class_method :parse_json

    def record_for(sequence, details)
      return unless details

      message = details.dig("exception", "description") || details["text"]
      Record.new(
        sequence:,
        exception_id: details["exceptionId"],
        class_name: details.dig("exception", "className"),
        message: message.to_s.scrub("�")
      )
    end
    private_class_method :record_for

    def ignored?(record)
      IGNORED_MESSAGES.any? { |pattern| pattern.match?(record.message) }
    end
    private_class_method :ignored?

    module Expectations
      # Expects the block to make the browser throw errors matching each pattern,
      # so the example does not fail on those errors. Waits for them like
      # Capybara does. One application error can arrive more than once (the local
      # error reporter rethrows), so every matching error counts as expected.
      def expect_browser_errors(*patterns)
        unless patterns.any? && patterns.all?(Regexp)
          raise ArgumentError, "expect_browser_errors takes one or more Regexps"
        end
        unless Capybara.current_session.driver.is_a?(Capybara::Cuprite::Driver)
          raise ArgumentError, "expect_browser_errors only works with Cuprite"
        end

        cursor = CupriteCdpLogger.logger.cursor
        result = yield
        UncaughtBrowserErrors.expected_sequences.merge(await_browser_errors(patterns, cursor).map(&:sequence))
        result
      end

      private

      def await_browser_errors(patterns, cursor)
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + Capybara.default_max_wait_time

        loop do
          records = UncaughtBrowserErrors.unexpected(UncaughtBrowserErrors.extract(CupriteCdpLogger.logger.since(cursor)))
          missing = patterns.reject { |pattern| records.any? { pattern.match?(it.message) } }
          return records.select { |record| patterns.any? { it.match?(record.message) } } if missing.empty?

          if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
            raise RSpec::Expectations::ExpectationNotMetError,
                  "Expected JavaScript error(s) that did not occur in the browser:\n\n#{missing.map(&:inspect).join("\n")}"
          end

          sleep 0.05
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include Capybara::UncaughtBrowserErrors::Expectations, type: :feature
end
