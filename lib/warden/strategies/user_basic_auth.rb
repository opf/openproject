require 'warden/basic_auth'

module Warden
  module Strategies
    class UserBasicAuth < BasicAuth
      def authenticate_user(username, password)
        user = User.find_by_login username

        user if user && user.check_password?(password)
      end
    end
  end
end
