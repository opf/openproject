# frozen_string_literal: true

module Grape
  module Exceptions
    class InvalidResponse < Base
      def initialize
        super(message: compose_message(:invalid_response))
      end
    end
  end
end
