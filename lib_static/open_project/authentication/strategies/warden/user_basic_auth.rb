require 'warden/basic_auth'

module OpenProject
  module Authentication
    module Strategies
      module Warden
        ##
        # Allows users to authenticate using their API key via basic auth.
        # Note that in order for a user to be able to generate one
        # `Setting.rest_api_enabled` has to be `1`.
        #
        # The basic auth credentials are expected to contain the literal 'apikey'
        # as the user name and the API key as the password.
        class UserBasicAuth < ::Warden::Strategies::BasicAuth
          def self.user
            'apikey'
          end

          def valid?
            (
              OpenProject::Configuration.apiv3_enable_basic_auth? &&
              super &&
              username == self.class.user
            )
          end

          def authenticate_user(_, api_key)
            User.find_by_api_key api_key
          end
        end
      end
    end
  end
end
