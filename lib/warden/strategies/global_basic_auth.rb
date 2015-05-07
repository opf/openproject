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
        @configuration ||= configuration!
      end

      def self.configuration!
        path = %w(authentication global_basic_auth)
        @configuration = path.inject(OpenProject::Configuration) { |acc, key| Hash(acc[key]) }

        if user == UserBasicAuth.user
          raise ArgumentError, "global user must not be '#{UserBasicAuth.user}'"
        end

        @configuration
      end

      def self.configuration?
        user && password
      end

      def self.user
        configuration['user']
      end

      def self.password
        configuration['password']
      end

      ##
      # Only valid if global basic auth is configured and tried.
      def valid?
        self.class.configuration && super && username == self.class.user
      end

      def authenticate_user(username, password)
        if username == self.class.user && password == self.class.password
          User.system.tap do |user|
            user.admin = true
          end
        end
      end
    end
  end
end
