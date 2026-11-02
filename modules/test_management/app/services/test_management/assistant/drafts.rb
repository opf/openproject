# frozen_string_literal: true

module TestManagement
  module Assistant
    # Turns a model reply (or a submitted draft form) into clean draft hashes:
    #   { "key", "title", "type", "priority", "preconditions", "steps" => [{ "action", "expected_result" }] }
    module Drafts
      MAX_TITLE = 255
      MAX_TEXT = 4000
      MAX_STEPS = 30

      module_function

      # Model reply: {"cases": [...]}, a bare array, or a single case object.
      def from_reply(text, types:, count:)
        parsed = Prompt.extract_json(text)
        list = case parsed
               when Hash then parsed["cases"] || parsed["test_cases"] || (parsed["title"] ? [parsed] : [])
               when Array then parsed
               else []
               end
        normalize_all(Array(list), types:).first(count)
      end

      def normalize_all(list, types: TestManagement::AssistantGeneration::CASE_TYPES)
        seen = Set.new
        list.filter_map.with_index do |raw, index|
          draft = normalize(raw, types:, key: "d#{index + 1}")
          next if draft.nil? || !seen.add?(draft["title"].downcase)

          draft
        end
      end

      def normalize(raw, types: TestManagement::AssistantGeneration::CASE_TYPES, key: nil)
        raw = raw.to_h.stringify_keys if raw.respond_to?(:to_h)
        return nil unless raw.is_a?(Hash)

        title = text(raw["title"] || raw["name"], MAX_TITLE)
        return nil if title.blank?

        type = raw["type"].to_s.downcase.strip
        priority = raw["priority"].to_s.downcase.strip
        {
          "key" => text(raw["key"], 20).presence || key,
          "title" => title,
          "type" => types.include?(type) ? type : nil,
          "priority" => TestManagement::TestCase::PRIORITIES.include?(priority) ? priority : "medium",
          "preconditions" => text(raw["preconditions"], MAX_TEXT),
          "steps" => steps(raw["steps"])
        }
      end

      def steps(raw)
        list = raw.is_a?(Hash) ? raw.sort_by { |k, _| k.to_s.to_i }.map(&:last) : Array(raw)
        list.filter_map do |step|
          step = step.to_h.stringify_keys if step.respond_to?(:to_h) && !step.is_a?(String)
          action, expected = if step.is_a?(Hash)
                               [step["action"] || step["step"],
                                step["expected_result"] || step["expected"]]
                             else
                               [step, nil]
                             end
          action = text(action, MAX_TEXT)
          expected = text(expected, MAX_TEXT)
          next if action.blank? && expected.blank?

          { "action" => action, "expected_result" => expected }
        end.first(MAX_STEPS)
      end

      def text(value, limit)
        return "" unless value.is_a?(String) || value.is_a?(Numeric)

        Prompt.clean(value.to_s).strip.first(limit)
      end
    end
  end
end
