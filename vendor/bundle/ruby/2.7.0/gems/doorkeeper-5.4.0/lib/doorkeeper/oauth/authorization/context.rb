# frozen_string_literal: true

module Doorkeeper
  module OAuth
    module Authorization
      class Context
        attr_reader :client, :grant_type, :scopes

        def initialize(client, grant_type, scopes)
          @client = client
          @grant_type = grant_type
          @scopes = scopes
        end
      end
    end
  end
end
