# frozen_string_literal: true

module TestManagement
  module Automation
    module Parsers
      # Allure results (0020): the `*-result.json` files written by the Allure integrations
      # (Selenide, JUnit/TestNG `@Step` and `Allure.step()`, pytest `allure.step`, Cypress, WebdriverIO,
      # Playwright, Jest, …). Send one result object, an array of them or { "results": [...] },
      # e.g. `jq -s . allure-results/*-result.json`.
      #   { name, fullName, status, statusDetails { message, trace }, start, stop, labels [{ name, value }],
      #     links [{ type, name, url }], parameters, attachments [{ name, source, type }], steps [...] }
      # Steps carry the same fields (nested steps included). Statuses: passed, failed, broken (an
      # exception other than an assertion), skipped, unknown.
      # - reference: label "tm_ref", else fullName, else name; tags: labels "tag";
      # - every label is a property ("tm_case" → case ids), and "tms" links add their names to "tm_case";
      # - a step parameter "tm_step" is an explicit case step number (like the "[step:3]" title marker);
      # - retries (several results with the same testCaseId / historyId / fullName): the latest counts,
      #   reported as "flaky" when an earlier attempt failed and the latest passed.
      class Allure
        RESULT_KEYS = %w[uuid historyId testCaseId fullName].freeze
        FAILED_STATUSES = %w[failed broken].freeze

        def self.result?(item)
          item.is_a?(Hash) && item["status"].is_a?(String) && item["name"].is_a?(String) &&
            RESULT_KEYS.any? { |key| item.key?(key) }
        end

        def self.detect?(data)
          list = data.is_a?(Hash) && data["results"].is_a?(Array) ? data["results"] : data
          list.is_a?(Array) ? list.any? && list.all? { |item| result?(item) } : result?(list)
        end

        def initialize(content)
          data = Json.load(content)
          data = data["results"] if data.is_a?(Hash) && data["results"].is_a?(Array)
          @results = data.is_a?(Array) ? data : [data]
          raise Error.new(:unprocessable, "Not Allure results (objects with 'name' and 'status').") unless @results.all? do |r|
            self.class.result?(r)
          end
        end

        def records
          @results.group_by { |result| identity(result) }.map do |_, attempts|
            ordered = attempts.sort_by { |result| result["stop"].to_i }
            build(ordered.last, ordered[0...-1])
          end
        end

        private

        def identity(result)
          result["testCaseId"].presence || result["historyId"].presence || result["fullName"].presence || result["uuid"] || result.object_id
        end

        def build(result, earlier)
          labels = labels_of(result)
          properties = labels.transform_values { |values| values.map(&:to_s) }
          tms_links = Array(result["links"]).select do |link|
            link.is_a?(Hash) && link["type"].to_s.casecmp?("tms")
          end
          tms = tms_links.filter_map { |link| link["name"].presence }
          properties["tm_case"] = Array(properties["tm_case"]) + tms if tms.any?
          steps = steps_of(result["steps"])
          status = result["status"].to_s
          status = "flaky" if status == "passed" && earlier.any? { |r| FAILED_STATUSES.include?(r["status"]) }

          reference = properties["tm_ref"]&.first.presence || result["fullName"].presence || result["name"]
          Record.new(
            reference: reference.to_s,
            title: result["name"].to_s,
            title_path: [labels["suite"]&.first, result["name"]].compact_blank.map(&:to_s),
            file: (labels["testclass"]&.first || labels["package"]&.first)&.to_s,
            raw_status: status,
            flaky: status == "flaky",
            duration_ms: duration(result),
            message: Json.clean(result.dig("statusDetails", "message")),
            stack: Json.clean(result.dig("statusDetails", "trace"), Steps::TRACE_LIMIT * 2),
            tags: Array(labels["tag"]).map(&:to_s),
            properties:,
            retry: earlier.size,
            attachments: attachments_of(result["attachments"]) + Steps.attachments_of(steps),
            steps:
          )
        end

        def labels_of(item)
          Array(item["labels"]).each_with_object({}) do |label, map|
            next unless label.is_a?(Hash) && label["name"].present?

            (map[label["name"].to_s.downcase] ||= []) << label["value"]
          end
        end

        def steps_of(list)
          Steps.tree(
            list,
            build: lambda do |step|
              next unless step.is_a?(Hash)

              { title: step["name"], raw_status: step["status"].presence || "unknown", duration_ms: duration(step),
                message: step.dig("statusDetails", "message"), stack: step.dig("statusDetails", "trace"),
                marker: parameter(step, "tm_step"), attachments: attachments_of(step["attachments"]) }
            end,
            children: ->(step) { step.is_a?(Hash) ? step["steps"] : [] }
          )
        end

        def parameter(step, name)
          Array(step["parameters"]).find { |p| p.is_a?(Hash) && p["name"].to_s.casecmp?(name) }&.dig("value")
        end

        def duration(item)
          return nil unless item["start"].is_a?(Numeric) && item["stop"].is_a?(Numeric)

          [item["stop"] - item["start"], 0].max.to_i
        end

        def attachments_of(list)
          Array(list).filter_map do |a|
            next unless a.is_a?(Hash) && a["source"].present?

            { "name" => (a["name"].presence || a["source"]).to_s, "path" => a["source"].to_s, "content_type" => a["type"].to_s }
          end
        end
      end
    end
  end
end
