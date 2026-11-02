# frozen_string_literal: true

module TestManagement
  module Automation
    # The explicit case step reference in a reported step title (0020):
    #   "[step:3] Submit the form"   – preferred, any framework (also "[step 3]", "[Step:3]")
    #   "@S3 Submit the form"        – short form, e.g. for tag-like naming
    # The number is the 1-based position of the case step, as shown on the case page.
    # The marker is removed from the title that is stored and shown.
    module StepMarker
      MAX = 999
      PATTERNS = [/\[\s*step\s*[:#]?\s*(\d{1,3})\s*\]/i, /(?<![\w@])@S(\d{1,3})\b/].freeze

      module_function

      def position_in(title)
        PATTERNS.each do |pattern|
          number = title.to_s[pattern, 1]&.to_i
          return number if number&.between?(1, MAX)
        end
        nil
      end

      def strip(title)
        return title if title.nil?

        PATTERNS.reduce(title.to_s) { |text, pattern| text.gsub(pattern, " ") }.squeeze(" ").strip
      end
    end
  end
end
