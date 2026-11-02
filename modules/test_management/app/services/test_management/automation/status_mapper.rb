# frozen_string_literal: true

module TestManagement
  module Automation
    # Maps reported statuses to run statuses (TestRunCase::STATUSES). Returns nil
    # for a test that should be ignored (skippedAs: "ignore" / statusMap → "ignore")
    # and raises KeyError for an unknown status.
    class StatusMapper
      DEFAULTS = {
        # Playwright / JUnit / generic
        "passed" => "passed", "pass" => "passed", "expected" => "passed", "success" => "passed", "ok" => "passed",
        "failed" => "failed", "fail" => "failed", "failure" => "failed", "unexpected" => "failed",
        "error" => "failed", "broken" => "failed", "timedout" => "failed", "timed_out" => "failed",
        "interrupted" => "blocked", "blocked" => "blocked",
        # Allure "unknown" (no result), Cucumber undefined / ambiguous steps (0020)
        "unknown" => "untested", "undefined" => "failed", "ambiguous" => "failed",
        "retest" => "retest", "in_progress" => "in_progress", "running" => "in_progress",
        "untested" => "untested", "not_run" => "untested", "ready" => "untested",
        # Other common TMS status names
        "settled" => "passed", "untestable" => "skipped",
        # Numeric result ids used by common TMS tools
        "1" => "passed", "2" => "blocked", "3" => "untested", "4" => "retest", "5" => "failed"
      }.freeze
      SKIPPED = %w[skipped skip pending disabled ignored].freeze

      def initialize(skipped_as: "skipped", flaky_as: "passed", status_map: {})
        @skipped_as = skipped_as
        @flaky_as = flaky_as
        @status_map = status_map.transform_keys { |k| k.to_s.downcase }
      end

      def call(raw)
        key = raw.to_s.strip.downcase
        mapped = @status_map[key] ||
                 (SKIPPED.include?(key) && @skipped_as) ||
                 (key == "flaky" && @flaky_as) ||
                 DEFAULTS[key] ||
                 (TestRunCase::STATUSES.include?(key) && key)
        raise KeyError, "unknown status '#{raw}'" unless mapped

        mapped == "ignore" ? nil : mapped
      end
    end
  end
end
