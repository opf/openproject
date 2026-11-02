# frozen_string_literal: true

module TestManagement
  module Automation
    module Parsers
      # Shared limits for reported steps (0020): at most MAX_STEPS steps per test (depth first),
      # MAX_DEPTH levels, capped titles, messages and traces (ANSI color codes removed).
      module Steps
        MAX_STEPS = 200
        MAX_DEPTH = 5
        TITLE_LIMIT = 1000
        MESSAGE_LIMIT = 4000
        TRACE_LIMIT = 8000

        module_function

        # Builds StepRecords from `list` with `build.(item) → attributes hash | nil` and
        # `children.(item) → array`. Stops at the limits.
        def tree(list, build:, children:, depth: 0, budget: [MAX_STEPS])
          return [] if depth >= MAX_DEPTH

          result = []
          Array(list).each do |item|
            break if budget[0] <= 0

            attributes = build.call(item)
            next unless attributes

            budget[0] -= 1
            sub = tree(children.call(item), build:, children:, depth: depth + 1, budget:)
            result << step(**attributes, steps: sub)
          end
          result
        end

        def step(title:, raw_status:, duration_ms: nil, message: nil, stack: nil, attachments: [], steps: [], marker: nil,
                 hook: false)
          StepRecord.new(
            title: title.to_s.gsub(Json::ANSI, "").strip.first(TITLE_LIMIT),
            raw_status: raw_status.to_s,
            duration_ms: duration_ms&.to_i,
            message: Json.clean(message, MESSAGE_LIMIT),
            stack: Json.clean(stack, TRACE_LIMIT),
            attachments:, steps:, marker: marker_value(marker), hook:
          )
        end

        def marker_value(value)
          number = value.to_s[/\A\s*(\d{1,3})\s*\z/, 1]&.to_i
          number if number&.between?(1, StepMarker::MAX)
        end

        # All attachments listed on the steps (they are uploaded with the test's files).
        def attachments_of(steps)
          steps.flat_map { |step| step.each_step.flat_map(&:attachments) }
        end
      end
    end
  end
end
