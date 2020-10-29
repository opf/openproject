# frozen_string_literal: true

module Airbrake
  module Rack
    # Adds current user information.
    #
    # @since v8.0.1
    class UserFilter
      # @return [Integer]
      attr_reader :weight

      def initialize
        @weight = 99
      end

      # @see Airbrake::FilterChain#refine
      def call(notice)
        return unless (request = notice.stash[:rack_request])

        user = Airbrake::Rack::User.extract(request.env)
        notice[:context].merge!(user.as_json) if user
      end
    end
  end
end
