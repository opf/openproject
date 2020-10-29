# frozen_string_literal: true

module Airbrake
  module Rack
    # Adds HTTP request parameters.
    #
    # @since v5.7.0
    class HttpHeadersFilter
      # @return [Array<String>] the prefixes of the majority of HTTP headers in
      #   Rack (some prefixes match the header names for simplicity)
      HTTP_HEADER_PREFIXES = %w[
        HTTP_
        CONTENT_TYPE
        CONTENT_LENGTH
      ].freeze

      # @return [Integer]
      attr_reader :weight

      def initialize
        @weight = 98
      end

      # @see Airbrake::FilterChain#refine
      def call(notice)
        return unless (request = notice.stash[:rack_request])

        http_headers = request.env.map.with_object({}) do |(key, value), headers|
          if HTTP_HEADER_PREFIXES.any? { |prefix| key.to_s.start_with?(prefix) }
            headers[key] = value
          end

          headers
        end

        notice[:context].merge!(
          httpMethod: request.request_method,
          referer: request.referer,
          headers: http_headers,
        )
      end
    end
  end
end
