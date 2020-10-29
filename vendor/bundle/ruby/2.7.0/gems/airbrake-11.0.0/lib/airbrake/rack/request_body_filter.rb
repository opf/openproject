# frozen_string_literal: true

module Airbrake
  module Rack
    # A filter that appends Rack request body to the notice.
    #
    # @example
    #   # Read and append up to 512 bytes from Rack request's body.
    #   Airbrake.add_filter(Airbrake::Rack::RequestBodyFilter.new(512))
    #
    # @since v5.7.0
    # @note This filter is *not* used by default.
    class RequestBodyFilter
      # @return [Integer]
      attr_reader :weight

      # @param [Integer] length The maximum number of bytes to read
      def initialize(length = 4096)
        @length = length
        @weight = 95
      end

      # @see Airbrake::FilterChain#refine
      def call(notice)
        return unless (request = notice.stash[:rack_request])
        return unless request.body

        notice[:environment][:body] = request.body.read(@length)
        request.body.rewind
      end
    end
  end
end
