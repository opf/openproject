module OpenProject
  module OpenIDConnect
    class LobbyBoyConfiguration
      def initialize(app)
        @app = app
      end

      ##
      # Updates the lobby boy settings with each request in case
      # the host or protocol change in OpenProject's settings.
      def call(env)
        self.class.update_client! if LobbyBoy.configured?

        @app.call env
      end

      class << self
        attr_accessor :provider

        def enabled?
          Rails.env != 'test'
        end

        def update!
          self.provider = lookup_provider

          if enabled? && provider
            update_client!
            update_provider!
          end
        end

        def lookup_provider
          OpenProject::Plugins::AuthPlugin.providers.find { |p| p[:sso] }
        end

        def update_client!
          LobbyBoy.configure_client! host: host,
                                     logged_in: lambda { !session[:user_id].nil? },
                                     end_session_endpoint: end_session_endpoint,
                                     on_logout_js_partial: 'session/warn_logout'
        end

        def update_provider!
          LobbyBoy.configure_provider! name:                 provider[:name],
                                       client_id:            provider[:client_options][:identifier],
                                       issuer:               provider[:issuer],
                                       end_session_endpoint: provider[:end_session_endpoint],
                                       check_session_iframe: provider[:check_session_iframe]
        end

        def host
          "#{Setting.protocol}://#{Setting.host_name}"
        end

        def end_session_endpoint
          '/logout?script'
        end
      end
    end
  end
end
