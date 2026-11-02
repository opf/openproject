# frozen_string_literal: true

module TestManagement
  module Automation
    module Parsers
      # Playwright JSON reporter output (`--reporter=json`):
      # { suites: [{ title, file, specs: [{ title, tags, tests: [{ projectName, status,
      #   annotations, results: [{ status, duration, retry, error, attachments }] }] }], suites: [...] }] }
      # One Record per spec × project (browser). The file-level suite title is the
      # file itself and is not repeated in the title path.
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

        def walk(suite, path, file, list)
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

        def build(spec, test, titles, file)
          results = Array(test["results"])
          last = results.last || {}
          title_path = titles + [spec["title"].to_s]
          properties = annotations(test, spec)
          steps = steps_of(last)

          Record.new(
            reference: "#{file}##{title_path.join(SEPARATOR)}",
            title: spec["title"].to_s,
            title_path:,
            file:,
            raw_status: status(test, last),
            flaky: test["status"] == "flaky",
            duration_ms: results.sum { |r| r["duration"].to_i },
            message: Json.clean(error_of(last)&.dig("message")),
            stack: Json.clean(error_of(last)&.dig("stack"), Steps::TRACE_LIMIT * 2),
            tags: Array(spec["tags"]).map(&:to_s),
            properties:,
            project_name: test["projectName"].presence,
            retry: last["retry"].to_i,
            attachments: attachments(results),
            steps:
          ).tap { |record| override_reference(record, properties) }
        end

        # `test.info().annotations.push({ type: "tm_ref", description: "…" })` pins a reference.
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
          else last["status"].presence || "failed" # unexpected: failed / timedOut / interrupted
          end
        end

        # `test.step` steps of the last attempt (the JSON reporter leaves out hooks, fixtures and
        # expect calls). Steps have no status: a step with an error failed, the others passed.
        # Steps after a failure did not run and are not in the report.
        def steps_of(result)
          Steps.tree(
            result["steps"],
            build: lambda do |step|
              next unless step.is_a?(Hash)

              error = step["error"].is_a?(Hash) ? step["error"] : nil
              { title: step["title"], raw_status: error ? "failed" : "passed", duration_ms: step["duration"],
                message: error&.dig("message"), stack: error&.dig("stack") }
            end,
            children: ->(step) { step.is_a?(Hash) ? step["steps"] : [] }
          )
        end

        def error_of(result)
          result["error"] || Array(result["errors"]).first
        end

        def annotations(test, spec)
          list = Array(test["annotations"]) + Array(spec["annotations"])
          list.each_with_object(Hash.new { |h, k| h[k] = [] }) do |annotation, props|
            next unless annotation.is_a?(Hash) && annotation["type"].present?

            props[annotation["type"].to_s.downcase] << annotation["description"].to_s
          end.to_h
        end

        def attachments(results)
          results.flat_map { |r| Array(r["attachments"]) }
                 .select { |a| a.is_a?(Hash) && a["path"].present? }
                 .uniq { |a| a["path"] }
                 .map { |a| { "name" => a["name"].to_s, "path" => a["path"].to_s, "content_type" => a["contentType"].to_s } }
        end
      end
    end
  end
end
