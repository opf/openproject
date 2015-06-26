module OpenProject
  module OpenIDConnect
    module SSOLogin
      include ::LobbyBoy::SessionHelper

      def authorization_successful(_user, auth_hash)
        super.tap do |_|
          confirm_login! # lobby_boy helper
        end
      end
    end
  end
end
