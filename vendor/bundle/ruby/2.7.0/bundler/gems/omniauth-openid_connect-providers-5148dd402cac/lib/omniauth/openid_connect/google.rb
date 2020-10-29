module OmniAuth::OpenIDConnect
  class Google < Provider
    def host
      config?(:host) || "accounts.google.com"
    end

    def icon
      config?(:icon) || "openid_connect/auth_provider-google.png"
    end

    def options
      super.merge({
        :client_auth_method => :not_basic,
        :send_nonce => false, # use state instead of nonce
        :state => lambda { SecureRandom.hex(42) }
      })
    end

    def client_options
      opts = {
        :authorization_endpoint => "/o/oauth2/auth",
        :token_endpoint => "/o/oauth2/token",
        :userinfo_endpoint => "https://www.googleapis.com/oauth2/v3/userinfo?alt=json"
      }

      opts.merge super
    end
  end
end
