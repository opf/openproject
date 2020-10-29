# frozen_string_literal: true

module Grape
  module Exceptions
    class InvalidVersionerOption < Base
      def initialize(strategy)
        super(message: compose_message(:invalid_versioner_option, strategy: strategy))
      end
    end
  end
end
