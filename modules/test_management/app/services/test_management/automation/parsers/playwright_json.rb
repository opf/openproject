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
      class PlaywrightJson
        SEPARATOR = " › "

        def initialize(content)
          @data = Json.load(content)
          unless @data.is_a?(Hash) && @data["suites"].is_a?(Array)
            raise Error.new(:unprocessable,
                            "Not a Playwright JSON report (no 'suites').")
          end
        end

        def records
          @data["suites"].each_with_object([]) { |suite, list| walk(suite, [], suite["file"], list) }
        end

        private

        def walk(suite, path, file, list) # rubocop:disable Metrics/AbcSize
          return unless suite.is_a?(Hash)

          file = suite["file"].presence || file
          titles = file_suite?(suite, path, file) ? path : path + [suite["title"].to_s].compact_blank
          Array(suite["specs"]).each do |spec|
            Array(spec["tests"]).each { |test| list << build(spec, test, titles, file) }
          end
          Array(suite["suites"]).each { |child| walk(child, titles, file, list) }
        end

        def file_suite?(suite, path, file)
          title = suite["title"].to_s
          title.blank? || title == file || (path.empty? && file.present? && file.end_with?(title))
        end

        def build(spec, test, titles, file) # rubocop:disable Metrics/AbcSize
          results = Array(test["results"])
          last = results.last || {}
          title_path = titles + [spec["title"].to_s]
          properties = annotations(test, spec)

          Record.new(
            reference: "#{file}##{title_path.join(SEPARATOR)}",
            title: spec["title"].to_s,
            title_path:,
            file:,
            raw_status: status(test, last),
            flaky: test["status"] == "flaky",
            duration_ms: results.sum { |r| r["duration"].to_i },
            message: Json.clean(error_of(last)&.dig("message")),
            stack: Json.clean(error_of(last)&.dig("stack"), TestResult::ERROR_TRACE_LIMIT),
            tags: Array(spec["tags"]).map(&:to_s),
            properties:,
            project_name: test["projectName"].presence,
            retry: last["retry"].to_i
          ).tap { |record| override_reference(record, properties) }
        end

        def override_reference(record, properties)
          return if properties["tm_ref"].blank?

          record.reference = properties["tm_ref"].first
          record.external_id = [record.reference, record.project_name && "[#{record.project_name}]"].compact.join(" ")
        end

        def status(test, last)
          case test["status"]
          when "skipped" then "skipped"
          when "flaky" then "flaky"
          when "expected" then last["status"] == "skipped" ? "skipped" : "passed"
          else last["status"].presence || "failed"
          end
        end

        def error_of(result)
          result["error"] || Array(result["errors"]).first
        end

        def annotations(test, spec) # rubocop:disable Metrics/AbcSize
          list = Array(test["annotations"]) + Array(spec["annotations"])
          list.each_with_object(Hash.new { |h, k| h[k] = [] }) do |annotation, props|
            next unless annotation.is_a?(Hash) && annotation["type"].present?

            props[annotation["type"].to_s.downcase] << annotation["description"].to_s
          end.to_h
        end
      end
    end
  end
end
