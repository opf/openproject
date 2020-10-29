# frozen_string_literal: true

module Grape
  module Exceptions
    class InvalidVersionHeader < Base
      def initialize(message, headers)
        super(message: compose_message(:invalid_version_header, message: message), status: 406, headers: headers)
      end
    end
  end
end
