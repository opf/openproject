module LobbyBoy
  class SessionController < ActionController::Base
    layout false

    before_action :set_cache_buster

    def check
      response.headers['X-Frame-Options'] = 'SAMEORIGIN'

      render_check 'init'
    end

    def state
      current_state =
        if params[:state] == 'unauthenticated'
          'unauthenticated'
        elsif params[:state] == 'logout'
          'logout'
        else
          self.id_token ? 'authenticated' : 'unauthenticated'
        end

      render_check current_state
    end

    def end
      cookies.delete :oidc_rp_state, domain: LobbyBoy.client.cookie_domain

      redirect_to LobbyBoy.client.end_session_endpoint
    end

    def refresh
      provider = LobbyBoy.provider.name

      id_token = self.id_token

      id_token_hint = id_token && id_token.jwt_token
      origin = '/session/state'

      params = {
          prompt: 'none',
          origin: origin,
          id_token_hint: id_token_hint
      }

      redirect_to "#{omniauth_prefix}/#{provider}?#{compact_hash(params).to_query}"
    end

    ##
    # Defines used functions. All of which are only dependent on
    # their input parameters and not on some random global state.
    module Functions
      module_function

      ##
      # Returns a new hash only containing entries the values of which are not nil.
      def compact_hash(hash)
        hash.reject { |_, v| v.nil? }
      end

      def omniauth_prefix
        ::OmniAuth.config.path_prefix
      end

      ##
      # Returns true if the user is logged in locally or false
      # if they aren't or we don't know whether or not they are.
      def logged_in?
        instance_exec &LobbyBoy.client.logged_in
      end
    end

    module InstanceMethods
      def id_token
        token = session['lobby_boy.id_token']
        ::LobbyBoy::OpenIDConnect::IdToken.new token if token
      end

      def render_check(state)
        render 'check', locals: { state: state, logged_in: logged_in? }
      end

      def set_cache_buster
        response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
        response.headers["Pragma"] = "no-cache"
        response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
      end
    end

    include Functions
    include InstanceMethods
  end
end
