# frozen_string_literal: true

module Doorkeeper
  module OAuth
    class ClientCredentialsRequest < BaseRequest
      attr_reader :client, :original_scopes, :response

      alias error_response response

      delegate :error, to: :issuer

      def initialize(server, client, parameters = {})
        @client = client
        @server = server
        @response = nil
        @original_scopes = parameters[:scope]
      end

      def access_token
        issuer.token
      end

      def issuer
        @issuer ||= ClientCredentials::Issuer.new(
          server,
          ClientCredentials::Validator.new(server, self),
        )
      end

      private

      def valid?
        issuer.create(client, scopes)
      end
    end
  end
end
