# frozen_string_literal: true

require "json"

module TestManagement
  module Automation
    module Parsers
      module Json
        ANSI = /\e\[[\d;]*m/

        module_function

        def load(content)
          JSON.parse(content, max_nesting: 200)
        rescue JSON::ParserError => e
          raise Error.new(:bad_request, "The report is not valid JSON: #{e.message.to_s.first(200)}")
        end

        def clean(text, limit = 4000)
          return nil if text.blank?

          text.to_s.gsub(ANSI, "").strip.first(limit)
        end
      end
    end
  end
end
