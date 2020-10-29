module OmniAuth::OpenIDConnect
  class Heroku < Provider
    def host
      config?(:host) || "connect-op.heroku.com"
    end

    def icon
      config?(:icon) || "openid_connect/auth_provider-heroku.png"
    end

    def client_options
      opts = {
        :authorization_endpoint => "/authorizations/new",
        :token_endpoint => "/access_tokens",
        :userinfo_endpoint => "/user_info"
      }

      opts.merge super
    end
  end
end
