module OpenIDConnect
  class Client < Rack::OAuth2::Client
    attr_optional :userinfo_endpoint, :expires_in

    def initialize(attributes = {})
      super attributes
      self.userinfo_endpoint ||= '/userinfo'
    end

    def authorization_uri(params = {})
      params[:scope] = setup_required_scope params[:scope]
      params[:prompt] = Array(params[:prompt]).join(' ')
      super
    end

    def userinfo_uri
      absolute_uri_for userinfo_endpoint
    end

    private

    def setup_required_scope(scopes)
      _scopes_ = Array(scopes).join(' ').split(' ')
      _scopes_ << 'openid' unless _scopes_.include?('openid')
      _scopes_
    end

    def handle_success_response(response)
      token_hash = JSON.parse(response.body).with_indifferent_access
      token_type = (@forced_token_type || token_hash[:token_type]).try(:downcase)
      case token_type
      when 'bearer'
        AccessToken.new token_hash.merge(client: self)
      else
        raise Exception.new("Unexpected Token Type: #{token_type}")
      end
    rescue JSON::ParserError
      raise Exception.new("Unknown Token Type")
    end
  end
end

Dir[File.dirname(__FILE__) + '/client/*.rb'].each do |file|
  require file
end
