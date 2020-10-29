# frozen_string_literal: true

module Grape
  module Exceptions
    class MissingGroupTypeError < Base
      def initialize
        super(message: compose_message(:missing_group_type))
      end
    end
  end
end
