begin
  require 'openid'
rescue LoadError
  begin
    gem 'ruby-openid', '>=2.1.4'
  rescue Gem::LoadError
    # no openid support
  end
end

if Object.const_defined?(:OpenID)
  config.to_prepare do
    OpenID::Util.logger = Rails.logger
    ActionController::Base.send :include, OpenIdAuthentication
  end
end
