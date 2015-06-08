module OpenProject
  module OpenIDConnect
    module SSOLogout
      include LobbyBoy::SessionHelper

      def session_expired?
        super || id_token_expired?
      end

      def logout
        if params.include? :script
          logout_user

          return render text: 'bye', status: 200
        end

        # If the user may view the site without being logged in we redirect back to it.
        site_open = !(Setting.login_required? && Concerns::OmniauthLogin.direct_login?)
        return_url = site_open && "#{Setting.protocol}://#{Setting.host_name}"

        if logout_at_op! return_url
          logout_user
        else
          super
        end
      end
    end
  end
end
