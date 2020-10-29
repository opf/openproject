module OpenIDConnect
  class RequestObject < ConnectObject
    include JWTnizable

    attr_optional :client_id, :response_type, :redirect_uri, :scope, :state, :nonce, :display, :prompt, :userinfo, :id_token
    validate :require_at_least_one_attributes

    undef :id_token=
    def id_token=(attributes = {})
      @id_token = IdToken.new(attributes) if attributes.present?
    end

    undef :userinfo=
    def userinfo=(attributes = {})
      @userinfo = UserInfo.new(attributes) if attributes.present?
    end

    def as_json(options = {})
      super.with_indifferent_access
    end

    class << self
      def decode(jwt_string, key = nil)
        new JSON::JWT.decode(jwt_string, key)
      end

      def fetch(request_uri, key = nil)
        jwt_string = OpenIDConnect.http_client.get_content(request_uri)
        decode jwt_string, key
      end
    end
  end
end

require 'openid_connect/request_object/claimable'
require 'openid_connect/request_object/id_token'
require 'openid_connect/request_object/user_info'
