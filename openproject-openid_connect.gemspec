# encoding: UTF-8
$:.push File.expand_path("../lib", __FILE__)

require 'open_project/openid_connect/version'

Gem::Specification.new do |s|
  s.name        = "openproject-openid_connect"
  s.version     = OpenProject::OpenIDConnect::VERSION
  s.authors     = "Finn GmbH"
  s.email       = "info@finn.de"
  s.homepage    = "https://www.openproject.org/projects/openid-connect"  # TODO check this URL
  s.summary     = 'OpenProject OpenID Connect'
  s.description = "Adds OmniAuth OpenID Connect strategy providers to Openproject."
  s.license     = "GPLv3"

  s.files = Dir["{app,config,db,lib}/**/*"] + %w(CHANGELOG.md README.md)

  s.add_dependency "rails", "~> 3.2.14"
  s.add_dependency "openproject-auth_plugins", "~> 4.0.0"
  s.add_dependency "omniauth", "~> 1.0"

  s.add_development_dependency "rspec", "~> 2.99"
end
