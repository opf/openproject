# frozen_string_literal: true

module Doorkeeper
  module Request
    class Strategy
      attr_reader :server

      delegate :authorize, to: :request

      def initialize(server)
        @server = server
      end

      def request
        raise NotImplementedError, "request strategies must define #request"
      end
    end
  end
end
