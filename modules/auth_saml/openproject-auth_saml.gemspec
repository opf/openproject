# encoding: UTF-8
$:.push File.expand_path("../lib", __FILE__)
$:.push File.expand_path("../../lib", __dir__)

require 'open_project/auth_saml/version'
# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'openproject-auth_saml'
  s.version     = OpenProject::AuthSaml::VERSION
  s.authors     = 'Cyril Rohr'
  s.email       = 'cyril.rohr@gmail.com'
  s.homepage    = 'https://github.com/finnlabs/openproject-auth_saml'
  s.summary     = 'OmniAuth SAML / Single-Sign On'
  s.description = 'Adds the OmniAuth SAML provider to OpenProject'
  s.license     = 'MIT'

  s.files = Dir['{app,lib}/**/*'] + %w(README.md)

  s.add_dependency 'omniauth-saml', '~> 1.10.1'
end
