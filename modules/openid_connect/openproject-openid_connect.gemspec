# encoding: UTF-8

Gem::Specification.new do |s|
  s.name        = 'openproject-openid_connect'
  s.version     = '1.0.0'
  s.authors     = 'OpenProject GmbH'
  s.email       = 'info@openproject.com'
  s.summary     = 'OpenProject OpenID Connect'
  s.description = 'Adds OmniAuth OpenID Connect strategy providers to Openproject.'
  s.license     = 'GPLv3'

  s.files = Dir['{app,config,db,lib}/**/*'] + %w(CHANGELOG.md README.md)

  s.add_dependency 'openproject-auth_plugins'
  s.add_dependency 'omniauth-openid_connect-providers', '~> 0.1'
  s.add_dependency 'lobby_boy', '~> 0.1.3'
end
