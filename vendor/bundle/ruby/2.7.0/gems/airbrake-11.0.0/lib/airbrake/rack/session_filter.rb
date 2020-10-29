# frozen_string_literal: true

module Airbrake
  module Rack
    # Adds HTTP session.
    #
    # @since v5.7.0
    class SessionFilter
      # @return [Integer]
      attr_reader :weight

      def initialize
        @weight = 96
      end

      # @see Airbrake::FilterChain#refine
      def call(notice)
        return unless (request = notice.stash[:rack_request])

        session = request.session
        notice[:session] = session if session
      end
    end
  end
end
