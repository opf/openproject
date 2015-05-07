require 'warden/basic_auth'

module Warden
  module Strategies
    ##
    # Allows users to authenticate using their API key via basic auth.
    # Note that in order for a user to be able to generate one
    # `Setting.rest_api_enabled` has to be `1`.
    #
    # The basic auth credentials are expected to contain the literal 'apikey'
    # as the user name and the API key as the password.
    class UserBasicAuth < BasicAuth
      def self.user
        'apikey'
      end

      def valid?
        super && username == self.class.user
      end

      def authenticate_user(_, api_key)
        token(api_key).try(:user)
      end

      def token(value)
        Token.where(action: 'api', value: value).first
      end
    end
  end
end
