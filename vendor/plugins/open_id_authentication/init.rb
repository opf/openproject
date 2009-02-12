if config.respond_to?(:gems)
  config.gem 'ruby-openid', :lib => 'openid', :version => '>=2.1.4'
else
  begin
    require 'openid'
  rescue LoadError
    begin
      gem 'ruby-openid', '>=2.1.4'
    rescue Gem::LoadError
      puts "Install the ruby-openid gem to enable OpenID support"
    end
  end
end

config.to_prepare do
  OpenID::Util.logger = Rails.logger
  ActionController::Base.send :include, OpenIdAuthentication
end
