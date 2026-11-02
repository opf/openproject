# frozen_string_literal: true

module TestManagement
  module Automation
    module Parsers
      # The module's own format for any tool:
      # { "tests": [{ "reference": "api/users#creates a user", "caseId": 12, "title": "…",
      #   "status": "passed", "durationMs": 120, "message": "…", "tags": ["@smoke"],
      #   "attachments": [{ "path": "shots/a.png" }],
      #   "steps": [{ "title": "Open the login page", "step": 1, "status": "passed", "durationMs": 80,
      #               "message": "…", "stack": "…", "attachments": [...], "steps": [...] }] }] }
      #   (a bare array works too; "step" is the case step number, like the "[step:1]" title marker)
      class Native
        def initialize(content)
          data = Json.load(content)
          @tests = data.is_a?(Array) ? data : (data.is_a?(Hash) && data["tests"])
          raise Error.new(:unprocessable, "Native report needs a 'tests' array.") unless @tests.is_a?(Array)
        end

        def records
          @tests.each_with_index.map do |test, index|
            raise Error.new(:unprocessable, "tests[#{index}] must be an object.") unless test.is_a?(Hash)

            status = (test["status"] || test["result"]).to_s
            raise Error.new(:unprocessable, "tests[#{index}].status is required.") if status.blank?

            case_ids = Array(test["caseId"] || test["case_id"] || test["caseIds"]).map(&:to_s).compact_blank
            reference = test["reference"].presence || test["ref"].presence
            title = test["title"].to_s
            if reference.blank? && case_ids.empty? && title.blank?
              raise Error.new(:unprocessable,
                              "tests[#{index}] needs a reference, caseId or title.")
            end

            steps = steps_of(test["steps"])
            Record.new(
              reference: reference&.to_s,
              title:,
              title_path: [title].compact_blank,
              file: test["file"]&.to_s,
              raw_status: status,
              duration_ms: test["durationMs"] || test["duration_ms"],
              message: Json.clean(test["message"]),
              stack: Json.clean(test["stack"], Steps::TRACE_LIMIT * 2),
              tags: Array(test["tags"]).map(&:to_s),
              properties: begin
                props = Hash(test["properties"]).transform_keys { |key| key.to_s.downcase }
                props.transform_values { |value| Array(value).map(&:to_s) }
              end,
              project_name: test["projectName"].presence,
              attachments: attachments_of(test["attachments"]) + Steps.attachments_of(steps),
              case_ids:,
              steps:
            ).tap { |record| record.duration_ms = record.duration_ms&.to_i }
          end
        end

        private

        def steps_of(list)
          Steps.tree(
            list,
            build: lambda do |step|
              next unless step.is_a?(Hash) && (step["title"].present? || step["name"].present?)

              { title: step["title"] || step["name"], raw_status: step["status"].presence || "passed",
                duration_ms: step["durationMs"] || step["duration_ms"], message: step["message"], stack: step["stack"],
                marker: step["step"], attachments: attachments_of(step["attachments"]) }
            end,
            children: ->(step) { step.is_a?(Hash) ? step["steps"] : [] }
          )
        end

        def attachments_of(list)
          Array(list).filter_map do |a|
            next unless a.is_a?(Hash) && (a["path"].presence || a["name"].presence)

            { "name" => (a["name"] || File.basename(a["path"].to_s)).to_s, "path" => (a["path"] || a["name"]).to_s,
              "content_type" => a["contentType"].to_s }
          end
        end
      end
    end
  end
end
