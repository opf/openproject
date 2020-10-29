# frozen_string_literal: true

module Doorkeeper
  module OAuth
    class TokenRequest
      attr_reader :pre_auth, :resource_owner

      def initialize(pre_auth, resource_owner)
        @pre_auth = pre_auth
        @resource_owner = resource_owner
      end

      def authorize
        auth = Authorization::Token.new(pre_auth, resource_owner)
        auth.issue_token!
        CodeResponse.new(pre_auth, auth, response_on_fragment: true)
      end

      def deny
        pre_auth.error = :access_denied
        pre_auth.error_response
      end
    end
  end
end
