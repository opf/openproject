# frozen_string_literal: true

module TestManagement
  module Automation
    # Raised by the ingest pipeline; `code` maps to an HTTP status in the API layer:
    # :bad_request (400), :forbidden (403), :not_found (404), :conflict (409),
    # :payload_too_large (413), :unprocessable (422).
    class Error < StandardError
      CODES = %i[bad_request forbidden not_found conflict payload_too_large unprocessable].freeze

      attr_reader :code

      def initialize(code, message = nil)
        raise ArgumentError, "unknown code #{code}" unless CODES.include?(code)

        @code = code
        super(message || code.to_s.humanize)
      end
    end
  end
end
