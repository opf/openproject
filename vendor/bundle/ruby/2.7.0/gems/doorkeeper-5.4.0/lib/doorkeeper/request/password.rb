# frozen_string_literal: true

module Doorkeeper
  module Request
    class Password < Strategy
      delegate :credentials, :resource_owner, :parameters, :client, to: :server

      def request
        @request ||= OAuth::PasswordAccessTokenRequest.new(
          Doorkeeper.config,
          client,
          resource_owner,
          parameters,
        )
      end
    end
  end
end
