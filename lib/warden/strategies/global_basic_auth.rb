require 'warden/basic_auth'

module Warden
  module Strategies
    class GlobalBasicAuth < BasicAuth
      def self.configuration
        config = Hash(OpenProject::Configuration['authentication'])

        user = config.fetch? 'global_basic_auth', 'user'
        password = config.fetch? 'global_basic_auth', 'password'

        { user: user, password: password } if user && password
      end

      ##
      # Only valid if global basic auth is configured.
      def valid?
        self.class.configuration && super
      end

      def authenticate_user(username, password)
        config = self.class.configuration

        if username == config[:user] && password == config[:password]
          User.system.tap do |user|
            user.admin = true
          end
        end
      end
    end
  end
end
