class Rack::OAuth2::Server::Authorize
  module RequestWithConnectParams
    CONNECT_EXT_PARAMS = [
      :nonce, :display, :prompt, :max_age, :ui_locales, :claims_locales,
      :id_token_hint, :login_hint, :acr_values, :claims, :request, :request_uri
    ]

    def self.prepended(klass)
      klass.send :attr_optional, *CONNECT_EXT_PARAMS
    end

    def initialize(env)
      super
      CONNECT_EXT_PARAMS.each do |attribute|
        self.send :"#{attribute}=", params[attribute.to_s]
      end
      self.prompt = Array(prompt.to_s.split(' '))
      self.max_age = max_age.try(:to_i)
    end

    def openid_connect_request?
      scope.include?('openid')
    end
  end
  Request.send :prepend, RequestWithConnectParams
end