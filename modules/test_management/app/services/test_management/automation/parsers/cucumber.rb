# frozen_string_literal: true

module TestManagement
  module Automation
    module Parsers
      # Shared by the Cucumber JSON and Cucumber messages parsers (0020).
      module Cucumber
        # "@tm_case:12" / "@tm_ref:checkout#pays" tags become properties, like Playwright annotations.
        TAG_PROPERTY = /\A@(tm_case|tm_ref|test_id|case_id):(.+)\z/i

        module_function

        def tag_properties(tags)
          tags.each_with_object({}) do |tag, props|
            match = tag.to_s.match(TAG_PROPERTY)
            (props[match[1].downcase] ||= []) << match[2] if match
          end
        end

        # Scenario status from its step statuses: failed > undefined/ambiguous (failed) > pending/skipped.
        def scenario_status(statuses)
          statuses = statuses.map { |s| s.to_s.downcase }
          return "failed" if statuses.intersect?(%w[failed undefined ambiguous])
          return "skipped" if statuses.any? && statuses.all? { |s| %w[skipped pending].include?(s) }
          return "pending" if statuses.include?("pending")
          return "passed" if statuses.include?("passed")

          statuses.empty? ? "skipped" : "unknown"
        end
      end
    end
  end
end
