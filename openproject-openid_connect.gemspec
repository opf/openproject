# encoding: UTF-8
$:.push File.expand_path('../lib', __FILE__)

require 'open_project/openid_connect/version'

Gem::Specification.new do |s|
  s.name        = 'openproject-openid_connect'
  s.version     = OpenProject::OpenIDConnect::VERSION
  s.authors     = 'OpenProject GmbH'
  s.email       = 'info@openproject.com'
  s.homepage    = 'https://community.openproject.org/projects/openid-connect'  # TODO check this URL
  s.summary     = 'OpenProject OpenID Connect'
  s.description = 'Adds OmniAuth OpenID Connect strategy providers to Openproject.'
  s.license     = 'GPLv3'

  s.files = Dir['{app,config,db,lib}/**/*'] + %w(CHANGELOG.md README.md)

  s.add_dependency 'rails', '~> 5.0'
  s.add_dependency 'openproject-auth_plugins', '~> 7.0'
  s.add_dependency 'omniauth-openid_connect-providers', '~> 0.1'
  s.add_dependency 'lobby_boy', '~> 0.1.3'

  s.add_development_dependency 'rspec', '~> 2.99'
end
