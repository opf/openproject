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

module TestManagement
  module Automation
    # Maps reported statuses to run statuses (TestRunCase::STATUSES). Returns nil
    # for a test that should be ignored (skippedAs: "ignore" / statusMap → "ignore")
    # and raises KeyError for an unknown status.
    class StatusMapper
      DEFAULTS = {
        "passed" => "passed", "pass" => "passed", "expected" => "passed", "success" => "passed", "ok" => "passed",
        "failed" => "failed", "fail" => "failed", "failure" => "failed", "unexpected" => "failed",
        "error" => "failed", "broken" => "failed", "timedout" => "failed", "timed_out" => "failed",
        "interrupted" => "blocked", "blocked" => "blocked",
        "retest" => "retest", "in_progress" => "in_progress", "running" => "in_progress",
        "untested" => "untested", "not_run" => "untested", "ready" => "untested",
        "settled" => "passed", "untestable" => "skipped"
      }.freeze
      SKIPPED = %w[skipped skip pending disabled ignored].freeze

      def initialize(skipped_as: "skipped", flaky_as: "passed", status_map: {})
        @skipped_as = skipped_as
        @flaky_as = flaky_as
        @status_map = status_map.transform_keys { |k| k.to_s.downcase }
      end

      def call(raw) # rubocop:disable Metrics/PerceivedComplexity
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
