# frozen_string_literal: true

module Grape
  module Exceptions
    class IncompatibleOptionValues < Base
      def initialize(option1, value1, option2, value2)
        super(message: compose_message(:incompatible_option_values, option1: option1, value1: value1, option2: option2, value2: value2))
      end
    end
  end
end
