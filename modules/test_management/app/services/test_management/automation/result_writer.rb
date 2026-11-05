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
    class ResultWriter
      COMMENT_LIMIT = 4000

      def initialize(user:, run:, import:, options:, mapper:, unmatched:)
        @user = user
        @run = run
        @import = import
        @options = options
        @mapper = mapper
        @unmatched = unmatched
        @statuses = Hash.new { |h, k| h[k] = [] }
        @run_cases = {}
      end

      def call(entries)
        matched = 0
        entries.each do |record, cases|
          status = map_status(record)
          next if status.nil?

          written = cases.count { |test_case| write(record, test_case, status) }
          matched += 1 if written.positive?
        end
        finish_cases
        run.update!(state: "in_progress") if run.state == "new" && @run_cases.any?
        matched
      end

      private

      attr_reader :user, :run, :import, :options, :mapper, :unmatched

      def map_status(record)
        mapper.call(record.raw_status)
      rescue KeyError
        unmatched << unmatched_entry(record, "unknown_status")
        nil
      end

      def write(record, test_case, status) # rubocop:disable Metrics/AbcSize
        run_case = run_case_for(test_case)
        unless run_case
          unmatched << unmatched_entry(record, "not_in_run")
          return false
        end

        run_case.results.create!(
          status:,
          comment: comment_for(record, status),
          user:,
          source: "automation",
          duration_ms: record.duration_ms,
          external_id: record.external_id.to_s.first(1024).presence,
          import:,
          iteration_id: import.iteration_id,
          error_message: (record.message unless status == "passed"),
          error_trace: (record.stack unless status == "passed"),
          details: details_for(record)
        )
        @statuses[run_case.id] << status
        true
      end

      def run_case_for(test_case)
        return @run_cases[test_case.id] if @run_cases.key?(test_case.id)

        run_case = run.run_cases.find_by(test_case_id: test_case.id)
        run_case ||= run.run_cases.create!(test_case:, assigned_to_id: run.assigned_to_id, status: "untested")
        @run_cases[test_case.id] = run_case
      end

      def comment_for(record, status)
        return nil if status == "passed"

        text = [record.project_name.presence && "[#{record.project_name}]", record.message].compact.join(" ")
        text.presence&.first(COMMENT_LIMIT)
      end

      def details_for(record)
        {
          "reference" => record.reference, "rawStatus" => record.raw_status, "projectName" => record.project_name,
          "retry" => record.retry, "flaky" => record.flaky, "ciRunUrl" => options.ci["runUrl"]
        }.compact
      end

      def finish_cases
        @run_cases.each_value do |run_case|
          next unless @statuses.key?(run_case.id)

          run_case.update!(status: TestRunCase.worst_status(@statuses[run_case.id]))
        end
      end

      def unmatched_entry(record, reason)
        { "reference" => record.reference, "title" => record.display_title, "file" => record.file,
          "status" => record.raw_status, "projectName" => record.project_name, "reason" => reason }.compact
      end
    end
  end
end
