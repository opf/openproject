# encoding: UTF-8

Gem::Specification.new do |s|
  s.name        = 'openproject-auth_saml'
  s.version     = '1.0.0'
  s.authors     = 'Cyril Rohr'
  s.email       = 'cyril.rohr@gmail.com'
  s.homepage    = 'https://github.com/finnlabs/openproject-auth_saml'
  s.summary     = 'OmniAuth SAML / Single-Sign On'
  s.description = 'Adds the OmniAuth SAML provider to OpenProject'
  s.license     = 'MIT'

  s.files = Dir['{app,lib}/**/*'] + %w(README.md)

  s.add_dependency 'omniauth-saml', '~> 1.10.1'
end
