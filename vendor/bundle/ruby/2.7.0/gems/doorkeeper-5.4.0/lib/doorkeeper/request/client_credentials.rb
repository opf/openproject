# frozen_string_literal: true

module Doorkeeper
  module Request
    class ClientCredentials < Strategy
      delegate :client, :parameters, to: :server

      def request
        @request ||= OAuth::ClientCredentialsRequest.new(
          Doorkeeper.config,
          client,
          parameters,
        )
      end
    end
  end
end
