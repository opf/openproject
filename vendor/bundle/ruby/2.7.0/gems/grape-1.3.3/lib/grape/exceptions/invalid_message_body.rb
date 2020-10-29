# frozen_string_literal: true

module Grape
  module Exceptions
    class InvalidMessageBody < Base
      def initialize(body_format)
        super(message: compose_message(:invalid_message_body, body_format: body_format), status: 400)
      end
    end
  end
end
