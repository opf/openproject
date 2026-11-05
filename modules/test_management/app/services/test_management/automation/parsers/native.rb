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
    module Parsers
      class Native
        def initialize(content)
          data = Json.load(content)
          @tests = data.is_a?(Array) ? data : (data.is_a?(Hash) && data["tests"])
          raise Error.new(:unprocessable, "Native report needs a 'tests' array.") unless @tests.is_a?(Array)
        end

        def records # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
          @tests.each_with_index.map do |test, index|
            raise Error.new(:unprocessable, "tests[#{index}] must be an object.") unless test.is_a?(Hash)

            status = (test["status"] || test["result"]).to_s
            raise Error.new(:unprocessable, "tests[#{index}].status is required.") if status.blank?

            case_ids = Array(test["caseId"] || test["case_id"] || test["caseIds"]).map(&:to_s).compact_blank
            reference = test["reference"].presence || test["ref"].presence
            title = test["title"].to_s
            if reference.blank? && case_ids.empty? && title.blank?
              raise Error.new(:unprocessable, "tests[#{index}] needs a reference, caseId or title.")
            end

            Record.new(
              reference: reference&.to_s,
              title:,
              title_path: [title].compact_blank,
              file: test["file"]&.to_s,
              raw_status: status,
              duration_ms: (test["durationMs"] || test["duration_ms"])&.to_i,
              message: Json.clean(test["message"]),
              stack: Json.clean(test["stack"], TestResult::ERROR_TRACE_LIMIT),
              tags: Array(test["tags"]).map(&:to_s),
              project_name: test["projectName"].presence,
              case_ids:
            )
          end
        end
      end
    end
  end
end
