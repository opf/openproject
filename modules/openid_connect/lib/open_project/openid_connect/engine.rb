require "open_project/plugins"

module OpenProject::OpenIDConnect
  class Engine < ::Rails::Engine
    engine_name :openproject_openid_connect

    include OpenProject::Plugins::ActsAsOpEngine
    extend OpenProject::Plugins::AuthPlugin

    register "openproject-openid_connect",
             author_url: "https://www.openproject.org",
             bundled: true,
             settings: { "default" => { "providers" => {} } } do
      menu :admin_menu,
           :plugin_openid_connect,
           :openid_connect_providers_path,
           parent: :authentication,
           caption: ->(*) { I18n.t("openid_connect.menu_title") },
           enterprise_feature: "sso_auth_providers"
    end

    assets %w(
      openid_connect/auth_provider-azure.png
      openid_connect/auth_provider-google.png
      openid_connect/auth_provider-heroku.png
    )

    class_inflection_override("openid_connect" => "OpenIDConnect")

    register_auth_providers do
      OmniAuth::OpenIDConnect::Providers.configure custom_options: %i[
        display_name?
        icon?
        sso?
        issuer?
        check_session_iframe?
        end_session_endpoint?
        jwks_uri?
        limit_self_registration?
        use_graph_api?
      ]

      strategy :openid_connect do
        OpenProject::OpenIDConnect.providers.map(&:to_h).map do |h|
          h[:single_sign_out_callback] = Proc.new do
            next unless h[:end_session_endpoint]

            redirect_to "#{omni_auth_start_path(h[:name])}/logout"
          end

          # Remember oidc session values when logging in user
          h[:retain_from_session] = %w[omniauth.oidc_sid]

          h[:backchannel_logout_callback] = ->(logout_token) do
            ::OpenProject::OpenIDConnect::SessionMapper.handle_logout(logout_token)
          end

          h
        end
      end
    end

    initializer "openid_connect.configure" do
      ::Settings::Definition.add(
        OpenProject::OpenIDConnect::CONFIG_KEY, default: {}, writable: false
      )
    end

    initializer "openid_connect.form_post_method" do
      # If response_mode 'form_post' is chosen,
      # the IP sends a POST to the callback. Only if
      # the sameSite flag is not set on the session cookie, is the cookie send along with the request.
      if OpenProject::Configuration["openid_connect"]&.any? { |_, v| v["response_mode"]&.to_s == "form_post" }
        SecureHeaders::Configuration.default.cookies[:samesite][:lax] = false
        # Need to reload the secure_headers config to
        # avoid having set defaults (e.g. https) when changing the cookie values
        load Rails.root.join("config/initializers/secure_headers.rb")
      end
    end

    config.to_prepare do
      ::OpenProject::OpenIDConnect::Hooks::Hook
    end
  end
end
