# frozen_string_literal: true

module Bim
  module Authentication
    # Standard database authentication using username/password
    class DatabaseAdapter < Adapter
      def authenticate(credentials)
        return nil unless credentials[:username] && credentials[:password]

        User.try_to_login(credentials[:username], credentials[:password])
      end

      def priority
        10 # High priority - try database auth first
      end
    end
  end
end
