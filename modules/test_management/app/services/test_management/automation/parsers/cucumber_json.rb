# frozen_string_literal: true

module TestManagement
  module Automation
    module Parsers
      # Cucumber JSON (the `json` formatter of Cucumber-JVM, cucumber-js, Cucumber-Ruby) (0020):
      # [{ uri, name, elements: [{ type: "background" | "scenario", name, tags: [{ name }],
      #    before: [hook], steps: [{ keyword, name, result: { status, duration (ns), error_message } }],
      #    after: [hook] }] }]
      # One Record per scenario (outline examples are separate scenarios); background steps are put in
      # front of the following scenario's steps. Reference "<uri>#<feature> › <scenario>" (as for
      # Cucumber messages). Step titles are "<keyword> <text>" ("Given I open the login page").
      # Failed hooks are kept as reported steps; passed hooks are left out. Inline embeddings are not
      # imported (upload screenshots as attachments instead).
      class CucumberJson
        NS_PER_MS = 1_000_000

        def self.detect?(data)
          data.is_a?(Array) && data.any? &&
            data.all? do |feature|
              feature.is_a?(Hash) && feature["elements"].is_a?(Array) && (feature.key?("uri") || feature["keyword"].present?)
            end
        end

        def initialize(content)
          @features = Json.load(content)
          unless self.class.detect?(@features)
            raise Error.new(:unprocessable,
                            "Not a Cucumber JSON report (an array of features with 'elements').")
          end
        end

        def records
          @features.flat_map do |feature|
            background = []
            feature["elements"].filter_map do |element|
              next unless element.is_a?(Hash)

              if element["type"].to_s == "background"
                background = Array(element["steps"])
                next
              end
              build(feature, element, background)
            end
          end
        end

        private

        def build(feature, element, background)
          raw_steps = Array(element["before"]).map { |h| [h, true] } + (background + Array(element["steps"])).map do |s|
            [s, false]
          end +
                      Array(element["after"]).map { |h| [h, true] }
          steps = Steps.tree(raw_steps, build: method(:step_attributes), children: ->(_) { [] })
          failed = steps.find { |step| step.raw_status == "failed" } ||
                   steps.find { |step| %w[undefined ambiguous].include?(step.raw_status) }
          tags = Array(element["tags"]).filter_map { |tag| tag.is_a?(Hash) ? tag["name"].to_s : tag.to_s }.compact_blank
          title_path = [feature["name"].to_s, element["name"].to_s].compact_blank

          Record.new(
            reference: "#{feature['uri']}##{title_path.join(PlaywrightJson::SEPARATOR)}",
            title: element["name"].to_s,
            title_path:,
            file: feature["uri"]&.to_s,
            raw_status: scenario_status(steps),
            duration_ms: steps.sum { |step| step.duration_ms.to_i },
            message: failed&.message&.then { |msg| msg.lines.first&.strip },
            stack: Json.clean(failed&.message || failed&.stack, Steps::TRACE_LIMIT * 2),
            tags:,
            properties: Cucumber.tag_properties(tags),
            steps: steps.reject { |step| step.hook && step.raw_status == "passed" }
          )
        end

        def step_attributes((step, hook))
          return unless step.is_a?(Hash)

          result = step["result"].is_a?(Hash) ? step["result"] : {}
          title = if hook
                    step.dig("match",
                             "location").presence || "Hook"
                  else
                    "#{step['keyword'].to_s.strip} #{step['name']}".strip
                  end
          { title:, raw_status: result["status"].presence || "unknown", duration_ms: result["duration"].to_i / NS_PER_MS,
            message: result["error_message"], stack: result["error_message"], hook: }
        end

        def scenario_status(steps)
          Cucumber.scenario_status(steps.map(&:raw_status))
        end
      end
    end
  end
end
