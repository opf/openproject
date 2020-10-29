module LobbyBoy
  module SessionHelper
    ##
    # Call in host rails controller to confirm that the user was logged in.
    def confirm_login!
      if LobbyBoy.configured?
        session['lobby_boy.id_token'] = env['lobby_boy.id_token'].jwt_token
        cookies[:oidc_rp_state] = env['lobby_boy.cookie']
      end
    end

    def finish_reauthentication!
      redirect_to(lobby_boy_path + 'session/state')
    end

    def reauthentication?
      env['omniauth.origin'] == '/session/state'
    end

    def finish_logout!
      redirect_to(lobby_boy_path + 'session/state?state=logout')
    end

    def id_token_expired?
      id_token && id_token.expires_in == 0
    end

    def id_token
      token = session['lobby_boy.id_token']
      ::LobbyBoy::OpenIDConnect::IdToken.new token if token
    end

    def logout_at_op!(return_url = nil)
      return false unless LobbyBoy.configured?

      id_token_hint = id_token && id_token.jwt_token
      logout_url = LobbyBoy::Util::URI.add_query_params(
          LobbyBoy.provider.end_session_endpoint,
          id_token_hint: id_token_hint,
          post_logout_redirect_uri: return_url)

      cookies.delete :oidc_rp_state, domain: LobbyBoy.client.cookie_domain

      if logout_url # may be nil if not configured
        redirect_to logout_url # log out at OpenIDConnect SSO provider too
        true
      else
        false
      end
    end
  end
end
