# frozen_string_literal: true

module Grape
  module Exceptions
    class UnknownValidator < Base
      def initialize(validator_type)
        super(message: compose_message(:unknown_validator, validator_type: validator_type))
      end
    end
  end
end
