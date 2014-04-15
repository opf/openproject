# Loading OpenID providers manually since rails doesn't do it automatically,
# possibly due to non trivially module-name-convertible paths.
require 'omniauth/openid_connect/provider'

# load pre-defined providers
Dir["lib/omniauth/openid_connect/*.rb"].each do |file|
  require file.gsub("lib/", "").gsub(".rb", "")
end

OmniAuth::OpenIDConnect::Provider.load_generic_providers

OmniAuth::OpenIDConnect::Provider.available.each do |pro|
  OpenProject::Application.config.middleware.use OmniAuth::Strategies::OpenIDConnect, pro.new.to_hash
end
