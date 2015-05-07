require 'warden/basic_auth'

module Warden
  module Strategies
    ##
    # Allows authentication via a singular set of basic auth credentials for admin access.
    #
    # The credentials must be configured in `config/configuration.yml` like this:
    #
    #     production:
    #       authentication:
    #         global_basic_auth:
    #           user: admin
    #           password: 123456
    #
    # The strategy will only be triggered when the configured user name is sent.
    # Meaning that this strategy is skipped if a basic auth attempt involving any
    # other user name is made.
    class GlobalBasicAuth < BasicAuth
      def self.configuration
        path = %w(authentication global_basic_auth)
        config = path.inject(OpenProject::Configuration) { |acc, key| Hash(acc[key]) }
        user = config['user']
        password = config['password']

        { user: user, password: password } if user && password
      end

      def self.user
        configuration[:user]
      end

      def self.password
        configuration[:password]
      end

      ##
      # Only valid if global basic auth is configured and tried.
      def valid?
        self.class.configuration && super && username == self.class.user
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
